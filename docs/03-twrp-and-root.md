# 03 – TWRP and root (the original method)

This section is the root procedure from the Ministry of Solutions write-up, put into plain steps.
The page is saved at [`reference/original-root-guide/webpage.html`](../reference/original-root-guide/webpage.html) and the
files it refers to are in this folder. Needs an **unlocked bootloader** ([02](02-bootloader-unlock.md)).

Why you need this for the LineageOS install: TWRP is how you flash GApps later ([08](08-gapps.md)), and
Magisk in the boot ramdisk is what gives you root. Both live in partitions that the GSI flash
**does not touch**, so they survive the whole procedure.

## Files

| File | What it is |
|---|---|
| [`files/recovery/TWRPATU.img`](../files/recovery/TWRPATU.img) | TWRP **3.3.1** for the ATU series (credit on the original page: *xBrownieCodez*). 9,363,456 bytes. |
| [`files/magisk/Magisk-v20.4.zip`](../files/magisk/Magisk-v20.4.zip) | Magisk **v20.4**, the version used by the original method |
| [`files/windows-tools/`](../files/windows-tools/) | `adb.exe`, `fastboot.exe`, drivers DLLs, and `MAF32.exe`, a Windows command-prompt launcher. On Linux use the platform-tools instead. |

### Where the kit came from

The original page says to download `HUAWEIATUROOT.zip` (password `ministryofsolutions.com`, 15.5 MB). **Its download link is dead**: the file host
shows *"no mirrors found"* ([screenshot](../reference/ministryofsolutions-HUAWEIATUROOT-download-page.jpg): uploaded 28 Oct 2020, listed MD5
`ad1f8a1786eccecd9d2f1579e870bdf7`). I got the zip from the seller I bought the unlock code from, who found a copy when I asked
([chat](../reference/unlock-chat-redacted.md)).

**The original archive is kept here, unmodified, for anyone who wants to audit it:**
[`files/original-kit/HUAWEIATUROOT.zip`](../files/original-kit/HUAWEIATUROOT.zip)

| | |
|---|---|
| Size | 16,295,651 bytes (15.5 MiB, matching the "15.5MB" on the download page) |
| MD5 | `ad1f8a1786eccecd9d2f1579e870bdf7`, **identical to the MD5 on the original download page** |
| SHA-256 | `788da18e4fbc9e231ec9f0d38624fa251ace7273e3f5043b6cc114eebbf39d69` |
| Encryption | ZIP with AES-256; the password given on the original page is `ministryofsolutions.com` |
| Contents | 7 files: `TWRPATU.img`, `Magisk-v20.4.zip`, `adb.exe`, `AdbWinApi.dll`, `AdbWinUsbApi.dll`, `fastboot.exe`, `MAF32.exe` |

I extracted the archive in a scratch folder and compared it: **all seven files are byte-identical** to the copies in `files/recovery/`, `files/magisk/` and
`files/windows-tools/`, which are the ones the rest of this guide uses. To extract it yourself, put it in its own empty folder first:

```bash
mkdir kit && 7z x -pministryofsolutions.com -okit files/original-kit/HUAWEIATUROOT.zip
```

The checksums of the extracted files are in [Appendix B](appendix-b-file-manifest.md).

I verified that `TWRPATU.img` is **byte-identical** to the start of the `recovery_ramdisk` partition read back from a phone that was
working with this guide, so it is the image that was running.

## Steps

1. **Back up everything** you care about. (Unlocking already wiped the phone once; this step just reminds you not to flash anything blind.)
2. **Enable OEM unlocking** in Developer options (tap Build number 7 times to get the menu).
3. **Unlock the bootloader.** See [02](02-bootloader-unlock.md).
4. **Boot into fastboot mode**: power the phone off, hold **Volume Down**, and plug in the USB cable.
5. **Flash TWRP to the `recovery_ramdisk` partition.** On this phone the recovery lives in `recovery_ramdisk`, *not* `recovery`:

   ```bash
   fastboot flash recovery_ramdisk TWRPATU.img
   ```

   (The original page runs this inside `MAF32.exe`, which is a Windows command window with fastboot on the path.)
6. **Unplug the cable.**
7. **Boot into TWRP**: with the phone **off and unplugged**, hold **Volume Up + Power**. Keep holding Volume Up after the Huawei
   logo appears and release only Power. TWRP opens. Swipe to allow modifications.
8. **Flash Magisk.** The original page copies the zip to an SD card, then *Install → Select Storage → SD card →* the zip.
   If you have no SD card: with the phone in TWRP and plugged in, run

   ```bash
   adb push Magisk-v20.4.zip /tmp/ && adb shell twrp install /tmp/Magisk-v20.4.zip
   ```

   (`/tmp` lives in RAM and works even when TWRP cannot read the encrypted `/data`. See [08](08-gapps.md).)
9. **Reboot to system.** If TWRP offers to install anything, choose **Do not install**.
10. Open the Magisk app. You now have root.

The original page's last line: *"Don't update/reset the phone after the root."* That warning is about Huawei's stock firmware;
in the LineageOS setup in this guide a factory reset was done and root was **not** lost, because Magisk lives in the `ramdisk`
partition and the reset only wipes `/data`.

## Notes from the field

- **Entering TWRP can be fiddly.** The Volume Up + Power combination did not work every time in testing.
  If the phone is running Android with adb on, `adb reboot recovery` is more reliable.
  `fastboot reboot recovery` is **ignored** by this bootloader. More in [11](11-troubleshooting-and-restore.md).
- **Which Magisk does the phone actually run?** The phone in this guide had been updated well past v20.4 over the years: its
  daemon reports **29.0**. A fresh install of `Magisk-v20.4.zip` was **not** re-tested as part of the LineageOS procedure.
  The older version is what the original method used and what is archived here. If you root fresh and then want a newer Magisk, read
  [09](09-root-with-magisk.md) first. **Magisk's in-app "Install" is dangerous on this phone's partition layout.**
- **TWRP and encrypted `/data`**: once Android has encrypted `/data`, TWRP 3.3.1 cannot read it
  (`Required key not available`). Push files to `/tmp` instead of internal storage.

Continue with [04 – Back up your phone](04-backup.md).
