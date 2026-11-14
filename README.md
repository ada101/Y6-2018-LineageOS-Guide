# LineageOS 15.1 + Google apps + Magisk on the Huawei Y6 2018 (ATU-L21 / L22 / L31 / L42)

A complete, tested walk-through for putting **LineageOS 15.1 (Android 8.1)** on a Huawei Y6 2018
(also sold as Y6 Prime 2018), with Google apps and Magisk root, starting from a stock phone.

There is **no official LineageOS for this phone**. It works by flashing a **Treble GSI**
(Generic System Image) on top of Huawei's stock vendor partition. That normally fails on this
phone in a specific way. The missing pieces are two small patches, which this guide documents: a **six-library patch** so the
vendor services start ([06](docs/06-patching-the-gsi.md)), and a **signal-strength patch** so the bars show the real signal ([06b](docs/06b-fixing-signal-bars.md)).

> **Tested on:** ATU-L22, stock EMUI 8.0.0.139 (C34), Australia (SIM on a 2G carrier), November 2026.
> Other ATU variants should behave the same (the phh Treble wiki lists L21, L22 and L42 as tested)
> but this guide was only verified end to end on one L22.
>
> **You do all of this at your own risk.** It wipes the phone. A mistake can leave it unbootable.
> Do the backup in [04](docs/04-backup.md) first.

## What the finished phone looks like

| | Result |
|---|---|
| OS | LineageOS 15.1, Android 8.1.0, phh GSI "v5", build 2018-06-26/27 (`ro.lineage.version 15.1-20180626-UNOFFICIAL-`) |
| Google apps | OpenGApps **nano** 8.1, 2022-05-03 |
| Root | Magisk (daemon 29.0) in the boot ramdisk |
| Calls, SMS, mobile data | Work |
| Wi-Fi, Bluetooth, audio | Work |
| Cameras | Both open; torch works |
| Sensors | All six present sensors work |
| Signal bars | **Correct**: with the patch in [06b](docs/06b-fixing-signal-bars.md) they matched a second phone's readings side by side through a whole call. Without it they are stuck at 4 |
| Fingerprint | n/a (this model has no reader) |
| Not tested | GPS fix outdoors, camera photo quality, VoLTE, NFC, FM radio |

## The guide, in order

