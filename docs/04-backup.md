# 04 – Back up your phone

**Do this before you flash anything.** Some of these partitions cannot be re-downloaded: they hold *your* phone's IMEI
and radio calibration.

## What gets backed up and why

| Partition(s) | Why it matters |
|---|---|
| `oeminfo`, `persist`, `modemst1`, `modemst2`, `fsg`, `modem`, `misc` | **IMEI, serial, MACs, radio/sensor calibration.** Irreplaceable |
| `system`, `vendor`, `odm`, `product`, `cust` | Your exact stock firmware, so you can go back to stock, **and the source of the libraries for [06](06-patching-the-gsi.md)** |
| `kernel`, `ramdisk`, `recovery_ramdisk`, `recovery_vendor`, `erecovery_kernel`, `erecovery_ramdisk`, `erecovery_vendor` | Boot images, TWRP (`recovery_ramdisk`), Huawei eRecovery |

`userdata` is **not** backed up (10 GB, encrypted). Copy off what you want from the phone itself.

## Run it

Needs a **rooted** phone and root granted to the adb **Shell** in the Magisk app (Superuser tab). See [09](09-root-with-magisk.md).

```bash
files/scripts/backup_partitions.sh ~/y6-backup
```

It reads each partition over adb with `dd`, then compares a **sha256 computed on the phone** with one computed on the PC,
and prints `OK` or `MISMATCH` per partition. It took about 2 minutes for the 4 GB.
Re-run if anything says MISMATCH, and keep the cable still.

Expected sizes on the verified phone (`ls -l`):

| File | Bytes |
|---|---|
| `oeminfo.img` | 67,108,864 |
| `persist.img` | 33,554,432 |
| `modem.img` | 100,663,296 |
| `system.img` | 2,751,463,424 |
| `vendor.img` | 637,534,208 |
| `kernel.img` | 58,720,256 |
| `recovery_ramdisk.img` | 33,554,432 |

(Sizes are those of a 16 GB ATU-L22; yours should match if it is the same model.)

## Without root

If you cannot root first, TWRP's adb runs as root already, so the same `dd` works with the `su -c '...'` wrapper
removed (**untested here**):

```bash
adb exec-out "dd if=/dev/block/bootdevice/by-name/system bs=1048576" > system.img
```

## Keep it safe and private

The folder contains your **IMEI and serial number**. Store it somewhere safe, and **do not upload or share it**.

## Useful offline: read files out of the backup

You can read single files out of `system.img` without root or mounting, using `debugfs`:

```bash
debugfs -R "ls /lib64" ~/y6-backup/system.img
debugfs -R "dump /lib64/libhidltransport.so ./libhidltransport.so" ~/y6-backup/system.img
```

This is how the patch script ([06](06-patching-the-gsi.md)) takes the libraries. Nothing is mounted or modified.

Continue with [05 – Choosing a GSI](05-choosing-a-gsi.md).
