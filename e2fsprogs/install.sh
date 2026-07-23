#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/sbin/mkfs.ext4" "$install_dir/mkfs.ext4"
cp "$1/payload/sbin/mkfs.ext3" "$install_dir/mkfs.ext3"
cp "$1/payload/sbin/mkfs.ext2" "$install_dir/mkfs.ext2"
cp "$1/payload/sbin/mke2fs" "$install_dir/mke2fs"
cp "$1/payload/sbin/fsck.ext4" "$install_dir/fsck.ext4"
cp "$1/payload/sbin/fsck.ext3" "$install_dir/fsck.ext3"
cp "$1/payload/sbin/fsck.ext2" "$install_dir/fsck.ext2"
cp "$1/payload/sbin/e2fsck" "$install_dir/e2fsck"
chmod 775 "$install_dir"/*

mkdir -p /usr/sbin
cp "$1/payload/sbin/"* /usr/sbin/

mkdir -p /etc
cp "$1/payload/etc/mke2fs.conf" /etc/mke2fs.conf
cp "$1/payload/etc/e2scrub.conf" /etc/e2scrub.conf
