include br-external.conf

OUTPUT_DIR  := $(PWD)/br2_external
BR2_EXTERNAL_PATH_NAME := BR2_EXTERNAL_$(EXTERNAL_NAME)_PATH
DEFCONFIG := $(OUTPUT_DIR)/configs/$(EXTERNAL_NAME)_defconfig
BUSYBOX_CONFIG := $(OUTPUT_DIR)/configs/$(EXTERNAL_NAME)_busybox.config
KERNEL_CONFIG := $(OUTPUT_DIR)/configs/$(EXTERNAL_NAME)_kernel.config
BUILDROOT_CONFIGS := $(DEFCONFIG) $(KERNEL_CONFIG) $(BUSYBOX_CONFIG)
BR_EXTERNAL_FILES := $(OUTPUT_DIR)/external.desc $(OUTPUT_DIR)/external.mk $(OUTPUT_DIR)/Config.in $(OUTPUT_DIR)/scripts/genimage.sh

ARGS4LOSETUP := -v /dev/mapper:/dev/mapper --privileged

#############################################################################
# Quickly initialize a buildroot external 
#############################################################################
.PHONY: all
all: buildroot external_init

.PHONY: buildroot
buildroot:
	@mkdir -p $(OUTPUT_DIR)
	@rm -rf $(OUTPUT_DIR)/buildroot || :
	@git clone -q -b $(BR2_VERSION) --depth 1 $(BR2_GIT_URL) $(OUTPUT_DIR)/buildroot 2>/dev/null

# More details for external, please refer to https://buildroot.org/downloads/manual/manual.html#customize
.PHONY: external_init
external_init: $(BR_EXTERNAL_FILES) genconfig
# Generate buildroot make wrapper
	@cp Makefile.buildroot $(OUTPUT_DIR)/Makefile
	@echo "Get start with following instructions:"
	@echo "1. Run 'make build-container' to enter dev environment"
	@echo "2. Run 'make menuconfig' for buildroot config"
	@echo "3. Run 'make kernelconfig' for kernel config"
	@echo "4. Run 'make busyboxconfig' for busybox config"
	@echo "5. Run 'make' to build a disk image for booting up by qemu/kvm"
	@echo "Enjoy your buildroot journey! Have Fun!"

$(OUTPUT_DIR)/external.desc:
	@echo "name: $(EXTERNAL_NAME)" > $@
	@echo "desc: $(EXTERNAL_DESC)" >> $@

$(OUTPUT_DIR)/external.mk:
	@echo "include \$$(sort \$$(wildcard \$$($(BR2_EXTERNAL_PATH_NAME))/package/*/*.mk))" > $@

$(OUTPUT_DIR)/Config.in:
	@echo > $@
	@for package in $(PACKAGES); do \
		mkdir -p $(OUTPUT_DIR)/package/$$package && \
		touch $(OUTPUT_DIR)/package/$$package/Config.in && \
		echo "source \"\$$$(BR2_EXTERNAL_PATH_NAME)/package/$$package/Config.in\"" >> $@; \
	done

$(OUTPUT_DIR)/scripts/genimage.sh:
	@mkdir -p $(@D)
	@cp utils/genimage.sh $(@D)

.PHONY: genconfig
genconfig:
	@mkdir -p $(dir $(DEFCONFIG))
	@bash $(SH_VERBOSE) utils/genconfig.sh $(dir $(DEFCONFIG)) $(OUTPUT_DIR)/buildroot br-external.conf
	@ls $(BUILDROOT_CONFIGS) > /dev/null

.PHONY: clean
clean:
	@rm -rf $(OUTPUT_DIR)

#############################################################################
# Development mode
#############################################################################
.PHONY: build-container
build-container: docker/Dockerfile
# move Dockerfile in a sub-folder as https://stackoverflow.com/a/46650340
	docker build -t $(EXTERNAL_NAME)  $(<D)
	docker run --rm -it -v $(OUTPUT_DIR):/build $(ARGS4LOSETUP) -w /build -t $(EXTERNAL_NAME):latest bash

# start linux image with kvm out of container 
# refer to https://github.com/buildroot/buildroot/blob/master/board/qemu/x86_64/readme.txt
# pressing `ctrl+a x` if want to quit qemu console
.PHONY: boot-img
boot-img: 
	sudo kvm -nographic -hda $(OUTPUT_DIR)/images/disk.img -net nic,model=virtio -net user
