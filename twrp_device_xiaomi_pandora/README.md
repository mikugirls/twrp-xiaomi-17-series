# TWRP Device Tree for Xiaomi 17 Pro (Pandora)

Device tree for building Team Win Recovery Project (TWRP) for the Xiaomi 17 Pro (Pandora).

**Maintainer:** antocorvo3000

## Device Information

| Property     | Value           |
| ------------ | --------------- |
| Device       | Xiaomi 17 Pro   |
| Codename     | Pandora         |
| Manufacturer | Xiaomi          |
| Platform     | Qualcomm Snapdragon (sm8750_thales family) |
| Architecture | arm64           |

## Status

### Working

* Boots successfully
* Touchscreen
* Data decryption (NXP Weaver + StrongBox)
* ADB / Fastbootd

### Notes on the decrypt runtime

The NXP StrongBox service must be started early, right after
`vendor.secure_element`, `se_omapi`, `vendor.keymint`, and `keystore2` are up,
and before the real `/vendor` mount can hide the ramdisk OMAPI manifest.
Waiting on stricter pre-conditions (`vendor.qseecomd`, `vendor.minkdaemon`)
before starting StrongBox delays it long enough to break the OMAPI view and
stall decrypt. Once StrongBox reaches `Shared secret negotiation concluded
successfully.`, NXP Weaver is started and completes the decrypt.

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
