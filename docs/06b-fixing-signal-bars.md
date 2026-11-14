# 06b – Fixing the signal bars

**Do this between patching ([06](06-patching-the-gsi.md)) and flashing ([07](07-flashing-the-gsi.md))**, so you flash once.
It is recommended: without it the signal bars are **permanently stuck at 4**, whatever the real reception.

> **Result:** after this patch, two phones (this one and a reference phone) sitting side by side through a whole phone call
> showed **exactly the same signal numbers all the way** in *Network Signal Info*, and the bars follow the real signal.

## The problem

After the first boot, the status bar showed no bars. Later (after GApps and a factory reset) it showed bars, but they were **always full**. Walking to a spot
with no reception, where a call was dropping out, **still showed 4 bars**.

Installing *Network Signal Info* made the cause visible. The Y6 and a reference phone (a Nexus S with a SIM on the same 2G carrier network), taken to the same two places:

| | Dead spot (call drops) | Good spot |
|---|---|---|
| Reference phone | **ASU 2**, −109 dBm | **ASU 26**, −61 dBm |
| Y6, as shipped by the GSI | **ASU 111** (app shows "109 dBm") | **ASU 74** (app shows "35 dBm") |

Live `adb logcat -b radio` on the Y6 showed the cause directly. Android asks the modem for signal strength every 20 seconds, and the answer
fluctuates around the same number at a fixed spot:

```
RILJ: [4407]< SIGNAL_STRENGTH SignalStrength: 75 0 -1 -1 -1 -1 -1 99 ...
RILJ: [4422]< SIGNAL_STRENGTH SignalStrength: 69 0 -1 -1 -1 -1 -1 99 ...
RILJ: [4424]< SIGNAL_STRENGTH SignalStrength: 70 0 -1 -1 -1 -1 -1 99 ...
```

## The cause

Android expects GSM signal as an **ASU from 0 to 31** (ASU = (dBm + 113) / 2, so 0 ≈ −113 dBm and 31 ≈ −51 dBm), or **99 for "unknown"**.

This modem instead reports the **signal in dBm with the minus sign dropped**: −70 dBm arrives as `70`. Real dBm readings fall between about
−51 and −113, so the values are always between 51 and 113: nothing like 0–31.

