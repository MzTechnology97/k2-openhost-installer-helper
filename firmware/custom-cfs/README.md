# Current custom CFS firmware — K2OH CFG6 RDG2

The manifest offers one image: **K2OH CFG6 RDG2**, working on the reference K2 Pro / CFS G32 configuration tested on **28 October 2026**. Old images and experimental tests are removed from the firmware repository's active tree and remain recoverable in Git history.

| Field | Value |
|---|---|
| File | `cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin` |
| SHA-256 | `7d611c5845d3c248cf55f57972fdc7fab1761d0e281bcbf70030ac97e458023f` |
| Size | 179976 bytes |
| Hardware / app | `cfs0_050_G32 / cfs0_000_153` |
| Internal identity | `K2OH / v323-cfg6`, API2 features `0xE3` |
| Menu | 40 → single current candidate |

This is byte-identical to the tested RDG2 build: Bambu RFID, valid type4 runtime, increasing MCU consumption and direct CFS percentage **39% → 38% → 34%**, with 17.113 m counted and no RS-485 errors across 31548 exchanges. Other tag formats and unload/reread cycles remain to be validated. [Evidence and limits](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFG6_RDG2_VALIDATION.md).

## Stage and install

The Helper repository does not version BIN images. Download the current file from the firmware repository:

```sh
cd ~/k2-openhost-installer-helper
curl -fL --retry 3 -o firmware/custom-cfs/cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin https://raw.githubusercontent.com/MzTechnology97/k2-cfs-rfid-tools/main/firmware/cfg6-rdg2/cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin
sha256sum firmware/custom-cfs/cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin
K2OH_NO_UPDATE_CHECK=1 ./helper.sh experimental-cfs
```

Compare the SHA above before selecting the file. The menu checks the hardware/app filename and hash again and requires the exact `FLASH EXPERIMENTAL CFS` acknowledgement; `--yes` cannot bypass it. Flash only with the printer fully idle and a separately retained verified recovery image. This remains in the experimental menu, separate from normal Creality MCU updates.

OEM/CFG identity is shared with earlier builds: identify RDG2 by filename and SHA, not only the displayed version. The manifest selects and verifies local files; it neither downloads nor automatically flashes them. This cleanup does not delete local recovery copies.

## Paired host and diagnostics

Use the matching K2-OpenHost Kalico integration. The `box_rfid_diag.py` reader in the [firmware repository](https://github.com/MzTechnology97/k2-cfs-rfid-tools/tree/main/host/kalico) adds `BOX_CFS_DIAG2 ADDRESS=1 SLOT=3`, one read-only request for physical slot4 through the existing RS-485 owner/queue. Update the module and restart the Klipper service only when idle. Do not open the serial device from a second program while Klipper owns it.

[Firmware overview](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/README.md) · [Parameters](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFS_V323_PARAMETER_GUIDE_EN.md) · [Italiano](README.it.md).
