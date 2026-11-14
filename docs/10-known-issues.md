# 10 – Known issues

## Signal bars: fixed (see 06b)

**Symptom without the fix:** no bars after the first boot; later the bars appear but are **always full**, even in a spot where a call is dropping, and apps
such as *Network Signal Info* show odd numbers (for example "109 dBm * 111 ASU").

**Cause:** this phone's modem reports GSM signal as the dBm magnitude (−70 dBm arrives as `70`) instead of an ASU from 0 to 31. Android shows 4 bars
for any value ≥ 12.

**Fix:** a small patch to the framework, [06b – Fixing the signal bars](06b-fixing-signal-bars.md). With it, the readings matched a second phone side
by side through a whole call.

**Still untested:** LTE and 3G (the modem may use the same convention there). The whole diagnosis was done on GSM/EDGE.

An earlier version of this guide said the bars *"started working after GApps and a factory reset, cause unknown"*. That was a misreading: the apps then showed
a number only because the radio was returning raw values, and the bars were still wrong (stuck at 4). **Still unexplained:** why the modem answered
`99` ("unknown") at first and only started returning real values later, after GApps and the factory reset.

## Google Play certification

This is an **uncertified GSI**. The Play Store may say the device is not certified, and some apps (banking, some streaming) may refuse to run or
limit features. Not tested. Magisk's tools to work around it were not installed (no modules on this phone, see [09](09-root-with-magisk.md)).

## Reported by the phh wiki for this phone, not checked

- The stock camera app takes very dark photos without flash; a third-party camera app is recommended.
- Fast charging works; face unlock works with Google Face Unlock.

## Things that were not tested

GPS fix outdoors (the GNSS/location services run), camera photo quality, VoLTE, NFC, FM radio, tethering/hotspot, SD-card handling,
long-term battery life, OTA updates (there are none for a GSI: reflash).

## Other observations

- The phone is a **userdebug** build (`ro.debuggable=1`, `test-keys`). `adb` has more access than on a user build.
- During boot there are SELinux `avc: denied` lines (for example for `bootanim` and the Phh `phhsu_daemon`). They did not stop anything from working.
- The first boot after GApps shows one early system-server error in the crash log with a bogus 2018 timestamp (the clock is not set yet); the system server stayed up.
- No restore to stock was ever needed. The restore steps in [11](11-troubleshooting-and-restore.md) are untested.
