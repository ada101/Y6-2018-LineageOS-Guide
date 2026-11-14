# 09 – Root with Magisk

## State on the finished phone

| Item | Value |
|---|---|
| Magisk daemon | **29.0 (29000)**, shown by `su -c "magisk -v"` → `29.0:MAGISK:R` |
| Magisk app | 29.0 (`com.topjohnwu.magisk`) |
| Where it lives | Boot **ramdisk** (the Magisk home screen shows *Ramdisk: Yes*, *Zygisk: No*) |
| SELinux | Enforcing |

Magisk was installed years earlier with the method in [03](03-twrp-and-root.md) and later updated. The GSI flash only replaces `system`;
the `kernel` and `ramdisk` partitions, where Magisk lives, are untouched, so **root survived the whole procedure**, including the factory reset
in [08](08-gapps.md). Nothing had to be re-rooted.

## Check that root works

From the PC:

```bash
adb shell su -c id
# uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

Magisk only gives root to apps (and the adb shell) that you have allowed.

### If `su` over adb says `Permission denied`

This took a while to find during testing. The causes were, in order:

1. **A stored "deny" rule for Shell.** Magisk's log said `su: request rejected (2000)` (2000 is the adb shell's uid), the phone showed a toast
   *"Shell was denied superuser access"*, and **no prompt appeared**. An earlier prompt that was missed or timed out had left a deny rule behind.
   A stored rule suppresses the prompt entirely, **and the *Automatic Response* setting is ignored when a rule exists.**
   **Fix:** Magisk app → **Superuser** tab → find **Shell** → turn its toggle **on** (or delete the rule so Magisk asks again).
2. **The prompt was missed.** The default request timeout is 10 seconds and *Tapjacking Protection* ignores taps while anything overlays the
   prompt. Raise it: Magisk → Settings → **Request Timeout → 60 seconds**, and make sure nothing else is on screen.
3. Check **Settings → Superuser Access** is **Apps and ADB** (it already was).

You can see Magisk's decisions in `adb logcat -d | grep Magisk`.

Tip: if you set **Automatic Response → Grant** to debug, **set it back to Prompt** afterwards.

## What not to touch (important on this phone)

| Do not | Why |
|---|---|
| Use the Magisk app's **Install** button (the *Install* card, or *Direct Install*) | It patches "the boot image", but this phone has **no standard `boot` partition**: Huawei splits it into `kernel`, `ramdisk`, `recovery_ramdisk`. The app does not know that, so a write could go to the wrong place. This is the one step in this guide that could genuinely brick the phone |
| **Update the Magisk app** (it offered 30.6 while the daemon was 29.0) | The app and the ramdisk version should match. A mismatch triggers *"Requires additional setup"*, a re-install into the boot image and a reboot |
| Enable **Zygisk** or install **Magisk modules** | The phh Y6 wiki states that Magisk modules cause a bootloop on this phone, and Zygisk is the module framework. Root works without it |
| Flash a **built-in-su** GSI (`...-su.img`) | It collides with Magisk's `su`. Use `...-nosu` images |

## "Requires additional setup"

After a factory reset the Magisk app said it needed additional setup, did it, and **rebooted the phone**. During that reboot adb disconnects.
This is Magisk finishing its own first-run set-up; it is not an error. Wait for the phone to come back.

## Developer options → "Root access"

A separate setting, with the options *Disabled / ADB only*, is LineageOS's own built-in `adb root`, available because this GSI is a
**userdebug** build. It is independent of Magisk and does not affect root for apps. It was left **Disabled**.

## Which Magisk if you are rooting from scratch?

`files/magisk/Magisk-v20.4.zip` is the version used by the original method. Whether a *fresh* v20.4 install works with this specific
GSI was **not tested**: the verified phone had Magisk 29 in its ramdisk before the GSI went on. If you root fresh and it misbehaves,
prefer to keep what the original method uses rather than experiment with the Install button.

Continue with [10 – Known issues](10-known-issues.md).
