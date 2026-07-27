#!/bin/sh

set -e

install_dir="$4"
terminfo_dir="/etc/terminfo/s"

mkdir -p "$install_dir"
cp "$1/payload/st" "$install_dir/st"
chmod 755 "$install_dir/st"

mkdir -p "$terminfo_dir"
for entry in "$1"/payload/terminfo/*; do
    name=${entry##*/}
    cp "$entry" "$terminfo_dir/$name"
done
