# 07 – Flashing the GSI

You need the patched image from [06](06-patching-the-gsi.md), [06b](06b-fixing-signal-bars.md) and, if you want it, [06c](06c-fixing-audiofx.md) and a stable USB connection.

## Steps

1. **Enter fastboot mode.** Power the phone off completely, hold **Volume Down**, and plug in the USB cable.
   Keep holding until the fastboot screen appears. (If it is on the eRecovery screen, choose Shutdown first.)
2. Check the PC sees it:

   ```bash
   fastboot devices          # <your-serial>  fastboot
   fastboot getvar max-download-size     # 0x1ff00000 on the verified phone
   ```
3. **Flash `system`.** The raw image is sent as sparse chunks automatically:

   ```bash
   fastboot flash system ~/y6-patched.img
   ```

   Expected: three or four "Sending sparse 'system' n/n ... OKAY / Writing 'system' ... OKAY" pairs, about 2 minutes in total.
   **Keep the phone and cable still.** If any step says FAILED, flash again.
4. **Optional but recommended: start capturing logs before the first boot**, in a second terminal
   (the phone has no `last_kmsg`, so this is the only way to see why a bootloop happens):

   ```bash
   files/scripts/capture_boot_logs.sh ~/boot-logs
   ```
5. **Reboot:**

   ```bash
   fastboot reboot
   ```

## What to expect

- The **bootloader-unlocked warning** screen, then the LineageOS boot animation, then the setup wizard.
- First boot is slower than later boots. With the signal-bars patch ([06b](06b-fixing-signal-bars.md)), Android rebuilds its compiled boot image first, which
  took about 3 minutes on the verified phone, and the phone is sluggish for a few minutes afterwards while apps are re-optimised.
- If the logs show `CANNOT LINK EXECUTABLE`, the patch was not applied or the wrong GSI was flashed. See [11](11-troubleshooting-and-restore.md).

## Things that go wrong here (all happened during testing)

### The phone lands on Huawei eRecovery: *"Data partition severely corrupted"*

This message is **usually misleading**. The kernel is started with `hw_bfm_enable=1`, Huawei's boot-failure monitor. After a couple of failed
Android boots it forces eRecovery and blames the data partition, whatever the real cause is. The real cause was always a failure in Android
itself (here the `CANNOT LINK` crash, then a different one). Check the logs first. Formatting the data partition does not fix a
failing system image.

The screen offers a "format data" button. After a *genuine* data problem it is the right choice, and it is also the easiest way to reach TWRP
(see below).

### Do not use `fastboot erase userdata` to clear data

`fastboot erase userdata` ran fine, and the next boot went to the "Data partition severely corrupted" screen. That was **most likely the
bootloop from the missing-symbol crash and not the erase itself**, but the two could not be separated, and the stock vendor does expect an
f2fs, file-encrypted `/data`. Prefer a factory reset from Android, TWRP's format, or eRecovery's format option.
`fastboot erase cache` is rejected (`Command not allowed`).

### Getting into TWRP afterwards

| Method | Result |
|---|---|
| `adb reboot recovery` (Android running, USB debugging on) | **Works.** The most reliable way |
| Phone off and unplugged, hold **Volume Up + Power**, keep Volume Up held after the logo | Works when done exactly; **did not work every time** |
| eRecovery screen → wipe data / factory reset | Reboots into TWRP (this wipes `/data`) |
| `fastboot reboot recovery` | **Ignored.** The phone just reboots normally |
| Flashing `misc` with a "boot-recovery" message | **Blocked**: `Writing 'misc' FAILED (remote: 'Command not allowed')` |

### adb does not see the phone on the eRecovery screen

The eRecovery screen has USB ID `12d1:1037`, which is not an adb or fastboot mode. Power off, then use Volume Down + USB for fastboot.

### USB drops out during a flash

The phone in testing had a damaged USB port. The flashes were done without moving it and all succeeded, and partition reads were
checksum-verified. If you have a flaky cable, use another cable or port; do not flash `system` over a connection that keeps resetting.

## After the first boot

- Go through the setup wizard, then enable **Developer options → USB debugging** again (it is reset).
- Continue with [08 – Google apps](08-gapps.md) if you want them. For vanilla LineageOS you can stop here;
  Magisk will still be present from before ([09](09-root-with-magisk.md)).
