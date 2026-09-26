#! /bin/sh
# Build the eMMC image for the u-boot VM example.
#
# The eMMC gets two GPT partitions, each exported by emmc-drv on its own:
#   uboot-env  1 MiB  the VM's CFI flash, holding the u-boot environment
#   vm1-disk   rest   the VM's disk, with its own partition table inside
set -e

KERNEL=${KERNEL:-Image-6.19.8}
RAMDISK=${RAMDISK:-ramdisk-armv8-64.cpio.gz}
IMG=${IMG:-emmc.img}
FS=${FS:-ext4}   # file system of the VM's boot partition: ext4 or vfat

first() { sgdisk -i "$1" "$2" | sed -n 's/^First sector: \([0-9]*\).*/\1/p'; }
last()  { sgdisk -i "$1" "$2" | sed -n 's/^Last sector: \([0-9]*\).*/\1/p'; }

# The eMMC image; SD card sizes need to be a power of 2 for QEMU
rm -f "$IMG"
truncate -s 256M "$IMG"
sgdisk -n 1:0:+1M -c 1:uboot-env \
       -n 2:0:0   -c 2:vm1-disk "$IMG" > /dev/null

# The flash starts out erased, i.e., all ones
head -c 1M /dev/zero | tr '\0' '\377' |
  dd of="$IMG" bs=512 seek="$(first 1 "$IMG")" conv=notrunc status=none

# The VM's disk, as large as the vm1-disk partition
VM_START=$(first 2 "$IMG")
VM_SECTORS=$(( $(last 2 "$IMG") - VM_START + 1 ))
rm -f vm1-disk.img
truncate -s $(( VM_SECTORS * 512 )) vm1-disk.img
if [ "$FS" = vfat ]; then TYPE=0700; else TYPE=8300; fi
sgdisk -n 1:0:0 -c 1:boot -t 1:$TYPE vm1-disk.img > /dev/null

# A file system with the kernel, the ramdisk and extlinux.conf
rm -rf rootdir
mkdir -p rootdir/boot/extlinux
cp "$KERNEL" rootdir/boot/Image
cp "$RAMDISK" rootdir/boot/ramdisk.cpio.gz
cat > rootdir/boot/extlinux/extlinux.conf <<EOC
default linux
timeout 3

label linux
  kernel /boot/Image
  initrd /boot/ramdisk.cpio.gz
  append console=ttyAMA0
EOC

FS_START=$(first 1 vm1-disk.img)
FS_SECTORS=$(( $(last 1 vm1-disk.img) - FS_START + 1 ))
rm -f boot.fs
if [ "$FS" = vfat ]; then
  mkfs.vfat -n BOOT -C boot.fs $(( FS_SECTORS / 2 )) > /dev/null
  mcopy -s -i boot.fs rootdir/boot ::
else
  # U-Boot can only write to ext4 without metadata checksums
  mkfs.ext4 -q -L boot -O ^metadata_csum,^metadata_csum_seed -d rootdir \
            boot.fs $(( FS_SECTORS / 2 ))k
fi
dd if=boot.fs of=vm1-disk.img bs=512 seek="$FS_START" conv=notrunc status=none

# Put the VM's disk into its partition
dd if=vm1-disk.img of="$IMG" bs=512 seek="$VM_START" conv=notrunc status=none
rm -rf rootdir boot.fs vm1-disk.img
