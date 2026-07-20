#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/xclip" "$install_dir/xclip"
chmod 775 "$install_dir/xclip"
