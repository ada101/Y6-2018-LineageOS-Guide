# 06 – Patching the GSI (the key step)

This is the step that makes the difference between a bootloop and a working phone.

## The problem

Huawei's EMUI 8.0 vendor partition contains dozens of HAL services (display, graphics, radio, Wi-Fi, GNSS, sensors, ...).
Many of them link against Huawei's own build of Android's HIDL libraries, which has **extra symbols** that a normal Android build
does not have:

| Symbol | Needed by | Defined in (stock Huawei) |
|---|---|---|
| `android::hardware::details::gServiceSidMap` | `vendor.huawei.hardware.*@1.0.so` and `vendor.qti.*` HALs | `libhidltransport.so` |
| `android::hardware::BHwBinder::setRequestingSid(bool)` | stock `libhidltransport.so` | `libhwbinder.so` |

Treble GSIs ship compatibility copies of the old libraries in `/system/lib/vndk-sp-26/` and `/system/lib64/vndk-sp-26/`.
A phone with an **8.0 vendor** has its vendor processes linked against **that** folder, and its copies lack the two symbols.
Every one of those services dies at startup:

```
F linker : CANNOT LINK EXECUTABLE "/vendor/bin/hw/vendor.qti.hardware.perf@1.0-service":
           cannot locate symbol "_ZN7android8hardware7details14gServiceSidMapE"
           referenced by "/vendor/lib64/vendor.huawei.hardware.teecdaemon@1.0.so"
```

With the display HALs dead, SurfaceFlinger waits forever (`ServiceManager: Waiting for service 'SurfaceFlinger'`),
the screen stays black, Huawei's boot-failure monitor counts failed boots, and you end up in eRecovery.

## The fix

Replace **six** libraries in `vndk-sp-26` (both `lib64` and `lib`, so **12 files**) with the **phone's own stock versions**:

| Library | Role |
|---|---|
| `libhwbinder.so` | defines `setRequestingSid` |
| `libhidltransport.so` | defines `gServiceSidMap` |
| `libhidlbase.so` | HIDL core |
| `libhidlmemory.so` | HIDL shared memory |
| `android.hidl.base@1.0.so` | HIDL base interface |
| `android.hidl.memory@1.0.so` | HIDL memory interface |

They are a **matched set**: replacing only some of them just moves the failure one library further along
(shown in practice: with only `libhidltransport` + `libhidlbase` swapped, the next error was the missing `setRequestingSid` in `libhwbinder`).

Only `vndk-sp-26` is changed. The GSI's own `/system/lib*/` libraries, which Android itself uses, are left alone.

## Run the script

```bash
# Option A: from your backup (recommended, no phone needed)
files/scripts/patch_gsi.sh \
    files/gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img \
    ~/y6-backup/system.img \
    ~/y6-patched.img

# Option B: from a phone that is still running stock EMUI (no root needed)
files/scripts/pull_stock_libs.sh ~/stock-libs
files/scripts/patch_gsi.sh files/gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img ~/stock-libs ~/y6-patched.img

# Option C: use the stock libraries already extracted in this folder (ATU-L22, EMUI 8.0.0.139 C34 only)
files/scripts/patch_gsi.sh files/gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img \
    files/prebuilt/stock-libs-ATU-L22-8.0.0.139 ~/y6-patched.img
```

**After this step, also apply the signal-bars fix: [06b](06b-fixing-signal-bars.md).** It runs on the same raw image.

### Or skip the patching: the finished image

For the **ATU-L22 on EMUI 8.0.0.139 (C34)**, the exact images that were flashed and booted are included, xz-compressed:

| Image | Contains |
|---|---|
| `v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img.xz` | **Recommended.** Both patches: the six libraries (this page) and the signal-bars fix ([06b](06b-fixing-signal-bars.md)) |
| `v5-2018-06-27-patched-libs-only-ATU-L22-8.0.0.139.img.xz` | Only the six libraries: boots, but the signal bars stay stuck at 4 |

```bash
xz -dk files/prebuilt/v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img.xz     # -> 2 GiB raw image
fastboot flash system files/prebuilt/v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img
```

Its SHA-256 (compressed file) is in [Appendix B](appendix-b-file-manifest.md). **Use it only on that exact model and firmware.** For any other ATU
variant or build, use Options A–C so the libraries match your phone.

What it does (all offline on the PC, **no root, nothing is mounted**):

1. Turns the sparse GSI into a raw ext4 image (`unsparse.py`; `simg2img` does the same).
2. Reads the six libraries (both 64- and 32-bit) out of your stock `system.img` with `debugfs`.
3. Overwrites the 12 files inside `vndk-sp-26` in the GSI image with `debugfs -w`, giving them the **same owner (root), mode `0644`
   and SELinux label (`u:object_r:system_file:s0`)** as the files they replace. The label matters: without it SELinux blocks them.
4. Runs `e2fsck -fn` on the result and **byte-compares** each file with the stock copy. It prints `OK: 12 libraries patched` or stops with an error.

Runtime: about 4 seconds. Output is a raw 2 GiB image; fastboot sends it in chunks.

On the verified phone, the script output was checked against the image that was actually flashed and booted: all 12 libraries identical.

## Check it without a phone (optional)

You can confirm the symbols are where the table above says, using binutils:

```bash
debugfs -R "dump /lib64/libhidltransport.so t.so" ~/y6-backup/system.img
readelf --dyn-syms -W t.so | grep gServiceSidMap       # defined (a section number, not UND)
debugfs -R "dump /lib64/vndk-sp-26/libhidltransport.so g.so" gsi_raw.img
readelf --dyn-syms -W g.so | grep gServiceSidMap       # prints nothing: symbol missing in the GSI copy
```

`unsparse.py` makes `gsi_raw.img` from the downloaded sparse file.

A resolver check was run before the first flash of the working image: for the final `vndk-sp-26` set, every undefined symbol of the
swapped libraries was found in the swapped set, the rest of `vndk-sp-26`, or the system's bionic/libc++/liblog/libutils/libcutils/libbase.
The only unresolved names were in RenderScript/unwind libraries that this patch does not touch.

## What can go wrong

- `this GSI has no /lib64/vndk-sp-26`: the image is not an Android 8.1/9 Treble GSI built with VNDK compatibility; use one from 05.
- `WARNING: stock libhidltransport has no gServiceSidMap`: your stock firmware is not Huawei EMUI 8.0, so this is the wrong approach for it.
- A patched image made for one firmware build should not be used on a different one: the whole point is that the libraries match the vendor partition.

Continue with [06b – Fixing the signal bars](06b-fixing-signal-bars.md).
