#!/bin/bash
# Back up the important partitions of a rooted Huawei Y6 2018 (ATU-Lxx) to this PC,
# verifying each one with sha256. Needs: adb, a device with root (Magisk) granted to "Shell".
# Usage: ./backup_partitions.sh <output-dir>
# WARNING: the output contains your IMEI/serial/calibration data (oeminfo, persist, modemst*).
#          Keep it PRIVATE and never share it.
set -u
OUT="${1:?usage: $0 <output-dir>}"
mkdir -p "$OUT" && cd "$OUT" || exit 1
BYNAME=/dev/block/bootdevice/by-name
# oeminfo/persist/modemst*/fsg/modem hold IMEI + calibration: irreplaceable. Do these first.
PARTS="oeminfo persist modemst1 modemst2 fsg modem misc kernel ramdisk recovery_ramdisk recovery_vendor erecovery_kernel erecovery_ramdisk erecovery_vendor odm product cust vendor system"
adb get-state >/dev/null 2>&1 || { echo "no adb device"; exit 1; }
adb shell su -c id 2>/dev/null | grep -q uid=0 || { echo "root not available to the adb shell (grant it in Magisk > Superuser)"; exit 1; }
fail=0
for p in $PARTS; do
  echo "[$(date +%T)] $p"
  adb exec-out "su -c 'dd if=$BYNAME/$p bs=1048576 2>/dev/null'" > "$p.img"
  dev=$(adb shell "su -c 'sha256sum $BYNAME/$p'" | awk '{print $1}')
  loc=$(sha256sum "$p.img" | awk '{print $1}')
  if [ -n "$dev" ] && [ "$dev" = "$loc" ]; then echo "  OK  $(stat -c %s "$p.img") bytes"; else echo "  MISMATCH $p"; fail=1; fi
done
[ $fail = 0 ] && echo "ALL OK" || { echo "SOME PARTITIONS FAILED - re-run (keep the cable still)"; exit 1; }
