#!/bin/bash
# Run this BEFORE rebooting into a freshly flashed system. While the phone bootloops it grabs
# logcat the moment adb appears, so you can see why it dies (the phone has no pstore/last_kmsg).
# Usage: ./capture_boot_logs.sh <output-dir> [seconds=420]
O="${1:?usage: $0 <output-dir> [seconds]}"; mkdir -p "$O"; end=$((SECONDS+${2:-420})); n=0
while [ $SECONDS -lt $end ]; do
  if [ "$(adb get-state 2>/dev/null)" = "device" ]; then
    n=$((n+1)); timeout 8 adb logcat -d -b all > "$O/logcat_$n.txt" 2>&1
    echo "$(date +%T) captured #$n ($(wc -l < "$O/logcat_$n.txt") lines)"
  fi; sleep 1
done
echo "look for:  grep -h 'CANNOT LINK\|Fatal signal' $O/logcat_*.txt | sort | uniq -c | sort -rn | head"
