#!/bin/bash
# Fix the Huawei Y6 2018 signal bars on a GSI image.
#
# Problem: this phone's modem reports GSM signal as the dBm MAGNITUDE (-70 dBm arrives as 70) instead
# of ASU 0..31. Android shows 4 bars for any value >= 12, so the bars are stuck at full.
# Fix: edit android.telephony.SignalStrength.getGsmSignalStrength() in framework.jar so any value
# above 31 (other than 99 = unknown) is converted: asu = (113 - value) / 2, clamped 0..31.
# See docs/06b-fixing-signal-bars.md and files/signal-fix/*.diff
#
# Usage:  ./patch_signal_strength.sh <raw-gsi.img>            (modified IN PLACE; run patch_gsi.sh first)
# Needs:  java, apktool (3.x tested: set APKTOOL=/path/to/apktool.jar or have 'apktool' on PATH),
#         debugfs + e2fsck (e2fsprogs), python3, zip/unzip. No root, nothing is mounted.
# Result: framework.jar replaced; the pre-compiled boot images are removed so Android rebuilds them
#         on the first boot (about 3 minutes on the verified phone).
set -eu
IMG="${1:?usage: $0 <raw-gsi.img>}"
APKTOOL="${APKTOOL:-apktool}"
case "$APKTOOL" in *.jar) AT=(java -jar "$APKTOOL");; *) AT=("$APKTOOL");; esac
for c in debugfs e2fsck python3 zip unzip java; do command -v $c >/dev/null || { echo "missing tool: $c"; exit 1; }; done
[ "$(head -c4 "$IMG" | xxd -p)" = "3aff26ed" ] && { echo "$IMG is a sparse image. Make it raw first (unsparse.py / patch_gsi.sh output)"; exit 1; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

debugfs -R "dump /framework/framework.jar $T/framework.jar" "$IMG" >/dev/null 2>&1
[ -s "$T/framework.jar" ] || { echo "no /framework/framework.jar in the image"; exit 1; }

echo "decompiling framework.jar ..."
"${AT[@]}" d -f --no-res -o "$T/src" "$T/framework.jar" >/dev/null 2>&1
SMALI="$(find "$T/src" -path '*android/telephony/SignalStrength.smali' | head -1)"
[ -n "$SMALI" ] || { echo "SignalStrength.smali not found"; exit 1; }
DEX="classes.dex"; case "$SMALI" in */smali_classes*/*) n="${SMALI#*smali_classes}"; DEX="classes${n%%/*}.dex";; esac

python3 -I - "$SMALI" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old=""".method public getGsmSignalStrength()I
    .locals 1

    .prologue
    .line 460
    iget v0, p0, Landroid/telephony/SignalStrength;->mGsmSignalStrength:I

    return v0
.end method"""
new=""".method public getGsmSignalStrength()I
    .locals 2

    .prologue
    .line 460
    iget v0, p0, Landroid/telephony/SignalStrength;->mGsmSignalStrength:I

    # Y6 2018 GSI patch: modem reports GSM RSSI as the dBm MAGNITUDE (-70 dBm -> 70), not ASU 0..31
    # (99 = unknown). Anything above 31 other than 99 is a magnitude: asu = (113 - v) / 2, clamped 0..31.
    const/16 v1, 0x1f

    if-le v0, v1, :cond_done

    const/16 v1, 0x63

    if-eq v0, v1, :cond_done

    rsub-int v0, v0, 0x71

    div-int/lit8 v0, v0, 0x2

    if-gez v0, :cond_nonneg

    const/4 v0, 0x0

    :cond_nonneg
    const/16 v1, 0x1f

    if-le v0, v1, :cond_done

    const/16 v0, 0x1f

    :cond_done
    return v0
.end method"""
if new in s: sys.exit("already patched")
if old not in s: sys.exit("getGsmSignalStrength() is not in the expected form: this is not the phh v5 framework. Not patching.")
open(p,"w").write(s.replace(old,new))
PY

echo "rebuilding $DEX ..."
"${AT[@]}" b -f -o "$T/rebuilt.jar" "$T/src" >/dev/null 2>&1
[ -s "$T/src/build/apk/$DEX" ] || { echo "build failed"; exit 1; }
mkdir "$T/upd" && cp "$T/src/build/apk/$DEX" "$T/upd/$DEX"
cp "$T/framework.jar" "$T/framework_new.jar"
( cd "$T/upd" && zip -q -X "$T/framework_new.jar" "$DEX" )
unzip -tq "$T/framework_new.jar" >/dev/null || { echo "patched jar is corrupt"; exit 1; }

# write into the image (same owner/mode/SELinux label) and drop the stale compiled boot images
printf 'u:object_r:system_file:s0\0' > "$T/label.bin"
: > "$T/cmds"
printf 'rm /framework/framework.jar\nwrite %s/framework_new.jar /framework/framework.jar\nsif /framework/framework.jar mode 0100644\nsif /framework/framework.jar uid 0\nsif /framework/framework.jar gid 0\nea_set -f %s/label.bin /framework/framework.jar security.selinux\n' "$T" "$T" >> "$T/cmds"
for a in arm arm64; do
  for f in $(debugfs -R "ls /framework/$a" "$IMG" 2>/dev/null | tr -s ' ' '\n' | grep -E '^boot'); do echo "rm /framework/$a/$f" >> "$T/cmds"; done
done
debugfs -w -f "$T/cmds" "$IMG" >/dev/null 2>&1

e2fsck -fn "$IMG" >/dev/null 2>&1 && echo "filesystem check: clean" || { echo "FILESYSTEM CHECK FAILED"; exit 1; }
debugfs -R "dump /framework/framework.jar $T/check.jar" "$IMG" >/dev/null 2>&1
cmp -s "$T/check.jar" "$T/framework_new.jar" || { echo "VERIFY FAILED"; exit 1; }
echo "OK: SignalStrength patched in $IMG. Flash it with: fastboot flash system $IMG"
