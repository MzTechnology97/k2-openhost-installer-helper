# Custom CFS firmware in the K2-OpenHost Helper

The Helper's manifest is a **selection and SHA-256 allowlist**, not a
source of firmware. Proprietary/manufacturer-derived BIN images are not
stored in this Helper repository (see .gitignore). Images are published
by the dedicated firmware project. Select an image only after its file
has been placed in this directory with exactly its original filename.

## Current curated images

1. **K2OH v3.23 CFG4 — experimental, hardware not qualified**.
   K2OH identity through command 0x7A, original G32/app153.
   Matching Kalico required for startup-only CFG parameters. Only
   IDs 1, 2, 3, 5, 7, 8 are genuinely modifiable in this build.
   SHA256: 118f34118edeb1e3d4ac018445b3fb839f8762b9d762bbfc011e62861fe8f71b.
2. **v3.22** — previously tested recovery image, retain its exact
   SHA256: 40dbaad88de7b6f9435592fa03b081e9b96663a9e84896b1ad8021a8f13cf8c7.
3. **v3.13** — legacy patched stock application.
4. **v3.12** — earlier hardware-validated RFID release.

Earlier v3.3/v3.6–v3.11 and v3.19 bench images were removed
**from the active menu only**. Historical sources, experiment records
and Git history are retained in the firmware repository.

The v3.23 image is published at:

https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/firmware/v3.23-k2oh/cfs0_050_G32-cfs0_000_153-runtime-config-v3_23-K2OH-CFG4-EXPERIMENTAL.bin

To stage the matching image, from the Helper root on CM5:

    curl -fL --retry 3 -o firmware/custom-cfs/cfs0_050_G32-cfs0_000_153-runtime-config-v3_23-K2OH-CFG4-EXPERIMENTAL.bin       https://raw.githubusercontent.com/MzTechnology97/k2-cfs-rfid-tools/main/firmware/v3.23-k2oh/cfs0_050_G32-cfs0_000_153-runtime-config-v3_23-K2OH-CFG4-EXPERIMENTAL.bin

Verify it **before** choosing it in the menu:

    sha256sum firmware/custom-cfs/cfs0_050_G32-cfs0_000_153-runtime-config-v3_23-K2OH-CFG4-EXPERIMENTAL.bin

The expected digest is listed above and in manifest.json. The menu
checks the file and digest a second time.

    K2OH_NO_UPDATE_CHECK=1 ./helper.sh experimental-cfs

The Helper **requires the exact interactive FLASH EXPERIMENTAL CFS
acknowledgement**. --yes does not bypass it. The T113 Bootstrap verifies
the target hardware, APP header CRC16 and size, initial MSP, reset vector,
upload hash and update result. The normal Creality update menu is
separate. Keep the exact v3.22 firmware available to restore bus
communications if an experimental image fails.

K2OH parameters are supported only by the paired modified CFS firmware
published in k2-cfs-rfid-tools. Creality stock and arbitrary firmware
(including the independent OpenCFS family identified as OCFS) do not
support these K2OH CFG4 writes. Full parameter guide:

https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFS_V323_PARAMETER_GUIDE_IT.md

## Important local-installation note

Existing CM5 instances can have additional **locally staged** OpenCFS
INERT/BENCH images or different menu ordering. Updating this repository
is not permission to overwrite the local manifest or remove images
during an MCU flash. Verify the selected filename and SHA256 every time;
do not assume the same menu number across devices.

## Translations / Traduzioni

[Guida italiana dei firmware CFS](README.it.md) | [CFS firmware guide in English](README.md) | [Parameters IT](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFS_V323_PARAMETER_GUIDE_IT.md) | [Parameters EN](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFS_V323_PARAMETER_GUIDE_EN.md)
