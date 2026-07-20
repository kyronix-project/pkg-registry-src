#!/bin/sh

install_dir="$4"

mkdir -p "$install_dir"
cp -r "$1/payload/"* "$install_dir/"
