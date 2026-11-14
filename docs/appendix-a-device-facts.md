# Appendix A – Device facts (verified ATU-L22, stock EMUI 8.0.0.139 C34)

Serial number, IMEI and MAC addresses are deliberately left out.

## Identity

| Property | Value |
|---|---|
| `ro.product.model` | ATU-L22 |
| `ro.product.device` | HWATU-QG |
| `ro.product.board` | ATU-L02 |
| `ro.build.product` | msm8937_64 |
| `ro.board.platform` | msm8937 (Snapdragon 430) |
| `ro.build.display.id` | ATU-L22 8.0.0.139(C34) |
| `ro.build.version.emui` | EmotionUI_8.0.0 |
| Android | 8.0.0 (first API level 26) |
| `ro.treble.enabled` | true, **A-only**, not system-as-root (`/` is a `rootfs` ramdisk) |
| Kernel | 3.18.66-g4731004 |
| Memory / storage | 2048 MB LPDDR3, 16 GB eMMC (Samsung), per the kernel command line |
| Region on the verified unit | Australia (SIM on a 2G carrier, roaming on 2G while testing) |
| Stock verified-boot state | `orange` (unlocked); command line has `bootlock=unlocked`, `userlock=unlocked`, `hw_bfm_enable=1` |

## Partition table (`/dev/block/bootdevice/by-name/`)

| # | Name | # | Name | # | Name |
|---|---|---|---|---|---|
| 1 | sbl1 | 20 | cmnlib | 39 | erecovery_ramdisk |
| 2 | rpm | 21 | cmnlib64 | 40 | erecovery_vendor |
| 3 | tz | 22 | keymaster | 41 | **kernel** |
| 4 | devcfg | 23 | pad1 | 42 | **ramdisk** (Magisk lives here) |
| 5 | dsp | 24 | fsg | 43 | **recovery_ramdisk** (TWRP lives here) |
| 6 | keystore | 25 | DDR | 44 | recovery_vendor |
| 7 | frp | 26 | sec | 45 | cache (128 MB) |
| 8 | mota | 27 | devinfo | 46 | odm |
| 9 | dip | 28 | limits | 47 | persist |
| 10 | syscfg | 29 | pad2 | 48 | log |
| 11 | lksecapp | 30 | **oeminfo** | 49 | patch |
| 12 | apdp | 31 | misc | 50 | version |
| 13 | msadp | 32 | modemst1 | 51 | **vendor** (≈ 608 MiB) |
| 14 | dpo | 33 | modemst2 | 52 | product |
| 15 | fsc | 34 | rrecord | 53 | cust |
| 16 | ssd | 35 | nff | 54 | **system** (≈ 2.6 GiB) |
| 17 | bootfail_info | 36 | mcfg | 55 | userdata (≈ 10 GiB) |
| 18 | pad0 | 37 | modem | | |
| 19 | aboot | 38 | erecovery_kernel | | |

There is **no `boot` partition**. Huawei splits it into `kernel` + `ramdisk`. TWRP goes in `recovery_ramdisk` (the stock
recovery is the "eRecovery" set).

## Mounts on the stock vendor

- `/system` ← `mmcblk0p54` ext4 (read-only), `/vendor` ← `p51` ext4, `/cust` ← `p53` ext4
- `/data` ← `mmcblk0p55` **f2fs**, **file-based encryption** `fileencryption=aes-256-xts:aes-256-cts`
  (`nosuid,nodev,noatime,discard,inline_data,inline_xattr`), from the vendor's `fstab.qcom`
- The vendor has **no `ro.vndk.version`**, which is why the GSI falls back to its `vndk-sp-26` compatibility libraries ([06](../docs/06-patching-the-gsi.md))

## Fastboot behaviour

| Item | Value |
|---|---|
| `max-download-size` | `0x1ff00000` (about 512 MB; the 2 GiB image is sent in 3–4 sparse chunks) |
| `partition-size:system` | `0xa4000000` |
| `partition-size:userdata` | `0x28fdfbe00` |
| `secure` | yes |
| `product` | `QC_REFERENCE_PHONE` (not informative) |
| `flash system` | allowed (bootloader unlocked) |
| `flash recovery_ramdisk` | allowed (used for TWRP) |
| `flash misc` | **refused** (`Command not allowed`) |
| `erase cache` | **refused** |
| `erase userdata` | allowed (not recommended, see [07](07-flashing-the-gsi.md)) |
| `reboot recovery` | ignored |

## USB IDs seen

| ID | State |
|---|---|
| `12d1:107d` | Android, normal |
| `18d1:4ee7` | LineageOS, debugging on (charging + adb) |
| `18d1:d00d` | Fastboot |
| `18d1:d001` | TWRP |
| `12d1:1037` | **Huawei eRecovery screen** (neither adb nor fastboot works) |

## How to get to each mode

| Mode | How |
|---|---|
| Fastboot | Off → hold **Volume Down** → plug in USB |
| TWRP | `adb reboot recovery`, or off and unplugged → **Volume Up + Power** (keep Volume Up held after the logo) |
| eRecovery | Appears automatically after repeated failed boots |

## Running LineageOS (verified)

`ro.build.version.release 8.1.0`, `ro.lineage.version 15.1-20180626-UNOFFICIAL-`, fingerprint
`Android/treble_arm64_avN/phhgsi_arm64_a:8.1.0/OPM2.171026.006/180626:userdebug/test-keys`, `ro.debuggable=1`.
Sensors present: KXTJ3 accelerometer, EPL259x proximity + light, QTI step counter and significant-motion, SX9310 SAR.
Two cameras. Services running include the Qualcomm/Huawei audio, camera provider, Bluetooth, gnss, sensors and `rild` HALs.
