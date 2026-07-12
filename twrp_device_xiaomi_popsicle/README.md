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

* After flashing a ROM update newer than the recovery's own donor firmware
  version, the post-install partition refresh can log EROFS/ext4 fstab
  mismatches for the dynamic super partitions, sometimes leaving storage
  unmounted and recovery unable to reflash itself until a reboot. Use a
  recovery built against a matching or newer stock recovery donor and an
  EROFS-only fstab for the dynamic partitions to avoid this. The underlying
  cause (stale donor recovery vs. a newer flashed ROM) is not specific to this
  device — any of the four devices could hit it if their recovery donor falls
  behind the ROM being flashed.

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
