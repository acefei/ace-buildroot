# ace-buildroot
Buildroot External template generator

## Usage
### Init minimal buildroot external
1. Tweak the configuration file [br-external.conf](https://github.com/acefei/ace-buildroot/blob/master/br-external.conf)
2. Run `make` to quickly setup a layout of a br2-external tree [as document](https://buildroot.org/downloads/manual/manual.html#customize-dir-structure)

### Buildroot Configuration 
1. Run `make build-container` to config buildroot
2. Run the following cmds in sequence 
```
make menuconfig
make kernalconfig
make busyboxconfig
```
Exit container, then you can find all buildroot configs in `br2_external/configs` and extra packages tarball in `br2_external/dl`
Highly recommend to track them with git, especially using git-lfs to store the files in `br2_external/dl`

## TODO
1. Use git lfs to store packages in $(BASEDIR)/dl
2. Enable CCACHE

## Known Issues
- [BUILDROOT ip: can't find device eth0](https://stackoverflow.com/questions/33337062/buildroot-ip-cant-find-device-eth0)

## Reference 
- [guestfs-faq](http://libguestfs.org/guestfs-faq.1.html)
