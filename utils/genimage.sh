#!/bin/bash - 
#===============================================================================
#
#          FILE: genimage.sh
# 
#         USAGE: ./genimage.sh <disk_img> <br_output_dir>
# 
#   DESCRIPTION: Generate a disk image that can boot up via qemu
#                This script is inspired by https://github.com/buildroot/buildroot/blob/master/boot/grub2/readme.txt
# 
#       OPTIONS: 
#                disk_img: disk image for qemu
#                br_output_dir: buildroot output directory
#
#        AUTHOR: acefei (), acefei@163.com
#       CREATED: 01/05/2020 05:07
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -e

disk_img=$(realpath "$1")
br_output_dir=$(realpath "$2")

setup=$(mktemp -dt "$(basename "$0").XXXXXXXXXX")
teardown(){
    # catch original exit code
    exit_code=$?

    # process
    rm -rf "$setup"

    # exit with original exit code
    if [ $exit_code -eq 0 ];then
        echo
        echo "$disk_img is available."
    else
        rm -rf $disk_img
        exit $exit_code
    fi
}
trap teardown EXIT 

root_tar=$br_output_dir/images/rootfs.tar
# the paths relative to $br_output_dir
grub_bios_setup=./host/sbin/grub-bios-setup
grub_boot_img=./host/lib/grub/i386-pc/boot.img
grub_img=./images/grub.img

#grub_env=grubenv
grub_cfg=grub.cfg

# https://en.wikipedia.org/wiki/BIOS_boot_partition
bios_guid=21686148-6449-6E6F-744E-656564454649
rootfs_uuid=$(cat /proc/sys/kernel/random/uuid)

is_compress() {
    case "$(file "$root_tar")" in
        *gzip*)
            echo "compress:gzip"
            ;;
        *archive*)
            echo ""
            ;;
        *)
            echo "Invalid file type for $root_tar"
            exit 1
            ;;
    esac
}

create_grub_env() {
    grub-editenv $grub_env set default=0
}

create_grub_cfg() {
    # based on https://github.com/buildroot/buildroot/blob/master/boot/grub2/grub.cfg
    cat > $grub_cfg <<EOF
set default="0"
set timeout="3"
set timeout_style="hidden"

menuentry "Buildroot" {
    set root="(hd0,gpt3)"
    linux /boot/bzImage root=PARTUUID=$rootfs_uuid console=ttyS0
}
EOF
}

create_empty_image() {
    K=1024
    M=$((K*1024))
    G=$((M*1024))
    part_start=2048
    grub_size=$((2*M/512))
    grubConfig_size=$((16*M/512))
    root_size=$((2*G/512))
    overhead=$((48*K))
    image_size=$(((overhead+grub_size+grubConfig_size+root_size)*512))
    compress_args=$(is_compress)
    
    # create empty image disk
    # equal to `dd if=/dev/zero of=<image_path> bs=<block_size> count=<block_num>`, image_size = block_size * block_num
    truncate -s "$image_size" "$disk_img"
    
    # create and populate partitions
    guestfish -a "$disk_img" <<EOF
run
part-init /dev/sda gpt
part-add /dev/sda p $part_start $((part_start+grub_size))
part-set-name /dev/sda 1 grub
part-set-bootable /dev/sda 1 true
part-set-gpt-type /dev/sda 1 $bios_guid
part-add /dev/sda p $((part_start+grub_size+1)) $((part_start+grub_size+grubConfig_size))
part-set-name /dev/sda 2 grubConfig
mkfs ext2 /dev/sda2
set-e2label /dev/sda2 grubConfig
mount /dev/sda2 /
mkdir-p /boot/grub
copy-in $grub_cfg /boot/grub
umount /
part-add /dev/sda p $((part_start+grub_size+grubConfig_size+1)) $((part_start+grub_size+grubConfig_size+root_size))
part-set-name /dev/sda 3 rootfs
part-set-gpt-guid /dev/sda 3 $rootfs_uuid
mkfs ext2 /dev/sda3
mount /dev/sda3 /
tar-in $root_tar / $compress_args
umount /
EOF
}

# run as subshell with trap
install_grub2() (
    # Setup loop device and loop partitions
    loopdev=$(sudo losetup -P --show -f "$disk_img")

    # Install Grub2
    trap 'sudo losetup -d $loopdev' EXIT
    cd $br_output_dir
    sudo $grub_bios_setup -b $grub_boot_img -c $grub_img -d . "$loopdev"

    # Display the current partition table
    sgdisk -p "$disk_img"
)

main() {
    cd $setup
    #create_grub_env
    create_grub_cfg
    create_empty_image
    install_grub2
}
main
