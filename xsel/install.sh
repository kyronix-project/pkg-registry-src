#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/xsel" "$install_dir/xsel"
chmod 775 "$install_dir/xsel"
