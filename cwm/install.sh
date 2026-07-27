#!/bin/sh

set -e

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/cwm" "$install_dir/cwm"
chmod 755 "$install_dir/cwm"

mkdir -p /etc
cp "$1/payload/cwmrc" /etc/cwmrc
