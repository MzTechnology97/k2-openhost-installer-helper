# Firmware CFS corrente — K2OH CFG6 RDG2

Il manifest propone una sola immagine: **K2OH CFG6 RDG2**, funzionante sulla configurazione di riferimento K2 Pro / CFS G32 verificata il **28 ottobre 2026**. Le vecchie immagini e i test sperimentali sono rimossi dal ramo attivo della repository firmware e rimangono recuperabili nella cronologia Git.

| Campo | Valore |
|---|---|
| File | `cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin` |
| SHA-256 | `7d611c5845d3c248cf55f57972fdc7fab1761d0e281bcbf70030ac97e458023f` |
| Dimensione | 179976 byte |
| Hardware / app | `cfs0_050_G32 / cfs0_000_153` |
| Identita interna | `K2OH / v323-cfg6`, API2, feature `0xE3` |
| Menu | 40 → unica voce corrente |

Il BIN e identico alla build RDG2 provata: RFID Bambu, runtime type4 valido, consumo MCU in crescita e percentuale diretta **39% → 38% → 34%** con 17,113 m conteggiati; nessun errore RS-485 nella sessione di 31548 scambi. Questo riscontro non qualifica ogni formato di tag o il ciclo scarico/rilettura. [Evidenze e limiti](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFG6_RDG2_VALIDATION.md).

## Preparazione e installazione

I BIN non sono versionati nella repository Helper. Scaricare il file corrente dalla repository firmware:

```sh
cd ~/k2-openhost-installer-helper
curl -fL --retry 3 -o firmware/custom-cfs/cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin https://raw.githubusercontent.com/MzTechnology97/k2-cfs-rfid-tools/main/firmware/cfg6-rdg2/cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin
sha256sum firmware/custom-cfs/cfs0_050_G32-cfs0_000_153-K2OH-CFG6-RDG2.bin
K2OH_NO_UPDATE_CHECK=1 ./helper.sh experimental-cfs
```

Confrontare lo SHA con la tabella prima della selezione. Il menu verifica a sua volta nome hardware/app e hash e richiede la frase esatta `FLASH EXPERIMENTAL CFS`; `--yes` non salta la conferma. Eseguire il flash soltanto con stampante del tutto inattiva e una copia di recupero verificata disponibile separatamente. L'operazione resta nel menu sperimentale; l'aggiornamento stock Creality rimane distinto.

Le firme OEM/CFG sono condivise con vecchie build: per identificare RDG2 usare il filename e lo SHA, non soltanto la versione mostrata dalla stampante. Il manifest seleziona e verifica file locali; non li scarica e non esegue flash automaticamente. Le copie locali di recupero non vengono eliminate da questa pulizia.

## Diagnostica e host abbinato

Usare Kalico K2-OpenHost abbinato. Il lettore `box_rfid_diag.py` nella [repository firmware](https://github.com/MzTechnology97/k2-cfs-rfid-tools/tree/main/host/kalico) aggiunge `BOX_CFS_DIAG2 ADDRESS=1 SLOT=3`: lettura in sola lettura dello slot fisico4 tramite la coda RS-485 esistente. Aggiornare il modulo e riavviare il servizio Klipper a stampante ferma. Non aprire la seriale da un secondo programma mentre e posseduta da Klipper.

[Guida firmware IT](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/README.it.md) · [Parametri](https://github.com/MzTechnology97/k2-cfs-rfid-tools/blob/main/docs/CFS_V323_PARAMETER_GUIDE_IT.md) · [English](README.md).
