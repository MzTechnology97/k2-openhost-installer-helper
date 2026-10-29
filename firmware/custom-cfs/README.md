# CFS G32 - CFG6 SGF1/RH1 R3

Menu **40** offers R3 first and the previous RDG2 image second.
R3 is paired with [Kalico k2-pro-openhost](https://github.com/MzTechnology97/kalico-k2pro/tree/k2-pro-openhost).

| Image | SHA-256 | Scope |
|---|---|---|
| [cfs0_050_G32-cfs0_000_153-K2OH-CFG6-SGF1-RH1-R3-CANDIDATE.bin](cfs0_050_G32-cfs0_000_153-K2OH-CFG6-SGF1-RH1-R3-CANDIDATE.bin) | `a6dec25c74e7d259eec0387193548a0c3cc78ec9fc4ddc35824f0fe0965385b8` | R3,185900bytes; G32 / cfs0_000_153 |
| RDG2 fallback | `7d611c5845d3c248cf55f57972fdc7fab1761d0e281bcbf70030ac97e458023f` | previous reference; no SGF1/RH1 geometry |

R3 hardware evidence: Bambu PETG HF reads in slots2/4, one RH1 job each,
UID flags0x13, RAM catalog/binding, per-UID327m lengths, consumption and
automatic runout replacement. This does not qualify every tag/board/lifecycle.
The filename retains CANDIDATE to preserve the exact tested artifact.

Use [the conf](https://github.com/MzTechnology97/kalico-k2pro/blob/k2-pro-openhost/config/k2/macros/box_spool_profiles.cfg)
and [the calibration procedure (Italian)](https://github.com/MzTechnology97/kalico-k2pro/blob/k2-pro-openhost/docs/CFS_SPOOL_CALIBRATION.md).
The Bambu host profile is `bambu = 1, 284.7, 508.3` (circumferences in mm).
The effective core comes from the first real runout and awaits repeat validation;
it is not the physical cardboard diameter. Firmware bytes are unchanged.
The detailed [firmware manifest](SGF1-RH1-R3-firmware-manifest.json) records scope.

Before flashing, stop printing/loading/unloading, prove printer/CFS idle and
follow the supervised menu. Type exactly `FLASH EXPERIMENTAL CFS`.
The host idle interlock rejects unavailable/unsafe status; it does not replace
physical supervision. Use T113 bootstrap0.1.2+ to preserve OEM application naming.
Enable the paired Kalico config and restart only while idle. Keep the fallback
and OEM recovery path available; these images target only G32 / APP153.

## R4-PRECISION1 candidate

The third menu entry is an experimental precision build, awaiting hardware validation. R3 stays first and RDG2 second. Use the matching Kalico modules before expecting millimetre estimates; legacy clients remain compatible. See [candidate manifest](SGF1-RH1-R4-PRECISION1-firmware-manifest.json) and [paired test procedure](https://github.com/MzTechnology97/kalico-k2pro/blob/feature/cfs-precise-remaining-20261029/docs/CFS_PRECISE_REMAINING.md). Do not flash or restart during a print.
