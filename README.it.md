# K2-OpenHost Installer Helper

[English](README.md) · **Italiano**

> [!WARNING]
> **Solo per utenti esperti, a tuo rischio.** K2-OpenHost fa decadere la garanzia e può danneggiare la stampante in modo irreparabile, bloccarne il firmware o, in caso di guasto, causare un incendio. Gli autori non si assumono alcuna responsabilità per danni a cose o persone. In modalità OpenHost la telecamera della camera va ricablata all'host esterno, la telecamera dell'ugello non si può usare e la porta USB esterna della stampante smette di funzionare. Leggi prima l'[esclusione di responsabilità e i limiti hardware](https://mztechnology97.github.io/K2-OpenHost/it/DISCLAIMER/).

L'helper trasforma un computer Linux esterno in un host [K2-OpenHost](https://mztechnology97.github.io/K2-OpenHost/it/) per la Creality K2 Pro. Installa Kalico, Moonraker e il fork Mainsail K2-OpenHost e, dallo stesso menu, prepara la stampante: il bootstrap della T113 scrive un sistema K2-OpenHost nello slot B libero della T113, con i bridge del gadget USB e HelixScreen collegati a questo host. Aggiorna anche tutto, controlla il sistema, fa i backup e aggiorna il firmware delle MCU con gli strumenti di Creality.

```text
Scheda madre K2 Pro (T113)                      Host Linux esterno (questo helper)
  MCU principale ttyS2 ── ttyGS0 ─┐              ┌── /dev/k2-main
  MCU ugello     ttyS3 ── ttyGS1 ─┼── USB di ────┼── /dev/k2-nozzle
  RS-485/CFS     ttyS5 ── ttyGS2 ─┘   servizio   └── /dev/k2-rs485
                                                     Kalico · Moonraker · Mainsail
  Cartographer3D (opzionale) ─────────── USB diretto ──> /dev/k2-cartographer
```

<img src="docs/images/cli-menu.png" alt="Menu dell'helper" width="760">

## Avvio rapido

Su un host basato su Debian (consigliato Raspberry Pi OS a 64 bit), come utente normale con `sudo`:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/MzTechnology97/k2-openhost-installer-helper.git ~/k2-openhost-installer-helper
~/k2-openhost-installer-helper/helper.sh
```

Scegli **1) Full install**, riavvia, collega la K2 ed esegui `~/k2-openhost-installer-helper/helper.sh doctor`. Poi apri `http://<nome-o-ip-dell-host>/`.

