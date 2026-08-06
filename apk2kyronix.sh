#!/bin/sh
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_SCRIPT="$ROOT_DIR/build.sh"

ALPINE_BRANCH="${ALPINE_BRANCH:-v3.21}"
ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"
ARCH="${ARCH:-x86_64}"
MAINTAINER="${MAINTAINER:-Kyronix Project}"
RECURSIVE=1
DRY_RUN=0

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [options] <package> [package...]

Convert Alpine Linux packages to Kyronix package format.

Options:
  --branch <ver>     Alpine branch (default: $ALPINE_BRANCH)
  --arch <arch>      Architecture (default: $ARCH)
  --mirror <url>     Alpine mirror (default: $ALPINE_MIRROR)
  --no-deps          Do not convert dependencies recursively
  --maintainer <s>   Maintainer string (default: $MAINTAINER)
  --dry-run          Only print what would be done
  -h, --help         Show this help
EOF
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --branch) ALPINE_BRANCH="$2"; shift 2 ;;
        --arch) ARCH="$2"; shift 2 ;;
        --mirror) ALPINE_MIRROR="$2"; shift 2 ;;
        --maintainer) MAINTAINER="$2"; shift 2 ;;
        --no-deps) RECURSIVE=0; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        -h|--help) usage ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *) break ;;
    esac
done

[ $# -eq 0 ] && usage

DOWNLOADER=""
for cmd in curl wget; do
    if command -v "$cmd" >/dev/null 2>&1; then
        DOWNLOADER="$cmd"
        break
    fi
done

[ -z "$DOWNLOADER" ] && { echo "error: neither curl nor wget found" >&2; exit 1; }

download() {
    local url="$1" out="$2"
    case "$DOWNLOADER" in
        curl) curl -sfL --max-time 30 "$url" -o "$out" ;;
        wget) wget -q --timeout=30 "$url" -O "$out" ;;
    esac
}

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
SEEN_FILE="$WORKDIR/.seen"
touch "$SEEN_FILE"

echo "==> Fetching Alpine package index ($ALPINE_BRANCH/$ARCH)..."

for repo in main community; do
    url="$ALPINE_MIRROR/$ALPINE_BRANCH/$repo/$ARCH/APKINDEX.tar.gz"
    printf '    %s ... ' "$repo"
    if download "$url" "$WORKDIR/APKINDEX-$repo.tar.gz" 2>/dev/null; then
        tar -xzf "$WORKDIR/APKINDEX-$repo.tar.gz" -C "$WORKDIR" APKINDEX 2>/dev/null || true
        if [ -f "$WORKDIR/APKINDEX" ]; then
            mv "$WORKDIR/APKINDEX" "$WORKDIR/APKINDEX-$repo"
            echo "OK"
        else
            echo "EMPTY"
        fi
    else
        echo "FAILED"
    fi
done

pkg_field() {
    local pkg="$1" key="$2"
    local val=""
    for idx in "$WORKDIR/APKINDEX-main" "$WORKDIR/APKINDEX-community"; do
        [ -f "$idx" ] || continue
        val=$(awk -v pkg="$pkg" -v key="$key" '
            BEGIN { RS=""; FS="\n" }
            {
                p = ""
                for (i=1; i<=NF; i++) {
                    if ($i ~ /^P:/) { p = substr($i, 3); break }
                }
                if (p != pkg) next
                for (i=1; i<=NF; i++) {
                    if ($i ~ "^" key ":") {
                        print substr($i, length(key) + 2)
                        exit
                    }
                }
            }
        ' "$idx")
        [ -n "$val" ] && { echo "$val"; return 0; }
    done
    return 1
}

pkg_repo() {
    local pkg="$1"
    for repo in main community; do
        idx="$WORKDIR/APKINDEX-$repo"
        [ -f "$idx" ] || continue
        if awk -v pkg="$pkg" '
            BEGIN { RS=""; FS="\n" }
            { for (i=1; i<=NF; i++) if ($i == "P:" pkg) found=1 }
            END { exit found ? 0 : 1 }
        ' "$idx"; then
            echo "$repo"
            return 0
        fi
    done
    return 1
}

pkg_deps() {
    local raw
    raw=$(pkg_field "$1" "D") || return 0
    [ -z "$raw" ] && return 0
    echo "$raw" | awk '{
        n = split($0, deps, " ")
        for (j=1; j<=n; j++) {
            dep = deps[j]
            if (dep ~ /^(so:|pc:|path:|!|\?|\/)/) continue
            gsub(/[><=!~].*$/, "", dep)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", dep)
            if (dep != "") print dep
        }
    }'
}

