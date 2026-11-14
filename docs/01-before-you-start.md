# 01 – Before you start

## Is this your phone?

Huawei Y6 2018 / Y6 Prime 2018: model codes **ATU-L21, ATU-L22, ATU-L31, ATU-L41, ATU-L42** (also
ATU-L11, ATU-LX3 in some regions). Chipset Snapdragon 430 (**msm8937**), 2 GB RAM, 16 GB eMMC,
shipped with **Android 8.0 / EMUI 8.0**.

Check from a running phone:

```bash
adb shell getprop ro.product.model          # ATU-L22
adb shell getprop ro.board.platform         # msm8937
adb shell getprop ro.treble.enabled         # true
adb shell getprop ro.build.display.id       # e.g. ATU-L22 8.0.0.139(C34)
```

This guide was verified on **ATU-L22 8.0.0.139 (C34)**. The libraries patched in
[06](06-patching-the-gsi.md) come *from the phone's own stock firmware*, so they match whatever you have.
The phh Treble wiki lists the L21, L22 and L42 as tested with GSIs, and its notes were written against
an L22 on 8.0.0.143. If you are on a different firmware build, back up first (see [04](04-backup.md)) and the
patch script will use the libraries from your backup.

**Your phone must still be on Android 8.0 / EMUI 8.0 stock vendor.** The whole approach reuses
Huawei's vendor partition. Do not update, and do not flash other Huawei firmware first.

## What you need

On the PC (Linux was used; Windows works for the fastboot parts using the tools in `files/windows-tools/`):

- `adb` and `fastboot` (Android platform-tools)
- `debugfs` and `e2fsck` (package **e2fsprogs**): used by the patch script, no root needed
- `python3`
- ~15 GB free disk: ~4 GB backup, ~2 GB each for the raw GSI, patched image, and the original download
- A USB cable and port you trust. **A cable that drops during `fastboot flash` can corrupt a partition.**
  Keep the phone still. (The phone this guide was written on had a damaged USB port, and every
  flash was verified afterwards.)

On the phone:

- Bootloader **unlocked** ([02](02-bootloader-unlock.md))
- **TWRP** in the recovery partition ([03](03-twrp-and-root.md))
- Ideally **Magisk root** (needed for the convenient backup script; TWRP's root adb can do it otherwise)
- Charged, and nothing on it you need: it is wiped

## What will be wiped

- Unlocking the bootloader wipes the phone (done once, in 02).
- Flashing the GSI replaces `/system`.
- Installing GApps and then factory-resetting wipes `/data` again.

Everything on internal storage is gone by the end. Copy off photos, contacts and so on first.

## Your backup holds your phone's identity

The backup in [04](04-backup.md) contains your phone's **IMEI, serial number and radio calibration**. Keep your copy somewhere safe, and don't
post it or send it to anyone.

## How the problem looks (so you recognise it later)

If you flash a stock GSI on this phone without the patch, the phone shows a black screen and
reboots, then drops into Huawei's **eRecovery** with *"Data partition severely corrupted"*.
That message is misleading. See [11 – Troubleshooting](11-troubleshooting-and-restore.md).

## Risk summary

- The unlock-code step involves paying an online seller and giving them your IMEI and remote access. See [02](02-bootloader-unlock.md).
- Writing to `misc` is **blocked** by this bootloader, so some "reboot to recovery" tricks do not work.
- Everything flashed here was done over fastboot to `system` only, so the vendor, modem and boot partitions were never changed by the GSI flash.
- No restore from backup was ever *needed* during this work, so the restore procedure in [11](11-troubleshooting-and-restore.md) is **untested** (the backup images themselves were checksum-verified).
