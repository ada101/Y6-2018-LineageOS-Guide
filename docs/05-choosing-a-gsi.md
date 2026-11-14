# 05 – Choosing a GSI

## What the phone can take

| Property | Value | What it means |
|---|---|---|
| CPU ABI | `arm64-v8a` | Need an **arm64** image (not `arm`, not `a64`) |
| Partition layout | **A-only** (no A/B slots) | Need an **A-only** image (`aonly` / `avN`, **not** `ab` / `bvN`) |
| System-as-root | No (`/` is a ramdisk, `/system` mounted separately) | "non-SaR" images |
| Treble | Enabled, vendor partition 8.0 | GSI + Huawei's own vendor. **Needs the patch in [06](06-patching-the-gsi.md)** |
| `system` partition | 0xA4000000 bytes (2.6 GiB) | A 2 GB GSI fits |

## Naming decoder

Common naming used by GSI builders:

| Piece | Meaning |
|---|---|
| `arm64` | 64-bit ARM, correct |
| `a` / `aonly` | A-only, correct |
| `ab` / `b` | A/B, **wrong for this phone** |
| `v` / `vanilla` | no Google apps, correct as a first install |
| `g` / `gapps` | includes Google apps |
| `N` / `nosu` | no built-in superuser (use Magisk) |
| `S` / `su` | built-in superuser (conflicts with Magisk) |

## The one that works

**phh LineageOS 15.1 "v5"** (2018-06-27 post, build `15.1-20180626`):

- File in this folder: [`files/gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img`](../files/gsi/2018-06-27-system-arm64-aonly-vanilla-nosu.img)
  (1,313,128,716 bytes, Android sparse image, expands to 2 GiB)
- Original name: `system-arm64-aonly-vanilla-nosu.img`
- Original download (from phh's release post on XDA, *"[Lineage] Unofficial 2018-06-27 Phh-Treble"*):
  `https://github.com/phhusson/treble_experimentations/releases/download/lineage-v21/system-arm64-aonly-vanilla-nosu.img`
- Result **with the patch from 06**: boots, runs, everything in the table in the README works.
- It has **not** been tested *without* the patch. It lacks the Huawei symbols (checked: its `vndk-sp-26` libraries do not
  define them), so the same vendor-service crash would be expected.

A fallback also in this folder, **untested**: [`files/gsi/fallback/2018-05-19-system-arm64-aonly.img`](../files/gsi/fallback/2018-05-19-system-arm64-aonly.img)
(phh LineageOS 15.1 "v4", `15.1-20180519`, original URL `.../releases/download/lineage-v4/system-arm64-aonly.img`).
It also lacks the symbols (checked), so it needs the same patch.

## What did not work, and why

All three *failed the same way before any patch*, then diverged. The key lines from each boot attempt are in
[`reference/boot-log-excerpts/`](../reference/boot-log-excerpts/).

| # | Image | What happened |
|---|---|---|
| 1 | **LineageOS 16.0 (Android 9)**, AndyYan, 2019-10-17, `lineage-16.0-20191017-UNOFFICIAL-treble_arm64_avN.img.xz` (SourceForge `andyyan-gsi/lineage-16.x`) | Black screen + bootloop. Dozens of vendor services crashed on start with `CANNOT LINK EXECUTABLE ... cannot locate symbol "_ZN7android8hardware7details14gServiceSidMapE"`. |
| 2 | **LineageOS 15.1**, iamsaalim, 2019-07-28, `lineage-15.1-arm64-aonly.img` (SourceForge `lineage-15-1-gsi`) | Same `gServiceSidMap` error at first. **After swapping only two libraries** (`libhidltransport`, `libhidlbase`) the next error appeared: `cannot locate symbol "_ZN7android8hardware9BHwBinder16setRequestingSidEb"`. **After swapping all six libraries** the vendor services started, but then **the zygote crashed** with `SIGBUS` inside `android::AssetManager::addSystemOverlays`, so still a bootloop. Not diagnosed beyond that. |
| 3 | **phh LineageOS 15.1 v5**, 2018-06-27 | **Worked** with the six-library patch. |

The phh wiki page for this phone ([link](https://github.com/phhusson/treble_experimentations/wiki/Huawei-Y6-and-Y6-Prime-(2018)))
says Android 8.x GSIs based on Phh-AOSP **v25 or later** bootloop on this phone, Android 9 GSIs based on **v127 or earlier** bootloop
unless the vendor is patched, and Android 10+ needs extra steps and breaks with Magisk. Image 2 is from 2019, which probably explains
its zygote crash, but that is an inference.

**Practical rule:** use a build **from 2018**. Newer images (2019 and later) did not boot here.

## Other candidates, not tried

- **phh AOSP 8.1 v22**, a plain-AOSP (not LineageOS) image from the same era. A third-party guide lists it as
  `system-arm64-aonly-vanilla-nosu.img.xz`. If LineageOS v5 will not boot for you, this is the next thing to try. The wiki also says
  Oreo GSIs give the best camera and tethering on this phone.
- **v3 (2018-04-05)** of the same LineageOS series, hosted on AndroidFileHost. Older, never tried.

Continue with [06 – Patching the GSI](06-patching-the-gsi.md).
