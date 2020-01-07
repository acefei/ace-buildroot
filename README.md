# ace-buildroot
Buildroot External template generator

## Usage
### Init minimal buildroot external
1. Tweak the configuration file [br-external.conf](https://github.com/acefei/ace-buildroot/blob/master/br-external.conf)
2. Run `make` to quickly setup a layout of a br2-external tree [as document](https://buildroot.org/downloads/manual/manual.html#customize-dir-structure)

### Buildroot Configuration 
1. Run `make build-container` to config buildroot
2. Run the following cmds in sequence to tweak buildroot/kernel/busybox config
```
make menuconfig
make kernalconfig
make busyboxconfig
```
3. Run `make` to generate a QEMU disk image
4. Run `make boot-img` to launch QEMU

> Note:<br> 
you can find all buildroot configs in `br2_external/configs` and extra packages tarball in `br2_external/dl`<br>
Highly recommend to track them with git, especially using git-lfs to store the files in `br2_external/dl`

## TODO
1. Use git lfs to store packages in $(BASEDIR)/dl
2. Enable CCACHE

## Known Issues
### [BUILDROOT ip: can't find device eth0](https://stackoverflow.com/questions/33337062/buildroot-ip-cant-find-device-eth0)
Press `ctrl+a+c` to qemu cli, and run `info network` (or `info pci`), we can find the default net device model is e1000.
```
(qemu) info network
hub 0
\ hub0port1: user.0: index=0,type=user,net=10.0.2.0,restrict=off
\ hub0port0: e1000.0: index=0,type=nic,model=e1000,macaddr=52:54:00:12:34:56
```
so there are two ways to solve this.
1. Enable e1000 driver and ensure `CONFIG_E1000=y` in linux.config
```
make linux-menuconfig
Device drivers —>
Network device support —>
Ethernet driver support—>
<*>     Intel(R) PRO/1000 Gigabit Ethernet support               
<*>     Intel(R) PRO/1000 PCI-Express Gigabit Ethernet support
```
2. Run qemu with `-net nic,model=virtio -net user` options, refer to [this](https://github.com/buildroot/buildroot/blob/master/board/qemu/x86_64/readme.txt) and you might need to know why [Qemu user mode networking doesn't work](https://superuser.com/a/859203)
    
### Can't find buildroot login prompt using qemu 
Use qemu_x86_defconfig for qemu-system-i386. Change tty1 to ttyS0 for using QEMU nographic option, refer to [Build buildroot and run QEMU](https://www.hiroom1.com/2016/05/20/ubuntu-16-04-build-buildroot-and-run-qemu/)

### `/boot/bzImage` not found when qemu booting up.
Enable `Install kernel image to /boot in target` in the kernel menu to populate a /boot directory with bzImage, refer to [Notes on using Grub2 for ARM u-boot-based platforms](https://github.com/buildroot/buildroot/tree/master/boot/grub2)

## Reference 
- [guestfs-faq](http://libguestfs.org/guestfs-faq.1.html)
- [BIOS boot partition](https://en.wikipedia.org/wiki/BIOS_boot_partition)
- [Why does the partition start on sector 2048 instead of 63?](https://superuser.com/questions/352572/why-does-the-partition-start-on-sector-2048-instead-of-63)
- [How to Setup QEMU Output to Console and Automate Using Shell Script](https://fadeevab.com/how-to-setup-qemu-output-to-console-and-automate-using-shell-script/)
