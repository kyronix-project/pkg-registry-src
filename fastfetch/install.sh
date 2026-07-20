#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/fastfetch" "$install_dir/fastfetch"
chmod 775 "$install_dir/fastfetch"
