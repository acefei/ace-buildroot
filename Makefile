include br-external.conf

OUTPUT_DIR  := $(PWD)/br2_external
BR2_EXTERNAL_PATH_NAME := BR2_EXTERNAL_$(EXTERNAL_NAME)_PATH
DEFCONFIG := $(OUTPUT_DIR)/configs/$(EXTERNAL_NAME)_defconfig
BUSYBOX_CONFIG := $(OUTPUT_DIR)/configs/$(EXTERNAL_NAME)_busybox.config
KERNEL_CONFIG := $(OUTPUT_DIR)/configs/$(EXTERNAL_NAME)_kernel.config
BUILDROOT_CONFIGS := $(DEFCONFIG) $(KERNEL_CONFIG) $(BUSYBOX_CONFIG)

BOOTABLE_IMG := $(PWD)/bootable.img
ARGS4LOSETUP := -v /dev/mapper:/dev/mapper --privileged

#############################################################################
# Quickly initialize a buildroot external 
#############################################################################
.PHONY: all
all: buildroot external_init

# More details for external, please refer to https://buildroot.org/downloads/manual/manual.html#customize
.PHONY: external_init
external_init: $(OUTPUT_DIR)/external.desc $(OUTPUT_DIR)/external.mk $(OUTPUT_DIR)/Config.in $(BUILDROOT_CONFIGS)
# Generate buildroot make wrapper
	@cp Makefile.buildroot $(OUTPUT_DIR)/Makefile
	@echo "Enjoy your buildroot journey in $(OUTPUT_DIR)"
	@echo "Have Fun!"

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

$(BUILDROOT_CONFIGS):
	@mkdir -p $(dir $(DEFCONFIG))
	@bash utils/genconfig.sh $(dir $(DEFCONFIG)) $(OUTPUT_DIR)/buildroot br-external.conf


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

.PHONY: buildroot
buildroot:
	@mkdir -p $(OUTPUT_DIR)
	@rm -rf $(OUTPUT_DIR)/buildroot || :
	@git clone -q -b $(BR2_VERSION) --depth 1 $(BR2_GIT_URL) $(OUTPUT_DIR)/buildroot 2>/dev/null

.PHONY: bootable-img
bootable-img: $(BOOTABLE_IMG)
$(BOOTABLE_IMG): output/images/rootfs.tar
	@bash utils/create_bootable_img.sh $@ $<

.PHONY: inspect-img
inspect-img: $(BOOTABLE_IMG)
	guestfish -a $<

# start linux image with kvm out of container 
# refer to https://github.com/buildroot/buildroot/blob/master/board/qemu/x86_64/readme.txt
# pressing `ctrl+a x` if want to quit qemu console
.PHONY: boot-img
boot-img: $(BOOTABLE_IMG)
	sudo kvm -nographic -m 1025 -hda $<
