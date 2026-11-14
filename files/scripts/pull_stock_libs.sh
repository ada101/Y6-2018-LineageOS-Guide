#!/bin/bash
# Copy the 6 stock Huawei HIDL libraries off a phone that is STILL RUNNING STOCK EMUI 8.0
# (no root needed). Alternative to pointing patch_gsi.sh at a system.img backup.
# Usage: ./pull_stock_libs.sh <output-dir>      -> <output-dir>/lib64/*.so and <output-dir>/lib/*.so
set -e
OUT="${1:?usage: $0 <output-dir>}"
mkdir -p "$OUT/lib64" "$OUT/lib"
for l in libhwbinder libhidlbase libhidltransport libhidlmemory android.hidl.base@1.0 android.hidl.memory@1.0; do
  adb pull /system/lib64/$l.so "$OUT/lib64/" >/dev/null
  adb pull /system/lib/$l.so   "$OUT/lib/"   >/dev/null
  echo "pulled $l"
done
