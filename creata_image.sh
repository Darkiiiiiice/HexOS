#! /bin/bash

BUILD_DIR=build
IMAGE_DIR=$BUILD_DIR/hardware
IMAGE_FILE=$IMAGE_DIR/hardware.img

mkdir -p $IMAGE_DIR
qemu-img create -f qcow2 $IMAGE_FILE 8G
sudo qemu-nbd --connect=/dev/nbd0 $IMAGE_FILE
sudo partprobe /dev/nbd0
sudo fdisk /dev/nbd0
sudo mkfs.fat -F 32 /dev/nbd0p1
sudo mkfs.ext4 -F /dev/nbd0p2
sudo mount /dev/nbd0p2 /mnt
sudo mount -m /dev/nbd0p1 /mnt/boot
sudo mkdir /mnt/boot/EFI
sudo grub-install --target=x86_64-efi --boot-directory=/mnt/boot --efi-directory=/mnt/boot/ --bootloader-id=GRUB /dev/nbd0
sudo cp grub/grub.cfg /mnt/boot/grub/
make unmount
