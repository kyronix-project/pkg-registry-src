#!/bin/sh
set -e

mkdir -p /usr/lib/sysroots
cp -r "$1/payload/"* /