How Android turns that into bars (`SignalStrength.getGsmLevel()`, read from the GSI's decompiled framework):

| ASU | Bars |
|---|---|
| ≤ 2, or 99 | 0 |
| 3–4 | 1 |
| 5–7 | 2 |
| 8–11 | 3 |
| **≥ 12** | **4** |

Every value this modem sends is ≥ 51, so the answer is always **4 bars**. A *weaker* signal gives a *bigger* number, which also makes no difference: still
4 bars. Apps compute dBm as `2 × ASU − 113` and so show the odd "109 dBm" and "35 dBm".

Why Huawei's own ROM shows correct bars: it most likely handles the modem's units in a Huawei class that LineageOS lacks (`HwQualcommRIL`, named by the
`ro.telephony.ril_class` property; this is an inference, since that code was not examined). On the stock ROM, *Network Signal Info* also showed nothing useful, which fits:
Huawei's own screens use their own path, while ordinary apps use the standard API.

## The fix

Patch one method in the framework, `android.telephony.SignalStrength.getGsmSignalStrength()`. Any value **above 31 (other than 99)** is treated as a dBm magnitude
and converted:

```
asu = (113 − value) / 2        clamped to 0 .. 31
```

| Raw value from the modem | Becomes | Bars |
|---|---|---|
| 111 (dead spot) | ASU 1 (−111 dBm) | **0** |
| 85 | ASU 14 | 4 |
| 75 | ASU 19 | 4 |
| 70 (good spot at home) | ASU 21 | 4 |
| 99 | left alone (Android's "unknown") | 0 |
| 0–31 (a real ASU, if a modem ever sends one) | unchanged | as normal |

It lives in the **getter**, so it fixes the status bar, and every app that reads the signal (including *Network Signal Info*) through the standard API.
The exact change is in [`files/signal-fix/SignalStrength-getGsmSignalStrength.diff`](../files/signal-fix/SignalStrength-getGsmSignalStrength.diff).

## Apply it

Run it on the raw image that `patch_gsi.sh` produced (step 06):

```bash
APKTOOL=/path/to/apktool.jar  files/scripts/patch_signal_strength.sh ~/y6-patched.img
```

It needs `java`, **apktool** (Apache-2.0, [apktool.org](https://apktool.org); **3.0.3** was used, not included here), `zip`/`unzip` and `debugfs`.
No root; nothing is mounted. It takes about 40 seconds. It:

1. reads `framework.jar` out of the image and decompiles it,
2. replaces the method (and **refuses to continue** if the method is not in the expected form, so it won't touch a different GSI),
3. rebuilds the dex, swaps only the changed `classes2.dex` into the original jar, and checks the jar,
4. writes the jar back with the same owner, mode and SELinux label,
5. **deletes the pre-compiled boot images** (`/framework/arm/boot*` and `/framework/arm64/boot*`, 90 files),
6. runs a filesystem check and verifies the jar byte for byte.

### Why the boot images are removed

The framework's pre-compiled boot image holds the **old compiled code** for that method (it may even be inlined into its callers), so replacing only
the jar could silently do nothing. With the images gone, Android rebuilds them from the new jar on the first boot, into `/data/dalvik-cache/arm64/`.
You can check that it happened:

```bash
adb shell su -c "ls -la /data/dalvik-cache/arm64 | grep boot"      # system@framework@boot.art / .oat / .vdex
adb shell md5sum /system/framework/framework.jar                   # must match the patched jar
```

**First boot after this takes a few minutes** (about 3 on the verified phone, from reboot to `sys.boot_completed`), and the phone is sluggish for a bit afterwards
while apps are re-optimised (a `dex2oat` process runs). Your data and Magisk are untouched. **GApps is not**: flashing `system` replaces the whole partition, and GApps lives there,
so on a phone that already has GApps they disappear (Play Services, Play Store, Gmail then complain). **Do this patch before GApps, then flash GApps
([08](08-gapps.md)) after the final `system` flash.** Every later `system` flash needs GApps flashed again, and a factory reset (see 08).

### Or use the ready-made image

For the **ATU-L22 on EMUI 8.0.0.139 (C34)**, the image with *both* patches (the six libraries and this one) is included:

```bash
xz -dk files/prebuilt/v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img.xz
fastboot flash system files/prebuilt/v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img
```

The already-patched `framework.jar` alone is in
[`files/signal-fix/framework-patched-phh-v5-2018-06-27.jar`](../files/signal-fix/framework-patched-phh-v5-2018-06-27.jar)
(for the phh v5 GSI only).

## Check it worked

1. Open **Network Signal Info → Mobile**. Before: something like `35 dBm * 74 ASU`. After: a **negative dBm** and a small ASU, such as
   **`-75 dBm * 19 ASU`**, and a graph that is not pinned to the top.
2. Compare the bars with another phone in a weak spot. They should drop with the real signal.
3. From the PC: `adb shell dumpsys telephony.registry | grep mSignalStrength` still prints the **raw** field (e.g. `75`). This is expected, because the registry
   shows the stored value; the conversion happens when apps read it. The real result is the app, and
   `dumpsys activity service com.android.systemui/.SystemUIService | grep MobileSignalController` shows the status-bar `level=`.

## What was verified, and what was not

| | |
|---|---|
| **Verified** | On GSM (2G / EDGE, 2G carrier network, roaming): the status bar, and *Network Signal Info* gave **identical readings to a reference phone side by side through a whole call** |
| **Verified** | Rebuilding from the original download with the two scripts gives a framework with the identical patched code (same CRC for the dex). Only the timestamp inside the jar differs |
| **Not tested** | **LTE and 3G.** If the modem uses the same convention for LTE RSRP or WCDMA RSCP (plausible), those need the same treatment, in `getLteRsrp`/`getWcdmaDbm`. Capture raw values with `adb logcat -b radio | grep SIGNAL_STRENGTH` on those networks first |
| Known edge | A real reading of **exactly −99 dBm** arrives as `99`, which Android reads as "unknown", so the bars read 0 at that single value |
| Unexplained | *Network Signal Info* showed **"Net. type: Unknown"** on the Y6 where the reference phone said EDGE. After the later GApps re-flash and a full `/data` wipe it showed **EDGE * 220 kbps** (with `-79 dBm * 17 ASU`). What changed that fixed it was not isolated: it could be the order of flashing (patch, then GApps), the clean `/data`, or the app's permissions on a fresh install |

## Technical notes

- The patched method (smali), in full, is in the `.diff`. It uses two registers instead of one.
- apktool rebuilds the whole dex, and in doing so dropped one **duplicate, unreachable** exception handler in an unrelated keystore class
  (`AndroidKeyStoreKeyPairGeneratorSpi`: a second `catch IllegalArgumentException` on a range where an earlier one already matches). Behaviour
  is unchanged. All 10,628 classes are present after the rebuild.
- Only `classes2.dex` is swapped; `classes.dex` and the manifest in the jar are the original bytes.

Continue with [07 – Flashing the GSI](07-flashing-the-gsi.md).
