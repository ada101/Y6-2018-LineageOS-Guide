# 06c – Fixing AudioFX (the equalizer)

**Optional, and quick.** Do it with the other patches, before flashing ([07](07-flashing-the-gsi.md)), so you flash once.

## The problem

LineageOS 15.1's equalizer app (**AudioFX**) has a long-standing bug that shows up on this phone: after a reboot the EQ does nothing, it starts working when you
open AudioFX, and it **stops again as soon as you move any slider**.

It was diagnosed and fixed separately, with a full write-up, a source patch and the evidence, in its own repository:

**<https://github.com/ada101/lineageos-audiofx-eq-fix/tree/main/15.1-device-profile-bug>**

The fix is one line in AudioFX's `SessionManager`: the service now reads the settings of the same output device the UI writes to.

## Apply it (one command, before flashing)

The patched app from that repository is included here, and a script drops it into the image. It runs on the same raw image as the other patches, in any order:

```bash
files/scripts/patch_audiofx.sh ~/y6-patched.img
```

No Magisk and no root are needed; nothing is mounted. It takes a second. The script:

1. checks that the AudioFX in the image is **exactly** the stock build the patch was made from (phh v5, 2018-06-27) and **refuses otherwise**,
2. replaces `/priv-app/AudioFX/AudioFX.apk` with the patched one (same owner, mode and SELinux label),
3. checks the filesystem and verifies the file byte for byte.

**Using the ready-made image from [06](06-patching-the-gsi.md)?** It does not include this fix, but the script works on it: decompress it first
(`xz -dk files/prebuilt/v5-...-signal-ATU-L22-8.0.0.139.img.xz`) and run the script on the resulting `.img`.

The full fast path is then: `patch_gsi.sh` → `patch_signal_strength.sh` → `patch_audiofx.sh` → flash → GApps ([08](08-gapps.md)).

## Check it worked

Set a very obvious EQ (one band +12 dB, the rest −12 dB), then:

1. Reboot, start music, **do not** open AudioFX: the effect should already be audible.
2. Open AudioFX and move sliders (small and large): the sound should follow.
3. Change presets and use the on/off switch: both should work.

## Already flashed? Two other routes

- **Magisk module** (the route the original repository recommends). **Careful:** the phh wiki reports that Magisk modules can bootloop this phone
  ([09](09-root-with-magisk.md)), so this guide does not use them. If you try it anyway, follow that repository's
  [`docs/INSTALL.md`](https://github.com/ada101/lineageos-audiofx-eq-fix/blob/main/15.1-device-profile-bug/docs/INSTALL.md) and keep the way back open: remove the module and reboot.
- **Reflash** `system` with this patch included. That wipes GApps (`/system`), so flash GApps again and factory-reset ([08](08-gapps.md)).

## What was verified, and what was not

| | |
|---|---|
| **Verified** (by the fix's author, on this phone) | The patched AudioFX, installed as a Magisk module, fixes all the symptoms |
| **Verified** (offline) | `patch_audiofx.sh` on the phh v5 image: the stock APK matches the expected checksum, the patched APK has the same signing certificate as the stock one, and the filesystem check is clean |
| **Not tested** | A full image built with this script, flashed, and booted. It places the same APK at the same path the module overlays, so it should behave the same |
| Unknown | The exact reason the service and the UI disagree about the output device on this phone (see the original repository) |

The patched APK is the work of [`ada101/lineageos-audiofx-eq-fix`](https://github.com/ada101/lineageos-audiofx-eq-fix) and AudioFX is Apache-2.0 (LineageOS project).
The APK's SHA-256 is in [Appendix B](appendix-b-file-manifest.md).
