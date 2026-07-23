#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp "$1/payload/bin/dialog" "$install_dir/dialog"
cp "$1/payload/lib/libdialog.a" "$install_dir/libdialog.a"
