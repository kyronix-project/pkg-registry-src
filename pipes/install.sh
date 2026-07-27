#!/bin/sh

set -e

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/pipes" "$install_dir/pipes"
chmod 755 "$install_dir/pipes"