convert_package() {
    local pkg="$1"
    local outdir="$ROOT_DIR/$pkg"

    if [ -f "$outdir/config.toml" ] && [ -f "$outdir/install.sh" ] \
        && [ -f "$outdir/package.gz" ] && [ -f "$outdir/package.gz.md5" ]; then
        echo "  [skip] $pkg"
        return 0
    fi

    local version
    version=$(pkg_field "$pkg" "V") || { echo "  [warn] $pkg not found in index"; return 1; }

    local desc
    desc=$(pkg_field "$pkg" "T" || echo "")
    local license
    license=$(pkg_field "$pkg" "L" || echo "")
    local homepage
    homepage=$(pkg_field "$pkg" "U" || echo "")

    local ver="$version" rev="1"
    case "$ver" in
        *-r[0-9]*)
            rev="${ver##*-r}"
            ver="${ver%-r*}"
        ;;
    esac
    # Alpine starts pkgrel at 0, Kyronix revision starts at 1
    [ "$rev" -eq 0 ] 2>/dev/null && rev=1 || true

    local repo
    repo=$(pkg_repo "$pkg") || { echo "  [warn] $pkg repo not found"; return 1; }
    local apk_url="$ALPINE_MIRROR/$ALPINE_BRANCH/$repo/$ARCH/$pkg-$version.apk"

    echo "  -> $pkg ($version -> rev $rev)"

    [ "$DRY_RUN" = 1 ] && { echo "     $apk_url"; return 0; }

    download "$apk_url" "$WORKDIR/$pkg.apk"
    [ -f "$WORKDIR/$pkg.apk" ] || { echo "  [error] download failed"; return 1; }

    mkdir -p "$WORKDIR/$pkg-extract"
    tar -xzf "$WORKDIR/$pkg.apk" -C "$WORKDIR/$pkg-extract" 2>/dev/null || true
    rm -f "$WORKDIR/$pkg-extract/.PKGINFO" \
          "$WORKDIR/$pkg-extract/.SIGN.RSA."* 2>/dev/null || true

    mkdir -p "$outdir"

    cat > "$outdir/install.sh" <<'INSTALL'
#!/bin/sh
set -e
cp -r "$1/payload/"* /
INSTALL
    chmod +x "$outdir/install.sh"

    desc_esc=$(echo "$desc" | sed 's/"/\\"/g')

    {
        echo "name = \"$pkg\""
        echo "version = \"$ver\""
        echo "revision = $rev"
        echo "description = \"$desc_esc\""
        echo "arch = \"x86-64\""
        echo "maintainer = \"$MAINTAINER\""
        [ -n "$license" ] && echo "license = \"$license\""
        [ -n "$homepage" ] && echo "homepage = \"$homepage\""
        echo "depends = ["

        pkg_deps "$pkg" | sed 's/.*/    "&",/'

        echo "]"
    } > "$outdir/config.toml"

    "$BUILD_SCRIPT" "$WORKDIR/$pkg-extract" "$outdir" >/dev/null

    rm -f "$WORKDIR/$pkg.apk"
    rm -rf "$WORKDIR/$pkg-extract"

    echo "  [done] $pkg"
}

convert_recursive() {
    local pkg="$1"

    if grep -qxF "$pkg" "$SEEN_FILE" 2>/dev/null; then
        return 0
    fi

    if [ -d "$ROOT_DIR/$pkg" ] && [ -f "$ROOT_DIR/$pkg/config.toml" ]; then
        echo "$pkg" >> "$SEEN_FILE"
        echo "  [skip] $pkg (already in repo)"
        return 0
    fi

    if [ "$RECURSIVE" = 1 ]; then
        # Collect deps first, then convert them
        local deps_str
        deps_str=$(pkg_deps "$pkg" || true)
        if [ -n "$deps_str" ]; then
            echo "$deps_str" | while read -r dep; do
                [ -n "$dep" ] && convert_recursive "$dep"
            done
        fi
    fi

    convert_package "$pkg" && echo "$pkg" >> "$SEEN_FILE"
}

echo "==> Converting packages..."

for pkg in "$@"; do
    convert_recursive "$pkg"
done

echo "==> Done"
