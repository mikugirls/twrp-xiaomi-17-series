# TWRP Device Tree for Xiaomi 17 Ultra (Nezha)

Device tree for building Team Win Recovery Project (TWRP) for the Xiaomi 17 Ultra (Nezha).

**Maintainer:** antocorvo3000_JohnTheFarm3r

## Device Information

| Property     | Value                      |
| ------------ | -------------------------- |
| Device       | Xiaomi 17 Ultra             |
| Codename     | Nezha                       |
| Manufacturer | Xiaomi                      |
| Platform     | Qualcomm Snapdragon (sm8750_thales family) |
| Architecture | arm64                       |

## Status

### Working

* Boots successfully
* Touchscreen (kernel-module only: `xiaomi_touch.ko` + `synaptics_tcm2.ko`,
  no userspace touch-report service)
* Secure runtime bring-up: KeyMint (onekeymint), secure element, OMAPI,
  Weaver, Gatekeeper
* ADB / Fastbootd

### In progress

* Full user-data decryption. StrongBox has been removed from the boot chain
  entirely (Weaver + Gatekeeper is used instead, matching the working
  Popsicle decrypt path); Gatekeeper runs in non-SPU mode
  (`vendor.gatekeeper.disable_spu=true`, `vendor.gatekeeper.is_security_level_spu=0`).
  Both known `system/vold/Decrypt.cpp` decrypt bugs are patched (Weaver slot
  byte-offset parsing, and the AES-256-GCM synthetic-password auth-tag
  handling). This combination has not yet been confirmed as fully working on
  real hardware.

## Notes on this revision

This tree drops the StrongBox-thales service entirely from the Nezha boot
chain rather than trying to bring it up: TouchWiz/Xiaomi's TWRP decrypt for
this platform only needs Weaver plus Gatekeeper to unwrap the synthetic
password, and StrongBox's own SharedSecret negotiation was a recurring source
of boot instability. `TW_INPUT_BLACKLIST := "hbtp_vm"` excludes the HBTP
virtual input device so the real touch input node is never mistaken for it.

Touch and decrypt architecture in this revision were informed by comparing
against another public Nezha TWRP tree that reported working decryption using
the same kernel-module-only touch approach and a StrongBox-free boot chain.

The decrypt path in `system/vold/Decrypt.cpp` includes a fix for an AES-256-GCM
authentication-tag handling bug in the synthetic-password unwrap path
(`Decrypt_User_Synth_Pass`): the original code split ciphertext/tag incorrectly,
used an uninitialized tag buffer, and never checked the OpenSSL EVP return
codes. See `patches/0001-vold-fix-synthetic-password-gcm.patch`.

## Credits

* Team Win Recovery Project (TWRP)
* Android Open Source Project (AOSP)
* The Android aftermarket development community
