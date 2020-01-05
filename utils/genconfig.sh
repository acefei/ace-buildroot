#!/bin/bash - 
#===============================================================================
#
#          FILE: genconfig.sh
# 
#         USAGE: ./genconfig.sh 
# 
#   DESCRIPTION: Generate buildroot external configs, like defconfig, kernel.config, busybox.config
# 
#       OPTIONS: ---
#        AUTHOR: acefei (), acefei@163.com
#       CREATED: 01/05/2020 02:17
#      REVISION:  ---
#===============================================================================
set -e

output_path=$(realpath $1)
br_path=$(realpath $2)
global_cfg=$3

ext_name=$(grep -Po 'EXTERNAL_NAME\s*:?=\s*\K\S+' $global_cfg)
defconfig_dest=$output_path/${ext_name}_defconfig
linux_config_dest=$output_path/${ext_name}_kernel.config
busybox_config_dest=$output_path/${ext_name}_busybox.config


set_vars ()
{
    local var=$1
    local value=$2
    local cfg=${3:-$defconfig_dest}

    grep -q "$var" $cfg && sed -i '/\('$var'\)/d' $cfg
    echo "$var=$value" >> $cfg
}	# ----------  end of function set_vars  ----------

set_defconfig ()
{
    defconfig=$(grep -Po 'DEFCONFIG\s*:?=\s*\K\S+' $global_cfg)
    if [ -z "$defconfig" ];then
        defconfig=qemu_x86_64_defconfig
    fi

    defconfig_path=$br_path/configs/$defconfig
    cp $defconfig_path $defconfig_dest
    source $defconfig_path

    #-------------------------------------------------------------------------------
    # Update defconfigs on demand
    #-------------------------------------------------------------------------------
    printf "\n# Build rootfs.tar\n" >> $defconfig_dest
    set_vars BR2_TARGET_ROOTFS_TAR y 

    printf "\n# Re-store dl on BASE_DIR for local build (might push tarballs to git lfs)\n" >> $defconfig_dest
    set_vars BR2_DL_DIR '"$(BASE_DIR)/dl"'

    printf "\n# Toolchain, required for grub2\n" >> $defconfig_dest
    set_vars BR2_TOOLCHAIN_BUILDROOT_WCHAR y

    printf "\n# Bootloader\n" >> $defconfig_dest
    set_vars BR2_TARGET_GRUB2 y

    # make ROOT_PWD=xxxx
    if [ -n "$ROOT_PWD" ];then
        # passwd -5  SHA256-based password algorithm
        # sed output is used in makefile
        salted_pwd=$(openssl passwd -5 -salt $(openssl rand -base64 8) $ROOT_PWD | sed 's/\$/\$\$/g')
        printf "\n# Root login with password \n" >> $defconfig_dest
        set_vars BR2_TARGET_ENABLE_ROOT_LOGIN y
        set_vars BR2_TARGET_GENERIC_ROOT_PASSWD '"$$5$$euisDgfHjF8=$$pGUnBPGIO5dNP1zw/HZSmQ0ODFCklsS2gNOSUJwxRY6"'
    fi
}	# ----------  end of function set_defconfig  ----------


set_linux_config ()
{
    test -z "$BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE" && return
    linux_config_path=$br_path/$BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE
    cp $linux_config_path $linux_config_dest

    # update custom kernel config
    sed -i 's!\(BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=\).*!\1"$(BR2_EXTERNAL_'${ext_name}'_PATH)/configs/'${ext_name}'_kernel.config"!' $defconfig_dest

}	# ----------  end of function set_linux_config  ----------


set_busybox_config ()
{
    busybox_config=$br_path/package/busybox/busybox.config
    cp $busybox_config $busybox_config_dest
    if [ -z "$BR2_PACKAGE_BUSYBOX_CONFIG" ]; then
        cat >> $defconfig_dest <<-EOF

# Busybox 
BR2_PACKAGE_BUSYBOX_CONFIG="\$(BR2_EXTERNAL_${ext_name}_PATH)/configs/${ext_name}_busybox.config"
EOF
    else
        sed -i 's!\(BR2_PACKAGE_BUSYBOX_CONFIG=\).*!\1"$(BR2_EXTERNAL_'${ext_name}'_PATH)/configs/'${ext_name}'_busybox.config"!' $defconfig_dest
    fi
}	# ----------  end of function set_busybox_config  ----------

main ()
{
    mkdir -p $output_path
    set_defconfig
    set_linux_config
    set_busybox_config
}	# ----------  end of function main  ----------

main
