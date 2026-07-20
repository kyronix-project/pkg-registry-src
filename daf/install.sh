#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/daf" "$install_dir/daf"
chmod 775 "$install_dir/daf"
