#!/bin/bash - 
#===============================================================================
#
#          FILE: genconfig.sh
# 
#         USAGE: ./genconfig.sh 
# 
#   DESCRIPTION: Generate buildroot external configs, like defconfig, kernal.config, busybox.config
# 
#       OPTIONS: ---
#        AUTHOR: acefei (), acefei@163.com
#       CREATED: 01/05/2020 02:17
#      REVISION:  ---
#===============================================================================

output_path=$(realpath $1)
br_path=$(realpath $2)
global_cfg=$3

ext_name=$(grep -Po 'EXTERNAL_NAME\s*:?=\s*\K\S+' $global_cfg)
defconfig_dest=$output_path/${ext_name}_defconfig
linux_config_dest=$output_path/${ext_name}_kernel.config
busybox_config_dest=$output_path/${ext_name}_busybox.config

set_defconfig ()
{
    defconfig=$(grep -Po 'DEFCONFIG\s*:?=\s*\K\S+' $global_cfg)
    if [ -z "$defconfig" ];then
        defconfig=qemu_x86_64_defconfig
    fi

    defconfig_path=$br_path/configs/$defconfig
    cp $defconfig_path $defconfig_dest
    source $defconfig_path
}	# ----------  end of function set_defconfig  ----------


set_linux_config ()
{
    test -z "$BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE" && return
    linux_config_path=$br_path/$BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE
    cp $linux_config_path $linux_config_dest
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
