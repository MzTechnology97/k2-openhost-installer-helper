# K2-OpenHost Installer Helper

**English** · [Italiano](README.it.md)

> [!WARNING]
> **Experienced users only, at your own risk.** K2-OpenHost voids the warranty and can damage the printer beyond repair, brick its firmware or, if something fails, cause a fire. The authors accept no liability for damage to property or persons. In OpenHost mode the chamber camera must be rewired to the external host, the nozzle camera cannot be used, and the printer's external USB port stops working. Read the [disclaimer and hardware limits](https://mztechnology97.github.io/K2-OpenHost/DISCLAIMER/) first.

The helper turns an external Linux computer into a [K2-OpenHost](https://mztechnology97.github.io/K2-OpenHost/) host for the Creality K2 Pro. It installs Kalico, Moonraker and the Mainsail K2-OpenHost fork, and from the same menu it prepares the printer: the T113 bootstrap writes a K2-OpenHost system to the T113's spare slot B, with the USB gadget bridges and HelixScreen pointed at this host. It also updates everything, checks the system, makes backups and flashes MCU firmware with Creality's own tools.

```text
Creality K2 Pro mainboard (T113)                External Linux host (this helper)
  Main MCU   ttyS2 ── ttyGS0 ─┐                  ┌── /dev/k2-main
  Nozzle MCU ttyS3 ── ttyGS1 ─┼── service USB ───┼── /dev/k2-nozzle
  RS-485/CFS ttyS5 ── ttyGS2 ─┘                  └── /dev/k2-rs485
                                                     Kalico · Moonraker · Mainsail
  Cartographer3D (optional) ────────── direct USB ──> /dev/k2-cartographer
```

<img src="docs/images/cli-menu.png" alt="Helper menu" width="760">

## Quick start

On a Debian-based host (Raspberry Pi OS 64-bit recommended), as a normal user with `sudo`:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/MzTechnology97/k2-openhost-installer-helper.git ~/k2-openhost-installer-helper
~/k2-openhost-installer-helper/helper.sh
```

Choose **1) Full install**, reboot, connect the K2 and run `~/k2-openhost-installer-helper/helper.sh doctor`. Then open `http://<host-name-or-ip>/`.

The full guide, from flashing the SD card to the first print, is in the wiki: [installation](https://mztechnology97.github.io/K2-OpenHost/installation/). The software stack is the one running every day on the reference K2 Pro with a CM5; a complete install on a fresh host has not been repeated end to end yet, so keep your current setup until the new one works.

## What it installs

- **Host:** build tools, serial port access, stable names for the K2 channels (`/dev/k2-main`, `/dev/k2-nozzle`, `/dev/k2-rs485`, `/dev/k2-cartographer`), `~/printer_data`. ModemManager and brltty are stopped because they grab USB serial ports.
- **Kalico** [`k2-pro-openhost`](https://github.com/MzTechnology97/kalico-k2pro) with the K2 Pro profile, a start gate that waits for the gadget channels, and KAMP (built into Kalico).
- **Moonraker** and **Mainsail K2-OpenHost** (CFS panel, filament library, print mapping, motor panel) behind nginx.
- With the full install: Moonraker timelapse and Klippain Shake&Tune.
- Optional: Cartographer3D (official plugin), Crowsnest with the Creality chamber camera fix, the host MCU, the CM5 fan from Klipper, Spoolman, Mobileraker, OctoEverywhere.

Existing files are never overwritten: folders are renamed with a date, files are backed up, and a newer profile file is written next to yours as `.k2oh-new`.

## Everyday commands

| Command | Menu | What it does |
| --- | --- | --- |
| `./helper.sh` | | the menu |
| `./helper.sh doctor` | 16 | checks host, Klipper, CFS, motors and the RS-485 link |
| `./helper.sh update` | 17 | updates Kalico, Moonraker and Mainsail |
| `./helper.sh release status` / `apply` | 34 | compares with the tested release and applies it |
| `./helper.sh backup` / `restore` | 20 / 21 | configuration, filament library, CFS state and Moonraker database |
| `./helper.sh t113 install` | 24 | writes slot B on the T113 (printer idle) |
| `./helper.sh t113 update` | 33 | updates K2-OpenHost's programs on slot B |
| `./helper.sh t113 mcu-fw update` | 31 | MCU, motor and CFS firmware with Creality's tools |

Updates, restores and Klipper restarts are refused while a print is running or paused. Every entry and its options: [menu reference](https://mztechnology97.github.io/K2-OpenHost/helper/menu/), [doctor](https://mztechnology97.github.io/K2-OpenHost/helper/doctor/), [T113 bootstrap](https://mztechnology97.github.io/K2-OpenHost/T113_BOOTSTRAP/), [updates and releases](https://mztechnology97.github.io/K2-OpenHost/installation/updates/), [backup](https://mztechnology97.github.io/K2-OpenHost/installation/backup/).

<img src="docs/images/cli-doctor.png" alt="Doctor output" width="760">

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| doctor: `not in group dialout` / `tty` | Reboot the host, or log out and in again. |
| doctor: `the K2 gadget (0525:a4a6) is not connected` | Use a data cable in the K2's **service** Micro-USB port; `lsusb` must list *Linux-USB Serial Gadget*. |
| doctor: `interface .. is /dev/ttyUSBx but printer.cfg uses ...` | Menu 19 (stable serial names), then restart Klipper. |
| doctor: `process … also uses /dev/ttyUSBx` | Another program reads the channel and the CFS or motors stop answering: stop it. The old Cartographer demux is removed with `scripts/system.sh retire-demux`. |
| Mainsail: *mcu 'mcu': Unable to connect* | Same checks as for the gadget; *Firmware restart* in Mainsail retries at once. |
| Browser shows *403 Forbidden* | `chmod o+x ~` and reload, or run menu 7 again. |
| Browser cannot reach the host | `sudo systemctl status nginx`; check the address with `hostname -I`. |

More in the wiki's [troubleshooting](https://mztechnology97.github.io/K2-OpenHost/reference/troubleshooting/). When asking for help, attach `./helper.sh doctor` and `~/printer_data/logs/klippy.log`.

## Credits

K2-OpenHost builds on Klipper, Kalico, Jacob10383 (K2 Kalico, extras, CFS workflow), luketot (K2 Pro baseline), Moonraker, Mainsail, Cartographer3D, Klippain Shake&Tune, moonraker-timelapse, Crowsnest and DnG-Crafts/K2-RFID. The menu layout is inspired by the [Creality Helper Script](https://github.com/tofuliang/Creality-Helper-Script-K2-Series) (Guilouz, sw3defy, tofuliang).

License: GPL-3.0.