La guida completa, dalla preparazione della scheda SD alla prima stampa, è nella wiki: [installazione](https://mztechnology97.github.io/K2-OpenHost/it/installation/). Lo stack software è quello che gira ogni giorno sulla K2 Pro di riferimento con un CM5; un'installazione completa su un host nuovo non è ancora stata ripetuta da capo, quindi tieni la configurazione attuale finché la nuova non funziona.

## Cosa installa

- **Host:** strumenti di compilazione, accesso alle porte seriali, nomi stabili per i canali della K2 (`/dev/k2-main`, `/dev/k2-nozzle`, `/dev/k2-rs485`, `/dev/k2-cartographer`), `~/printer_data`. ModemManager e brltty vengono fermati perché si prendono le porte seriali USB.
- **Kalico** [`k2-pro-openhost`](https://github.com/MzTechnology97/kalico-k2pro) con il profilo della K2 Pro, un controllo all'avvio che aspetta i canali del gadget, e KAMP (già incluso in Kalico).
- **Moonraker** e **Mainsail K2-OpenHost** (pannello della CFS, libreria filamenti, mappatura di stampa, pannello dei motori) dietro nginx.
- Con l'installazione completa: Moonraker timelapse e Klippain Shake&Tune.
- Opzionali: Cartographer3D (plugin ufficiale), Crowsnest con la correzione per la telecamera Creality, la MCU dell'host, la ventola del CM5 da Klipper, Spoolman, Mobileraker, OctoEverywhere.

I file esistenti non vengono mai sovrascritti: le cartelle vengono rinominate con la data, i file salvati, e un file del profilo più recente viene scritto accanto al tuo come `.k2oh-new`.

## Comandi di tutti i giorni

| Comando | Menu | Cosa fa |
| --- | --- | --- |
| `./helper.sh` | | il menu |
| `./helper.sh doctor` | 16 | controlla host, Klipper, CFS, motori e collegamento RS-485 |
| `./helper.sh update` | 17 | aggiorna Kalico, Moonraker e Mainsail |
| `./helper.sh release status` / `apply` | 34 | confronta con la release provata e la applica |
| `./helper.sh backup` / `restore` | 20 / 21 | configurazione, libreria filamenti, stato della CFS e database di Moonraker |
| `./helper.sh t113 install` | 24 | scrive lo slot B sulla T113 (stampante ferma) |
| `./helper.sh t113 update` | 33 | aggiorna i programmi di K2-OpenHost sullo slot B |
| `./helper.sh t113 mcu-fw update` | 31 | firmware di MCU, motori e CFS con gli strumenti di Creality |

Aggiornamenti, ripristini e riavvii di Klipper vengono rifiutati durante una stampa o una pausa. Tutte le voci e le loro opzioni: [riferimento del menu](https://mztechnology97.github.io/K2-OpenHost/it/helper/menu/), [doctor](https://mztechnology97.github.io/K2-OpenHost/it/helper/doctor/), [bootstrap della T113](https://mztechnology97.github.io/K2-OpenHost/it/T113_BOOTSTRAP/), [aggiornamenti e release](https://mztechnology97.github.io/K2-OpenHost/it/installation/updates/), [backup](https://mztechnology97.github.io/K2-OpenHost/it/installation/backup/).

<img src="docs/images/cli-doctor.png" alt="Risultato di doctor" width="760">

## Risoluzione dei problemi

| Sintomo | Cosa fare |
| --- | --- |
| doctor: `not in group dialout` / `tty` | Riavvia l'host, oppure esci e rientra. |
| doctor: `the K2 gadget (0525:a4a6) is not connected` | Usa un cavo dati nella porta Micro-USB **di servizio** della K2; `lsusb` deve mostrare *Linux-USB Serial Gadget*. |
| doctor: `interface .. is /dev/ttyUSBx but printer.cfg uses ...` | Menu 19 (nomi seriali stabili), poi riavvia Klipper. |
| doctor: `process … also uses /dev/ttyUSBx` | Un altro programma legge il canale e la CFS o i motori smettono di rispondere: fermalo. Il vecchio demux del Cartographer si rimuove con `scripts/system.sh retire-demux`. |
| Mainsail: *mcu 'mcu': Unable to connect* | Gli stessi controlli del gadget; *Firmware restart* in Mainsail riprova subito. |
| Il browser mostra *403 Forbidden* | `chmod o+x ~` e ricarica, oppure riesegui il menu 7. |
| Il browser non raggiunge l'host | `sudo systemctl status nginx`; controlla l'indirizzo con `hostname -I`. |

Altro nella [risoluzione dei problemi](https://mztechnology97.github.io/K2-OpenHost/it/reference/troubleshooting/) della wiki. Quando chiedi aiuto, allega `./helper.sh doctor` e `~/printer_data/logs/klippy.log`.

## Riconoscimenti

K2-OpenHost si basa su Klipper, Kalico, Jacob10383 (Kalico per K2, estensioni, flusso della CFS), luketot (base della K2 Pro), Moonraker, Mainsail, Cartographer3D, Klippain Shake&Tune, moonraker-timelapse, Crowsnest e DnG-Crafts/K2-RFID. L'impostazione del menu si ispira al [Creality Helper Script](https://github.com/tofuliang/Creality-Helper-Script-K2-Series) (Guilouz, sw3defy, tofuliang).

Licenza: GPL-3.0.
