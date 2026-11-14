#!/bin/bash
# Downloads the four files that are too big for git (over 100 MB) from this repo's GitHub Release
# into the folders the guide expects, and checks their SHA-256.
# Usage: files/scripts/fetch_large_files.sh [all|gsi|prebuilt]     (default: all)
set -euo pipefail
REPO="ada101/Y6-2018-LineageOS-Guide"
TAG="v1.0"
cd "$(dirname "$0")/.."          # -> files/

# group | path under files/ | sha256
LIST="gsi|gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img|66992887a5c083e87a612f721842d6e85c01682aa6ee0d3be72b9b998e64104c
gsi|gsi/fallback/2018-05-19-system-arm64-aonly.img|6b05046d024902bf8ebcdbea91d6e70113438eafe4fad432901ef75a8755ec08
prebuilt|prebuilt/v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img.xz|c3fd479844f1cd3c1933737aa87d5c6e44b1da936112bf8fbb377dc24839316d
prebuilt|prebuilt/v5-2018-06-27-patched-libs-only-ATU-L22-8.0.0.139.img.xz|a4345fb9c782a1b9d3e92c94eb3674885e2c89e4b4ca49abf0a52086c48e2636"

want="${1:-all}"
while IFS='|' read -r group path sha; do
    [ "$want" = all ] || [ "$want" = "$group" ] || continue
    if [ -f "$path" ] && [ "$(sha256sum "$path" | cut -d' ' -f1)" = "$sha" ]; then
        echo "OK (already here): $path"; continue
    fi
    mkdir -p "$(dirname "$path")"
    echo "Downloading $(basename "$path") ..."
    curl -fL -C - --retry 3 -o "$path" "https://github.com/$REPO/releases/download/$TAG/$(basename "$path")"
    got="$(sha256sum "$path" | cut -d' ' -f1)"
    [ "$got" = "$sha" ] || { echo "CHECKSUM MISMATCH: $path"; echo " expected $sha"; echo " got      $got"; exit 1; }
    echo "OK: $path"
done <<< "$LIST"
