#!/bin/sh

set -e

usage() {
  echo "Usage: $0 <payload_dir> [output_dir]"
  echo ""
  echo "  payload_dir   - directory containing files to package"
  echo "  output_dir    - where to write package.zst and package.zst.md5 (default: ./out)"
  exit 1
}

[ $# -lt 1 ] && usage

payload_dir="$1"
output_dir="${2:-./out}"

[ -d "$payload_dir" ] || { echo "error: '$payload_dir' is not a directory"; exit 1; }

tmpdir=$(mktemp -d)
tmp_tar="$tmpdir.tar"
trap 'rm -rf "$tmpdir" "$tmp_tar"' EXIT

mkdir -p "$tmpdir/payload"
cp -a "$payload_dir"/. "$tmpdir/payload/"

mkdir -p "$output_dir"

tar -cf "$tmp_tar" -C "$tmpdir" .
zstd -q -19 -T0 -f "$tmp_tar" -o "$output_dir/package.zst"
md5sum "$output_dir/package.zst" | awk '{print $1}' > "$output_dir/package.zst.md5"

echo "built: $output_dir/package.zst"
echo "  md5:  $(cat "$output_dir/package.zst.md5")"
