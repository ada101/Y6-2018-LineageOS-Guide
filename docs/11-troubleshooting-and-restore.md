# 11 – Troubleshooting and going back to stock

## Symptom → cause → fix

| Symptom | Likely cause | What to do |
|---|---|---|
| Black screen after the unlock-warning screen, reboots, then eRecovery says **"Data partition severely corrupted"** | Android failed to boot; Huawei's boot-failure monitor (`hw_bfm_enable=1`) forces eRecovery and blames data. Almost never a real data problem | Capture and read the boot log (below). Do not just keep formatting |
| Log shows `CANNOT LINK EXECUTABLE ... gServiceSidMap` (or `setRequestingSid`) | The GSI was not patched, or only partly patched | Run [`patch_gsi.sh`](06-patching-the-gsi.md) and re-flash. All six libraries are needed |
| Vendor services start, then `Fatal signal 7 (SIGBUS)` in `zygote64`, backtrace through `AssetManager::addSystemOverlays` | The GSI is too new (the 2019 LineageOS 15.1 build did this) | Use a 2018 GSI: [05](05-choosing-a-gsi.md) |
| Phone boots to the setup wizard, but "Google Services Framework keeps stopping" on everything | GApps flashed after the first boot; app data folders were not created | Factory reset: [08](08-gapps.md) |
| `su -c id` over adb: `Permission denied`, toast *"Shell was denied superuser access"* | Stored deny rule for Shell in Magisk | [09](09-root-with-magisk.md): Superuser tab → enable Shell |
| Signal bars **always full**, even with no reception; *Network Signal Info* shows ASU 70–111 and dBm like "109" | The modem reports signal as the dBm magnitude | [06b](06b-fixing-signal-bars.md) |
| After flashing the signal patch, the first boot is long and the phone is slow for a few minutes | Android is rebuilding its boot image and re-optimising apps | Wait; about 3 minutes on the verified phone |
| `patch_signal_strength.sh`: *"getGsmSignalStrength() is not in the expected form"* | The GSI is not phh v5 | The script refuses on purpose. Use phh v5, or adapt the diff in `files/signal-fix/` |
| `fastboot reboot recovery` just reboots normally | The bootloader ignores it | `adb reboot recovery`, or Volume Up + Power, or the eRecovery wipe option |
| `fastboot flash misc ...` → `FAILED (remote: 'Command not allowed')` | `misc` is write-protected | Not possible; use the methods above |
| `fastboot erase cache` → `Command not allowed` | Same | Skip it |
| PC shows USB ID `12d1:1037` and `adb`/`fastboot` list nothing | The phone is on the eRecovery screen | Shutdown from there, then Volume Down + USB for fastboot |
| TWRP: `Required key not available` writing to `/data` or `/sdcard` | `/data` is encrypted and TWRP 3.3.1 cannot unlock it | Push to `/tmp`: [08](08-gapps.md) |
| Setup wizard stuck on "Just a sec...", `Failed to unlock: ... unlock_user_key`, `/data/data` empty | A reset with `twrp wipe data` left an old encryption key in `/data/misc` | Empty `/data` fully from TWRP (`rm -rf /data/*`), see [08](08-gapps.md) |
| Phone drops off `adb` right after a Magisk screen | Magisk *"additional setup"* reboot | Wait; it is normal: [09](09-root-with-magisk.md) |
| The Magisk app wants to **Install**/**Update** | It does not understand the Huawei partition layout | Do not. See [09](09-root-with-magisk.md) |

## Reading the boot log

The phone has **no pstore / `last_kmsg`**, so a failed boot leaves nothing behind. Capture while it is trying:

```bash
files/scripts/capture_boot_logs.sh ~/boot-logs        # start BEFORE rebooting
```

While Android is partly up (the vendor services restart in a loop) adb shows the phone as `device` for a few seconds per cycle, and the script
saves a full `logcat -b all` (it includes the kernel log) at each moment. Afterwards:

```bash
grep -h 'CANNOT LINK\|Fatal signal' ~/boot-logs/logcat_*.txt | sort | uniq -c | sort -rn | head
```

What the failures looked like, for reference:

```
# unpatched GSI
F linker: CANNOT LINK EXECUTABLE "/vendor/bin/hw/vendor.display.color@1.0-service": cannot locate symbol
          "_ZN7android8hardware7details14gServiceSidMapE" referenced by "/vendor/lib64/vendor.display.color@1.0_vendor.so"
I ServiceManager: Waiting for service 'SurfaceFlinger' on '/dev/binder'...

# partly patched (hidltransport + hidlbase only)
F linker: CANNOT LINK EXECUTABLE "/vendor/bin/hw_diag_server": cannot locate symbol
          "_ZN7android8hardware9BHwBinder16setRequestingSidEb" referenced by "/system/lib64/vndk-sp-26/libhidltransport.so"

# fully patched, but GSI too new (2019 build)
F libc: Fatal signal 7 (SIGBUS), code 1 (BUS_ADRALN) in tid 586 (main), pid 586 (main)   [zygote64]
F DEBUG: #00 libutils.so SharedBuffer::acquire() ... #03 libandroidfw.so AssetManager::ZipSet::addOverlay ... #04 AssetManager::addSystemOverlays

# working (2018 GSI + six-library patch)
no CANNOT LINK, no Fatal signal, sys.boot_completed=1, setup wizard focused
```

You can check a library for a symbol offline with `readelf --dyn-syms -W <lib> | grep <symbol>`: a *defined* symbol has a section number
in column 7, an *undefined* one says `UND`.

## Going back to stock (**untested**: no restore was ever needed, but the images are checksum-verified)

You need the backup from [04](04-backup.md). With the phone in fastboot mode (Volume Down + USB):

```bash
cd ~/y6-backup
fastboot flash system   system.img
fastboot flash vendor   vendor.img
fastboot flash odm      odm.img
fastboot flash product  product.img
fastboot flash cust     cust.img
fastboot flash kernel   kernel.img
fastboot flash ramdisk  ramdisk.img
fastboot flash recovery_ramdisk recovery_ramdisk.img
fastboot flash recovery_vendor  recovery_vendor.img
fastboot reboot
```

Notes:

- Only `system` was ever changed during this guide, so for a normal "go back" **`system.img` alone is the important one**: flash it and reboot.
- The partitions are read with `dd`, so each image has the partition's full size; `fastboot` accepts that.
- **Do not** flash `oeminfo`, `persist`, `modem*`, `fsg` or `misc` unless you have actually lost your IMEI/radio, and understand what you are doing.
- Afterwards the `/data` partition still holds LineageOS's encrypted data, which stock may reject. Use the wipe/format option on the eRecovery screen (the phone
  shows it after repeated failed boots) or Settings → Reset on the restored system to wipe it.
- **Huawei stock firmware (`UPDATE.APP`)** was *not* needed and none is included. The sites that list ATU-L22 firmware
  (firmwarefile.com returned HTTP 403 to automated access; getdroidtips listed only 8.0.0.158 (C636), with no direct link) were not verified. Your own
  `system.img` backup is the best stock image for your phone.

## Starting over completely

If you want to try a different GSI, the procedure is: fastboot mode → `fastboot flash system <new patched image>` → reboot. Nothing else in the phone needs undoing.
