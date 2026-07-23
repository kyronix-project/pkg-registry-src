#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir/lib"
mkdir -p "$install_dir/bin"
mkdir -p "$install_dir/include"
mkdir -p /usr/share/terminfo

cp "$1/payload/lib/"*.a        "$install_dir/lib/"
cp "$1/payload/bin/"*          "$install_dir/bin/"
chmod 755 "$install_dir/bin/"*
cp "$1/payload/include/"*.h    "$install_dir/include/"
cp -r "$1/payload/share/terminfo/"* /usr/share/terminfo/

echo "[ncurses] installed"
