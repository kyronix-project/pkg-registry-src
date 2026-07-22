#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp -r "$1/payload/"* "$install_dir/"
chmod +x "$install_dir/bin/openssl" 2>/dev/null || true
