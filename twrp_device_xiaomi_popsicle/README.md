# TWRP Device Tree for Xiaomi 17 Pro Max (Popsicle)

Device tree for building Team Win Recovery Project (TWRP) for the Xiaomi 17 Pro Max (Popsicle).

**Maintainer:** antocorvo3000

## Device Information

| Property     | Value              |
| ------------ | ------------------ |
| Device       | Xiaomi 17 Pro Max   |
| Codename     | Popsicle            |
| Manufacturer | Xiaomi              |
| Platform     | Qualcomm Snapdragon (sm8750_thales family) |
| Architecture | arm64               |

## Status

### Working

* Boots successfully
* Touchscreen
* Data decryption (NXP Weaver + Gatekeeper)
* ADB / Fastbootd

### Notes on the decrypt runtime

NXP StrongBox is intentionally **not** started after user decrypt on this
device: Weaver plus Gatekeeper is sufficient for the TWRP FBE decrypt path,
and starting StrongBox afterward has been linked to Android boot ending in a
locked/CE-not-unlocked state on some units. The startup gate waits for
`vendor.secure_element` and `se_omapi` to be stable, then starts only NXP
Weaver.

### Known Issues

* Flashing a ROM update can leave the running recovery unable to mount
  storage afterward, sometimes to the point that recovery cannot even
  reflash itself from within TWRP — until recovery is rebooted, after which
  everything works again. Because a same-session reboot fixes it without any
  reflash, the cause looks like a stale `dm-linear` (dynamic/super partition)
  device-mapper state rather than a wrong fstab entry: those mappings are
  created once at boot from the super partition layout at that time, and a
  ROM flash that rewrites the super partition does not get picked up by the
  already-running recovery until it reboots and recreates them. A possible
  source-level fix is forcing TWRP to re-detect/resize the super partition
  after an install completes (see `TWPartitionManager::Setup_Super_Partition`
  / `Update_Size`) instead of only at startup. Not specific to this device —
  any of the four could hit it after a flash that changes the dynamic
  partition layout.

## Notes

The decrypt path in `system/vold/Decrypt.cpp` includes a fix for an AES-256-GCM
authentication-tag handling bug in the synthetic-password unwrap path
(`Decrypt_User_Synth_Pass`): the original code split ciphertext/tag incorrectly,
used an uninitialized tag buffer, and never checked the OpenSSL EVP return
codes. See `patches/0001-vold-fix-synthetic-password-gcm.patch`.

## Credits

* Team Win Recovery Project (TWRP)
* Android Open Source Project (AOSP)
* The Android aftermarket development community
