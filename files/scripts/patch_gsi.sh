#!/bin/bash
# Patch a Treble GSI so it boots on the Huawei Y6 2018 stock EMUI 8.0 vendor.
#
# Problem: Huawei's vendor HAL services need symbols (android::hardware::details::gServiceSidMap,
# BHwBinder::setRequestingSid) that exist only in Huawei's own 8.0 HIDL libs. A stock GSI's
# /system/lib*/vndk-sp-26/ copies lack them, so every vendor service dies with
# 'CANNOT LINK EXECUTABLE ... cannot locate symbol' and you get a black screen + bootloop.
# Fix: replace six libs in vndk-sp-26 with the phone's own stock ones.
#
# Usage:  ./patch_gsi.sh <gsi.img> <stock-source> <out-raw.img>
#   <gsi.img>        sparse or raw GSI (e.g. 2018-06-27-system-arm64-aonly-vanilla-nosu.img)
#   <stock-source>   EITHER your backed-up stock system.img (ext4)  OR a directory with lib/ and lib64/
#                    (see pull_stock_libs.sh)
#   <out-raw.img>    result; flash with: fastboot flash system <out-raw.img>
# Needs: debugfs + e2fsck (package e2fsprogs), python3, cmp. No root, no loop mounts.
set -eu
GSI="${1:?see usage in script header}"; STOCK="${2:?}"; OUT="${3:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LIBS="libhwbinder libhidlbase libhidltransport libhidlmemory android.hidl.base@1.0 android.hidl.memory@1.0"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
command -v debugfs >/dev/null || { echo "install e2fsprogs (debugfs)"; exit 1; }

# 1. raw GSI
if [ "$(head -c4 "$GSI" | xxd -p)" = "3aff26ed" ]; then python3 -I "$HERE/unsparse.py" "$GSI" "$OUT"; else cp "$GSI" "$OUT"; fi
debugfs -R "stat /lib64/vndk-sp-26" "$OUT" >/dev/null 2>&1 || { echo "this GSI has no /lib64/vndk-sp-26 - not an Android 8.1/9 GSI?"; exit 1; }

# 2. collect the stock libs
mkdir -p "$T/lib64" "$T/lib"
for l in $LIBS; do for d in lib64 lib; do
  if [ -d "$STOCK" ]; then cp "$STOCK/$d/$l.so" "$T/$d/$l.so"
  else debugfs -R "dump /$d/$l.so $T/$d/$l.so" "$STOCK" >/dev/null 2>&1; fi
  [ -s "$T/$d/$l.so" ] || { echo "missing stock $d/$l.so"; exit 1; }
done; done
# sanity: the stock libhidltransport must actually define the symbol we are adding
readelf --dyn-syms -W "$T/lib64/libhidltransport.so" 2>/dev/null | grep -q gServiceSidMap || echo "WARNING: stock libhidltransport has no gServiceSidMap - is this really Huawei EMUI 8.0 firmware?"

# 3. write them in, same owner/mode/SELinux label as the files they replace
printf 'u:object_r:system_file:s0\0' > "$T/label.bin"
: > "$T/cmds"
for l in $LIBS; do for d in lib64 lib; do p=/$d/vndk-sp-26/$l.so
  printf 'rm %s\nwrite %s/%s/%s.so %s\nsif %s mode 0100644\nsif %s uid 0\nsif %s gid 0\nea_set -f %s/label.bin %s security.selinux\n' \
    "$p" "$T" "$d" "$l" "$p" "$p" "$p" "$p" "$T" "$p" >> "$T/cmds"
done; done
debugfs -w -f "$T/cmds" "$OUT" >/dev/null 2>&1

# 4. verify
e2fsck -fn "$OUT" >/dev/null 2>&1 && echo "filesystem check: clean" || { echo "FILESYSTEM CHECK FAILED"; exit 1; }
for l in $LIBS; do for d in lib64 lib; do
  debugfs -R "dump /$d/vndk-sp-26/$l.so $T/chk.so" "$OUT" >/dev/null 2>&1
  cmp -s "$T/chk.so" "$T/$d/$l.so" || { echo "VERIFY FAILED $d/$l"; exit 1; }
done; done
echo "OK: 12 libraries patched into $OUT ($(stat -c %s "$OUT") bytes). Flash with: fastboot flash system $OUT"
