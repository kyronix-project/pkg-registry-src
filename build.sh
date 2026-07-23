#!/bin/sh

set -e

usage() {
  echo "Usage: $0 <payload_dir> [output_dir]"
  echo ""
  echo "  payload_dir   - directory containing files to package"
  echo "  output_dir    - where to write package.gz and package.gz.md5 (default: ./out)"
  exit 1
}

[ $# -lt 1 ] && usage

payload_dir="$1"
output_dir="${2:-./out}"

[ -d "$payload_dir" ] || { echo "error: '$payload_dir' is not a directory"; exit 1; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/payload"
cp -a "$payload_dir"/. "$tmpdir/payload/"

mkdir -p "$output_dir"

tar -czf "$output_dir/package.gz" -C "$tmpdir" .
md5sum "$output_dir/package.gz" | awk '{print $1}' > "$output_dir/package.gz.md5"

echo "built: $output_dir/package.gz"
echo "  md5:  $(cat "$output_dir/package.gz.md5")"