| # | Document | What it covers |
|---|---|---|
| 01 | [Before you start](docs/01-before-you-start.md) | Identify your phone, what you need, risks |
| 02 | [Bootloader unlock](docs/02-bootloader-unlock.md) | **Required, and Huawei no longer provides codes.** I bought a code from Ministry of Solutions (about A$10) and it worked. Own risk. Includes the redacted chat |
| 03 | [TWRP and root (the original method)](docs/03-twrp-and-root.md) | Flashing TWRP, rooting with Magisk, from the [Ministry of Solutions](https://ministryofsolutions.com/huawei-y6-prime-2018-twrp-and-root-atu-l21-l22-l41-l31-l42/) write-up |
| 04 | [Back up your phone](docs/04-backup.md) | Verified copy of every irreplaceable partition. **Do not skip** |
| 05 | [Choosing a GSI](docs/05-choosing-a-gsi.md) | Which images work, which don't, and why |
| 06 | [Patching the GSI](docs/06-patching-the-gsi.md) | **The key step.** Six Huawei libraries swapped into the image |
| 06b | [Fixing the signal bars](docs/06b-fixing-signal-bars.md) | **Recommended.** The modem reports signal in the wrong units, so bars are stuck at full. A small framework patch fixes it |
| 07 | [Flashing the GSI](docs/07-flashing-the-gsi.md) | Fastboot flashing, first boot, the eRecovery screen |
| 08 | [Google apps](docs/08-gapps.md) | OpenGApps nano via TWRP, and the factory reset it needs |
| 09 | [Root with Magisk](docs/09-root-with-magisk.md) | Keeping and checking root; what not to touch |
| 10 | [Known issues](docs/10-known-issues.md) | Signal bars, certification, things not tested |
| 11 | [Troubleshooting and going back to stock](docs/11-troubleshooting-and-restore.md) | Symptom → cause → fix, plus how to read the boot logs |
| A | [Device facts](docs/appendix-a-device-facts.md) | Partition table, fastboot behaviour, build properties |
| B | [File manifest](docs/appendix-b-file-manifest.md) | Every file in this folder, what it is, its SHA-256, where it came from |

## Get the large files first

Four files are over GitHub's 100 MB limit, so they are **not in the git repository**. They are attached to the
[v1.0 release](https://github.com/ada101/Y6-2018-LineageOS-Guide/releases/tag/v1.0) (the two GSIs and the two prebuilt images).
The **GApps zip is not hosted here**: download it from SourceForge ([doc 08](docs/08-gapps.md)).
After cloning, run:

```bash
files/scripts/fetch_large_files.sh            # all four, SHA-256 checked   (or: gsi | prebuilt)
```

They land in the folders the guide uses (`files/gsi/`, `files/prebuilt/`), so every command below works unchanged.

## Fast path (phone already unlocked, TWRP and Magisk installed)

If your phone is already unlocked and rooted, this is the whole job. Details are in the numbered documents.

```bash
# 1. Back up (rooted phone, cable plugged in, Magisk "Shell" granted)       -> doc 04
files/scripts/backup_partitions.sh ~/y6-backup

# 2. Patch the GSI with your phone's own stock libraries                    -> doc 06
files/scripts/patch_gsi.sh files/gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img \
                           ~/y6-backup/system.img  ~/y6-patched.img

# 2b. Fix the signal bars (needs java + apktool)                            -> doc 06b
APKTOOL=/path/to/apktool.jar files/scripts/patch_signal_strength.sh ~/y6-patched.img

#    (ATU-L22 on EMUI 8.0.0.139 only: skip 1 and 2 and use the ready-made image
#     files/prebuilt/v5-2018-06-27-patched-libs-and-signal-ATU-L22-8.0.0.139.img.xz, see docs 06 and 06b)

# 3. Flash it (phone off, hold Volume Down, plug in USB)                    -> doc 07
fastboot flash system ~/y6-patched.img
fastboot reboot            # first boot; if it lands on eRecovery, see doc 07

# 4. GApps through TWRP, then factory reset from Settings                   -> doc 08
adb reboot recovery
# (download the zip first, see doc 08)
adb push files/gapps/gapps-nano.zip /tmp/ && adb shell twrp install /tmp/gapps-nano.zip
adb reboot                 # Google services will crash-loop: Settings > System > Reset > Erase all data
```

## What is in this folder

```
README.md                 this page
docs/                     the guide, one document per stage (01-11 + two appendices)
files/
  scripts/                backup, unsparse, patch_gsi (the important one), patch_signal_strength, pull_stock_libs, capture_boot_logs, fetch_large_files
  gsi/                    the GSI that worked (phh LineageOS 15.1 v5) + fallback v4 (untested)
  prebuilt/               ready-made patched images + the six stock libraries (ATU-L22, EMUI 8.0.0.139 only)
  signal-fix/             the signal-bars patch: diff of the change + the already-patched framework.jar
  gapps/                  official md5 for OpenGApps nano 8.1 20220503 (the zip itself comes from SourceForge, doc 08)
  recovery/               TWRPATU.img - TWRP for the ATU series (verified identical to the one in use)
  magisk/                 Magisk-v20.4.zip - the version used by the original root method
  windows-tools/          adb.exe / fastboot.exe / MAF32.exe from the original root kit
  original-kit/           HUAWEIATUROOT.zip - the original, unmodified root kit archive (MD5 matches the original download page)
  SHA256SUMS              checksums for everything in files/   (cd files && sha256sum -c SHA256SUMS)
reference/
  original-root-guide/    single-file archive of the Ministry of Solutions root page ([view rendered](https://ada101.github.io/Y6-2018-LineageOS-Guide/reference/original-root-guide/archive-ministryofsolutions_2026-11-15.html))
  unlock-chat-redacted.md the real chat with the unlock-code seller (IMEI, code and remote ID removed)
  ministryofsolutions-HUAWEIATUROOT-download-page.jpg   the dead download page for the root kit
  boot-log-excerpts/      the key error lines from each boot attempt (works / fails and why)
```

Not included: the original owner's own partition backup, which holds that phone's IMEI and serial. You make your own in [04](docs/04-backup.md).

## License

The guide text and the scripts written for it are released under the [Unlicense](LICENSE) (public domain).
This covers **only that original work**. The other files keep their own owners and licences: the phh GSIs and LineageOS (Apache-2.0 and others),
TWRP and Magisk (GPL), Huawei's stock libraries, the Ministry of Solutions kit and page, and OpenGApps (see its own terms).

## Credits

- **phh (Pierre-Hugues Husson)**: Treble GSIs, the Y6 2018 [Treble wiki page](https://github.com/phhusson/treble_experimentations/wiki/Huawei-Y6-and-Y6-Prime-(2018)) (archived Jan 2025)
- **Ministry of Solutions**: the original unlock/TWRP/root write-up. TWRP build credit on that page: **xBrownieCodez**
- **LineageOS** developers; **OpenGApps**; **topjohnwu** (Magisk)
- Other GSIs tried and documented as failures: AndyYan (LineageOS 16.0), iamsaalim (LineageOS 15.1, 2019)
