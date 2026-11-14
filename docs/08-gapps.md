# 08 – Google apps (OpenGApps nano)

## The file

| | |
|---|---|
| File | `open_gapps-arm64-8.1-nano-20220503.zip`. **Not included in this repository**: download it from SourceForge (below) and save it as `files/gapps/gapps-nano.zip` |
| Size | 271,606,054 bytes (271.6 MB) |
| MD5 (official) | `25c697bf89be72fb8b75075004544fda`, see [`gapps-nano.zip.md5`](../files/gapps/gapps-nano.zip.md5) |
| Platform / Android / variant | `arm64` / `8.1` / `nano` |
| Download | <https://sourceforge.net/projects/opengapps/files/arm64/20220503/> (pick `open_gapps-arm64-8.1-nano-20220503.zip`) |

It is the last OpenGApps build for Android 8.1. **GitHub no longer hosts the OpenGApps files** (the releases there are empty), only SourceForge does.
`/system` has about 1.1 GB free after the GSI, and nano needs roughly 300–400 MB.

## Order matters

Flash GApps **last**, after the final `system` flash (patched libraries and signal fix, [06](06-patching-the-gsi.md)/[06b](06b-fixing-signal-bars.md)).
Flashing a new `system` image overwrites `/system`, **including GApps**. This happened in testing: the signal fix was flashed after GApps, Play Services
vanished, and GApps had to be flashed again, which needed a second factory reset (the same data-folder failure as below). Also, any change you
make to `/system` (for example adding an app there) is lost by a re-flash.

## Install

Needs TWRP and a working USB-debugging connection to Android.

```bash
md5sum files/gapps/gapps-nano.zip            # must be 25c697bf89be72fb8b75075004544fda

adb reboot recovery                          # into TWRP (3.3.1)
adb push files/gapps/gapps-nano.zip /tmp/gapps-nano.zip     # NOT /sdcard, see below
adb shell md5sum /tmp/gapps-nano.zip         # same value as above
adb shell twrp install /tmp/gapps-nano.zip
adb reboot
```

The installer prints `Installation complete!`.

### Why `/tmp`?

After the first Android boot, `/data` is file-based-encrypted and TWRP 3.3.1 cannot unlock it. Pushing to `/sdcard` or `/data/local/tmp` fails
(`Required key not available`) or silently writes where nothing can read it. `/tmp` is the recovery's RAM disk; with 1.8 GB RAM there is
room for the 271 MB zip and the installer's extraction (about 1.4 GB free was observed).

## Then factory-reset (this is required in the tested order)

When GApps was flashed **after Android had already booted once**, the Google services crash-looped on the next boot:

- `Google Services Framework keeps stopping` popups on every screen, and **popups from every Google app**.
- The popups got in the way of the screen while testing root. (They were suspected of hiding Magisk's superuser prompt;
  the actual reason root was refused over adb turned out to be something else, see [09](09-root-with-magisk.md).)
- Logcat: `Failed to ensure /data/user/0/com.google.android.gsf/databases: mkdir failed: ENOENT` then
  `SQLiteCantOpenDatabaseException ... gservices.db`. Android registered the package but its private data folder was never created.
- **Did not fix it:** `pm clear` on gsf/gms/vending, and a reboot.
- **Did fix it:** **Settings → System → Reset options → Erase all data (factory reset).** It reboots via TWRP, wipes `/data`, and after
  the setup wizard the Google services were stable (no crashes in the log).

So do the reset straight away, after flashing GApps. Nothing is lost that was not already going to be wiped.

**Do not use `twrp wipe data` for this reset.** It deliberately keeps `/data/misc` and `/data/unencrypted` (the encryption keys). Used instead of the
Settings reset, it left a broken user key behind (`/data/misc/vold/user_keys/ce/0` without its `keymaster_key_blob`): `unlock_user_key` failed, no app
data folders were created, and the setup wizard hung on "Just a sec...". What fixed it: in TWRP, `adb shell 'rm -rf /data/* /data/.[a-zA-Z]*'`
(this erases everything, including `/data/media`), then reboot. `twrp format data` does not exist in 3.3.1.

**Untested alternative:** flashing GApps *before the very first Android boot* (so no first-boot data exists) might avoid the reset. This
was not tried, because the phone had already booted once when GApps was added.

## After the reset

- The Magisk root **survives** (the reset only wipes `/data`; Magisk is in the ramdisk). On the first boot afterwards, the Magisk app says
  *"Requires additional setup"* and **reboots the phone once**. That is normal.
- You will need to re-enable **USB debugging**.
- The setup wizard completed and the Google services stayed stable. Sign-in and Play Store use were not tested in detail. The phone is an **uncertified GSI**, so the Play Store may report the device as uncertified. See [10](10-known-issues.md).

Continue with [09 – Root with Magisk](09-root-with-magisk.md).
