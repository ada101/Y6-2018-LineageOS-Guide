# 02 – Bootloader unlock

Everything after this needs an **unlocked bootloader**. On this phone it is the hardest step.

## The situation

- **Huawei stopped issuing official bootloader unlock codes in mid-2018**, so you cannot get one from Huawei.
- The way people still do it is to **buy a code from a third-party service**.
- The code is generated from your phone's IMEI, so a code is only good for the phone it was made for.
- The unlock **wipes the phone completely**.

## What I did

**I bought the unlock code from [Ministry of Solutions](https://ministryofsolutions.com/huawei-bootloader-unlock-paid-service-html),
the same website whose write-up is used for the TWRP and root step ([03](03-twrp-and-root.md)). It cost about A$10, and it worked.**
I ordered on 28 August 2025 for an **ATU-L22** and had the code on 29 August.

> **Doing this yourself is at your own risk.** You are paying an online seller, giving them your phone's IMEI, and letting them remote
> into a computer your phone is plugged into. I had no problems, but this guide cannot vouch for the seller, for the service in the future,
> or for anything you pay for. Read the notes at the bottom of this page.

The original root write-up (saved in
[saved copy](../reference/original-root-guide/archive-ministryofsolutions_2026-11-15.html) ([view it rendered](https://ada101.github.io/Y6-2018-LineageOS-Guide/reference/original-root-guide/archive-ministryofsolutions_2026-11-15.html)), live at
<https://ministryofsolutions.com/huawei-y6-prime-2018-twrp-and-root-atu-l21-l22-l41-l31-l42/>)
lists the unlock as its third step: *"Unlock the bootloader of your phone (Buy bootloader code)"*, and links that text to the
service page above. The page also says the unlock wipes the phone, and says to enable **OEM unlock** in Developer options first.

The real conversation with the seller, with my IMEI, the remote-access ID and the code itself removed, is here:
**[`reference/unlock-chat-redacted.md`](../reference/unlock-chat-redacted.md)**.

## How it went, step by step

1. **Order the code** from the service page, giving your phone's model (ATU-xxx) and **IMEI** (dial `*#06#`).
   The seller replied in a chat app once they were online; time zones meant there was a delay of a few hours.
2. **A remote session on a PC.** The seller connected over a remote-desktop tool (AnyDesk) to a Windows computer my phone was
   plugged into. I used a **temporary Windows install**, created only for this one job.
   The seller asked me not to touch the mouse while their software ran, and was particular that nobody copies it.
   **That software is not included here and I did not examine it.**
3. **Put the phone into manufacturer mode** when the seller asks (this is what they told me, word for word in the chat):
   1. Connect the phone to the PC by USB.
   2. In the phone's dialer, enter **`*#*#2846579#*#*`**. A hidden menu opens (Huawei's "ProjectMenu").
   3. Tap **Background settings**.
   4. Tap **USB port settings**, then **Manufacturer mode**.
   5. Leave it there. **Do not press Close.**
4. **Wait while the seller works.** About five minutes later the seller sent a **16-character bootloader code**.
5. **Unlock the bootloader with the code.** The chat does not show this step, so what follows is Huawei's standard fastboot
   method and not something confirmed from the record:

   ```bash
   # phone powered off -> hold Volume Down while plugging in USB -> fastboot screen
   fastboot oem unlock <YOUR-16-CHARACTER-CODE>
   ```

   Enable **Developer options → OEM unlocking** first, as the original page says. The phone then wipes itself and reboots.

My own words in the chat after the code arrived and the phone was unlocked: *"holy crap it actually worked"*.

## How to confirm the bootloader is unlocked

All of these were true on the finished phone:

- A **"Your device has been unlocked and can't be trusted"** warning screen appears at every boot.
- `adb shell getprop ro.boot.verifiedbootstate` → **`orange`**
- `adb shell cat /proc/cmdline` contains **`bootlock=unlocked`** and **`userlock=unlocked`**
- `fastboot flash` works on partitions such as `system` and `recovery_ramdisk`.

## Notes and safety

- **Keep the code and your IMEI to yourself.** A code only works on its own IMEI, but it still links to you.
- Use a **throw-away Windows install** (or a spare PC) for the remote session, as I did, and do not leave anything the seller gave you on a computer you care about.
- This is a paid service run by an individual. Prices and availability can change, and sellers of codes come and go.
  If someone asks for payment up front and then vanishes, that is a scam.
- Once unlocked, the phone stays unlocked across ROM changes. You only do this once.

Continue with [03 – TWRP and root](03-twrp-and-root.md).
