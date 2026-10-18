# Firmware CFS personalizzati — Helper K2-OpenHost

Questa cartella contiene il **manifest delle immagini autorizzate e le impronte SHA-256**. I firmware BIN non vengono salvati nella repository dell'Helper: vengono pubblicati nella [repository firmware CFS](https://github.com/MzTechnology97/k2-cfs-rfid-tools/tree/main/firmware).

## Candidati attuali

1. **K2OH v3.23 CFG4 — SPERIMENTALE**: firmware modificato G32/app153, identità RS-485 `K2OH` con `0x7A`, revisione `v323-cfg4`, 28 parametri esposti; soltanto gli ID 1/2/3/5/7/8 sono realmente modificabili all'avvio da Kalico. Build non ancora qualificata su hardware reale.
2. **v3.22 — RIPRISTINO**: mantenere il BIN originale verificato, SHA-256 `40dbaad88de7b6f9435592fa03b081e9b96663a9e84896b1ad8021a8f13cf8c7`.
3. **v3.13**: firmware modificato legacy.
4. **v3.12**: firmware RFID precedente, validato su hardware.

Le vecchie versioni RFID v3.3–v3.11 e i firmware sperimentali v3.19–v3.21 sono stati eliminati **soltanto dal menu principale dell'Helper**. I file storici, le prove e i sorgenti restano recuperabili nella repository firmware e nella cronologia Git.

## Installazione e controllo

Scaricare prima sul CM5 il BIN esatto dalla repository firmware e posizionarlo nella cartella `firmware/custom-cfs`. Verificare lo SHA-256 indicato nel manifest; per la v3.23 è:

    118f34118edeb1e3d4ac018445b3fb839f8762b9d762bbfc011e62861fe8f71b

Il percorso del firmware è:

[CFS v3.23 CFG4 sperimentale](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/firmware/v3.23-k2oh/cfs0_050_G32-cfs0_000_153-runtime-config-v3_23-K2OH-CFG4-EXPERIMENTAL.bin)

Eseguire:

    cd ~/k2-openhost-installer-helper
    K2OH_NO_UPDATE_CHECK=1 ./helper.sh experimental-cfs

Il menu confronta nome hardware/applicazione e SHA-256, verifica i prerequisiti del T113 e richiede la conferma testuale esatta `FLASH EXPERIMENTAL CFS`. Non sono eseguiti flash automatici e `--yes` non può aggirare la conferma.

**Compatibilità:** i valori CFG4 si applicano solo alla build K2-OpenHost abbinata, distribuita da k2-cfs-rfid-tools. Firmware Creality stock, firmware non verificati e OpenCFS non accettano questi SET. OpenCFS deve comunque essere identificato separatamente da Kalico con firma `OCFS`.

[Guida parametri IT](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFS_V323_PARAMETER_GUIDE_IT.md) | [Parameter guide EN](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFS_V323_PARAMETER_GUIDE_EN.md) | [English Helper guide](README.md)
