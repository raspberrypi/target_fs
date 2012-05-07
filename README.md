target_fs
=========

emergency kernel target_fs files

You want these in .config to use this:

CONFIG_BLK_DEV_INITRD=y
CONFIG_INITRAMFS_SOURCE="../target_fs"
