#!/bin/bash
# Fix AudioFX (the LineageOS equalizer) on a phh LineageOS 15.1 GSI image.
#
# Problem: the EQ does nothing after boot, works once you open AudioFX, and stops again after any slider move.
# Cause + fix (one line in SessionManager): https://github.com/ada101/lineageos-audiofx-eq-fix/tree/main/15.1-device-profile-bug
# This script puts the already-patched AudioFX.apk from that repo into the GSI image. No Magisk module is needed.
# See docs/06c-fixing-audiofx.md
#
# Usage:  ./patch_audiofx.sh <raw-gsi.img>      (modified IN PLACE; any order relative to patch_gsi.sh / patch_signal_strength.sh)
# Needs:  debugfs + e2fsck (e2fsprogs), sha256sum. No root, nothing is mounted.
# Safety: refuses unless the AudioFX in the image is the exact stock build the patch was made from (phh v5, 2018-06-27).
set -eu
IMG="${1:?usage: $0 <raw-gsi.img>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
NEW="$HERE/../audiofx/AudioFX-patched-2.2.0-lineage-15.1.apk"
STOCK_SHA256="fbbae1e94a4b4995cff7097e90352e366e65bc2d3bb338f46f220f51422e492b"
for c in debugfs e2fsck sha256sum; do command -v $c >/dev/null || { echo "missing tool: $c"; exit 1; }; done
[ -f "$NEW" ] || { echo "missing $NEW"; exit 1; }
[ "$(head -c4 "$IMG" | xxd -p)" = "3aff26ed" ] && { echo "$IMG is a sparse image. Make it raw first (unsparse.py / patch_gsi.sh output)"; exit 1; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

debugfs -R "dump /priv-app/AudioFX/AudioFX.apk $T/stock.apk" "$IMG" >/dev/null 2>&1
[ -s "$T/stock.apk" ] || { echo "no /priv-app/AudioFX/AudioFX.apk in the image"; exit 1; }
cur="$(sha256sum "$T/stock.apk" | cut -d' ' -f1)"
if [ "$cur" = "$(sha256sum "$NEW" | cut -d' ' -f1)" ]; then echo "already patched"; exit 0; fi
[ "$cur" = "$STOCK_SHA256" ] || { echo "AudioFX in this image is not the stock build the patch was made for. Not patching."; echo "Build your own with the original repo's scripts/build.sh instead."; exit 1; }

printf 'u:object_r:system_file:s0\0' > "$T/label.bin"
cat > "$T/cmds" <<CMDS
rm /priv-app/AudioFX/AudioFX.apk
write $NEW /priv-app/AudioFX/AudioFX.apk
sif /priv-app/AudioFX/AudioFX.apk mode 0100644
sif /priv-app/AudioFX/AudioFX.apk uid 0
sif /priv-app/AudioFX/AudioFX.apk gid 0
ea_set -f $T/label.bin /priv-app/AudioFX/AudioFX.apk security.selinux
CMDS
debugfs -w -f "$T/cmds" "$IMG" >/dev/null 2>&1

e2fsck -fn "$IMG" >/dev/null 2>&1 && echo "filesystem check: clean" || { echo "FILESYSTEM CHECK FAILED"; exit 1; }
debugfs -R "dump /priv-app/AudioFX/AudioFX.apk $T/check.apk" "$IMG" >/dev/null 2>&1
cmp -s "$T/check.apk" "$NEW" || { echo "VERIFY FAILED"; exit 1; }
echo "OK: AudioFX patched in $IMG. Flash it with: fastboot flash system $IMG"
