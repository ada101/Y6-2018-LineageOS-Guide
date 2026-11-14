# Appendix B – File manifest

Paths are relative to this guide's folder. Checksums are SHA-256 and are also in [`files/SHA256SUMS`](../files/SHA256SUMS)
(check them with `cd files && sha256sum -c SHA256SUMS`).

## `files/`

| File | Size (bytes) | What it is | Where it came from | SHA-256 |
|---|---|---|---|---|
| `gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img` | 1,313,128,716 | **The GSI that works**: phh LineageOS 15.1 v5, arm64 A-only, vanilla, no su. Android sparse image. | phh's XDA post → `github.com/phhusson/treble_experimentations/releases/download/lineage-v21/system-arm64-aonly-vanilla-nosu.img`. Renamed with a date prefix | `66992887a5c083e87a612f721842d6e85c01682aa6ee0d3be72b9b998e64104c` |
| `gsi/fallback/2018-05-19-system-arm64-aonly.img` | 1,307,566,324 | phh LineageOS 15.1 v4. **Untested** fallback | same post → `.../releases/download/lineage-v4/system-arm64-aonly.img`. Renamed | `6b05046d024902bf8ebcdbea91d6e70113438eafe4fad432901ef75a8755ec08` |
| `gapps/gapps-nano.zip` (**not in the repo**: download from SourceForge, check the sizes and sums here) | 271,606,054 | OpenGApps arm64 8.1 nano, 2022-05-03 | SourceForge `opengapps/arm64/20220503/open_gapps-arm64-8.1-nano-20220503.zip`. Renamed. MD5 verified against the official `.md5` | `bc13b3487b6aaae8fbf7350d0aa955e012353cd268fb02c13a59158316398f49` |
| `gapps/gapps-nano.zip.md5` | 73 | Official MD5 file (`25c697bf89be72fb8b75075004544fda`) | SourceForge | `ac9c81baac25e0327a1b74775d358a5bd84ab52dd53edfaef9d2f3db5a3dc899` |
| `original-kit/HUAWEIATUROOT.zip` | 16,295,651 | **The original root-kit archive, unmodified** (AES-256 zip, password `ministryofsolutions.com`). Its 7 files are byte-identical to the extracted copies listed below. MD5 `ad1f8a1786eccecd9d2f1579e870bdf7` matches the original download page | Ministry of Solutions' original `HUAWEIATUROOT.zip`, obtained from the unlock-code seller ([03](03-twrp-and-root.md)) | `788da18e4fbc9e231ec9f0d38624fa251ace7273e3f5043b6cc114eebbf39d69` |
| `recovery/TWRPATU.img` | 9,363,456 | TWRP 3.3.1 for the ATU series. Byte-identical to the start of the working phone's `recovery_ramdisk` | The "HUAWEIATUROOT" kit referenced by the Ministry of Solutions page | `7dc6a8fd82f4def29c3bb8e56d8fcf0828516bbf51c80e3f6d5a5613d4f4d0e1` |
| `magisk/Magisk-v20.4.zip` | 5,942,417 | Magisk v20.4, the version used by the original method | same kit | `5795228296ab3e84cda196e9d526c9b8556dcbf5119866e0d712940ceed1f422` |
| `windows-tools/adb.exe` | 1,474,048 | ADB for Windows (2016) | same kit | `e76f27aef48e9bf8bb876df6ce42289b7784692ef6de49f07c26f11de335c861` |
| `windows-tools/AdbWinApi.dll` | 97,792 | ADB Windows driver DLL | same kit | `d60103a5e99bc9888f786ee916f5d6e45493c3247972cb053833803de7e95cf9` |
| `windows-tools/AdbWinUsbApi.dll` | 62,976 | ADB Windows driver DLL | same kit | `25207c506d29c4e8dceb61b4bd50e8669ba26012988a43fbf26a890b1e60fc97` |
| `windows-tools/fastboot.exe` | 802,304 | fastboot for Windows | same kit | `8cb2db90842d85878a36f2b6e32389b25d18e5bf1df1e56646f4df231e7f5eb3` |
| `windows-tools/MAF32.exe` | 29,882 | Windows command-prompt launcher with adb/fastboot on the path (the original page's "open MAF32.exe") | same kit | `cfa3c01e448c0375325d4f6cb8d24e7c22be94aa87909eeeadcf66b2558eff9b` |
| `scripts/backup_partitions.sh` | | Verified partition backup over adb | written for this guide | see `SHA256SUMS` |
| `scripts/unsparse.py` | | Android sparse → raw converter | written for this guide | |
| `scripts/pull_stock_libs.sh` | | Copy the six stock libraries off a stock phone | written for this guide | |
| `scripts/patch_gsi.sh` | | **Patch a GSI with the six libraries**: tested; output identical to the booted image | written for this guide | |
| `scripts/patch_signal_strength.sh` | | **Fix the signal bars**: patches `SignalStrength` in the GSI's framework and removes the stale boot images. Tested end to end; result has the identical patched dex | written for this guide | see `SHA256SUMS` |
| `scripts/capture_boot_logs.sh` | | Capture logcat while the phone bootloops | written for this guide | |
| `prebuilt/v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img.xz` | 504,467,264 | **Recommended: the exact image now running on the verified phone**: six-library patch + signal-bars patch, boot images removed. xz of a 2 GiB raw ext4 image; decompresses to SHA-256 `7507dded55c3f4bbb7b836d44cb5cb59bc0c120b7bb1590ea17520cb7c18bbb0`. ATU-L22, EMUI 8.0.0.139 (C34) only | `patch_gsi.sh` then `patch_signal_strength.sh` on the v5 GSI | `c3fd479844f1cd3c1933737aa87d5c6e44b1da936112bf8fbb377dc24839316d` |
| `prebuilt/v5-2018-06-27-patched-libs-only-ATU-L22-8.0.0.139.img.xz` | 504,467,628 | The first image that booted: six-library patch only (signal bars stuck at 4). Same firmware restriction | `patch_gsi.sh` | `a4345fb9c782a1b9d3e92c94eb3674885e2c89e4b4ca49abf0a52086c48e2636` |
| `prebuilt/stock-libs-ATU-L22-8.0.0.139/lib64/*.so` and `lib/*.so` | | The six stock Huawei HIDL libraries (`libhwbinder`, `libhidlbase`, `libhidltransport`, `libhidlmemory`, `android.hidl.base@1.0`, `android.hidl.memory@1.0`) in 64- and 32-bit | Extracted from that phone's own stock `system.img` | see `SHA256SUMS` |
| `signal-fix/SignalStrength-getGsmSignalStrength.diff` | | The exact smali change (unified diff) | made for this guide | `e0e554f188db6b7245e23aabcba36ad60f52c12d8e02cd0bfbada8759867a82f` |
| `signal-fix/framework-patched-phh-v5-2018-06-27.jar` | 7,688,201 | The phh v5 `framework.jar` with only `classes2.dex` replaced by the patched one. For the phh v5 GSI only | `patch_signal_strength.sh` | `28a5803744cc11a15b054bf37971834ccf31080b7e58c8c1052b5908b8ddb509` |

The Windows tools and the TWRP and Magisk files come from the third-party kit above and are archived as received (both extracted and inside the original zip).
`adb.exe`/`fastboot.exe` are old (2016); on Linux and recent Windows use current Android platform-tools instead. None is Huawei proprietary firmware. Licences
were **not** checked for each file (TWRP and Magisk are open source; the origin of `MAF32.exe` is not documented), so check before redistributing anything publicly.

## `reference/`

| Path | What it is |
|---|---|
| `original-root-guide/archive-ministryofsolutions_2026-11-15.html` | Single-file SingleFile archive (saved 15 Nov 2026), view it rendered at https://ada101.github.io/Y6-2018-LineageOS-Guide/reference/original-root-guide/archive-ministryofsolutions_2026-11-15.html. Saved copy of the Ministry of Solutions write-up *"Huawei Y6 Prime 2018 TWRP and Root (ATU-L21, L22, L41, L31, L42)"*, published 28 Oct 2020, updated 22 Sep 2022. Live URL: <https://ministryofsolutions.com/huawei-y6-prime-2018-twrp-and-root-atu-l21-l22-l41-l31-l42/> |
| `unlock-chat-redacted.md` | The real chat (28–29 Aug 2025) with the unlock-code seller, with the IMEI, remote-access ID, unlock code and personal names removed |
| `ministryofsolutions-HUAWEIATUROOT-download-page.jpg` | Screenshot of the (dead) download page for `HUAWEIATUROOT.zip`: 15.5 MB, uploaded 28 Oct 2020, MD5 `ad1f8a1786eccecd9d2f1579e870bdf7` |
| `boot-log-excerpts/` | One file per boot attempt (1–5) with the key `logcat` lines: the `CANNOT LINK` errors, fatal signals, the zygote crash backtrace, and the working boot. Timestamps stripped |

## Not in this folder

| Item | Why |
|---|---|
| The original phone's **partition backup** (19 images, 4.0 GB) | It contains that phone's IMEI, serial and calibration. You make your own with [`backup_partitions.sh`](04-backup.md) |
| The two GSIs that **did not boot** (LineageOS 16.0 from 2019-10-17; LineageOS 15.1 from 2019-07-28) | Useless to others. Their download sources are given in [05](05-choosing-a-gsi.md) |
| The full raw `logcat` dumps | They contain the phone's serial number and network names. The excerpts above keep the useful lines |
