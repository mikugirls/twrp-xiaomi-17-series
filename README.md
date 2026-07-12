# TWRP Device Trees — Xiaomi 17 Series

Device trees for building Team Win Recovery Project (TWRP) for the Xiaomi 17 Series.

**Maintainer:** antocorvo3000

| Device            | Codename  | Folder                                                  | Status |
| ------------------ | --------- | -------------------------------------------------------- | ------ |
| Xiaomi 17          | Pudding   | [`twrp_device_xiaomi_pudding`](twrp_device_xiaomi_pudding)   | Boots, touch, decrypt working |
| Xiaomi 17 Pro       | Pandora   | [`twrp_device_xiaomi_pandora`](twrp_device_xiaomi_pandora)   | Boots, touch working; decrypt not stable |
| Xiaomi 17 Pro Max   | Popsicle  | [`twrp_device_xiaomi_popsicle`](twrp_device_xiaomi_popsicle) | Boots, touch, decrypt working |
| Xiaomi 17 Ultra     | Nezha     | [`twrp_device_xiaomi_nezha`](twrp_device_xiaomi_nezha)       | Boots, touch working; decrypt not yet confirmed, should work in theory |

Each device folder is a self-contained TWRP device tree (BoardConfig, device makefile, fstab, prebuilt blobs, source patches) with its own `README.md` describing that device in detail.

## Releases

Built recovery images (stock-AVB, ready to `fastboot flash recovery`) are published under [Releases](../../releases). Pudding, Pandora, and Popsicle currently have a working release build. Nezha will be added once its current decrypt work lands.

## Status by device

### Xiaomi 17 (Pudding)

* Working: boot, touch, data decryption (stable)

### Xiaomi 17 Pro (Pandora)

* Working: boot, touch
* Not stable: data decryption (NXP Weaver + StrongBox). StrongBox timing
  relative to the real `/vendor` mount and OMAPI visibility has needed several
  corrections and is not yet reliably reproducible.

### Xiaomi 17 Pro Max (Popsicle)

* Working: boot, touch, data decryption (NXP Weaver + Gatekeeper, no StrongBox, stable)

### Xiaomi 17 Ultra (Nezha)

* Working: boot, touch (kernel-module only, no userspace touch-report service)
* Not yet confirmed: full user-data decryption. StrongBox has been removed
  from the boot chain (Weaver + Gatekeeper only, Gatekeeper running in
  non-SPU mode); both known `system/vold/Decrypt.cpp` bugs are patched. This
  should work in theory but has not been confirmed on real hardware yet.

## Known issue: mount failures after flashing a ROM update

On Popsicle, flashing a ROM update can leave the running recovery unable to
mount storage afterward, sometimes to the point that recovery cannot even
reflash itself from within TWRP — until recovery is rebooted, after which
everything works again. The fact that a same-session reboot fixes it (no
reflash needed) points to a stale device-mapper state rather than a wrong
fstab entry: TWRP creates the `dm-linear` mappings for the dynamic ("super")
partitions once at boot, from the super partition layout as it exists at that
moment. A ROM flash rewrites the super partition (partition boundaries/sizes
for system/vendor/product/etc.), but the already-running recovery keeps using
its old, now-stale `dm-linear` mappings — it does not re-scan the super
partition mid-session. Only a reboot tears down and recreates those mappings
against the current super partition metadata, which is why the reboot
resolves it. A possible source-level fix is forcing TWRP to re-detect/resize
the super partition after an install completes rather than only at startup
(see `TWPartitionManager::Setup_Super_Partition` / `Update_Size`). This is not
Popsicle-specific — the same class of failure could in theory hit any of the
four devices after a flash that changes the dynamic partition layout; not yet
confirmed on the other three.

## Decrypt fix shared across all four devices

All four device trees include a fix for an AES-256-GCM authentication-tag
handling bug in `system/vold/Decrypt.cpp` (`Decrypt_User_Synth_Pass`, the
synthetic-password unwrap path): the original code split ciphertext/tag
incorrectly, used an uninitialized tag buffer as the expected GCM tag, and
never checked the OpenSSL EVP return codes — so a failed/unauthenticated
decrypt could silently be treated as successful. See
`patches/0001-vold-fix-synthetic-password-gcm.patch` in each device folder.

## Acknowledgements

The Nezha (Xiaomi 17 Ultra) touch and decrypt approach in this repository —
kernel-module-only touch with no userspace touch-report service, and a
StrongBox-free Weaver/Gatekeeper decrypt chain — was informed by comparing
against [EkinStrop/twrp_device_xiaomi_nezha](https://github.com/EkinStrop/twrp_device_xiaomi_nezha),
a public Nezha TWRP device tree by JohnTheFarm3r that reports working data
decryption using the same approach. Thank you for publishing that work.

* Team Win Recovery Project (TWRP)
* Android Open Source Project (AOSP)
* The Android aftermarket development community

## License

Copyright (C) 2026 antocorvo3000

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this project except in compliance with the License. You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

A copy of the Apache License 2.0 is included in this repository as the `LICENSE` file.
