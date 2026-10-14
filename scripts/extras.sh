#!/usr/bin/env bash
# Optional components for the K2-OpenHost host.
#   hostmcu       Klipper Linux host MCU ([mcu rpi]: host GPIO/ADXL, CM5 temperature)
#   cartographer  Cartographer3D plugin, official (direct USB to the host)
#   shaketune     Klippain Shake&Tune resonance tools
#   timelapse     Moonraker timelapse (the K2 profile ships its macros)
#   crowsnest     webcam streaming (with creality-cam when the K2 camera is connected)
#   creality-cam  crowsnest settings for the K2 Pro chamber camera (Creality CAM)
#   spoolman      connect Moonraker to an existing Spoolman server
#   mobileraker   Mobileraker companion (push notifications)
#   octoeverywhere OctoEverywhere remote access
#   host-fan      the host's CPU fan from Klipper ([host_fan], CM5 fan header)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# add_include <file.cfg>: include it from printer.cfg, before overrides.cfg and
# the SAVE_CONFIG block, unless it is already included.
add_include() {
    local name="$1" cfg="$CONFIG_DIR/printer.cfg"
    [[ -f "$cfg" ]] || { warn "printer.cfg not found; add [include $name] yourself"; return 0; }
    if grep -Eq "^\[include[[:space:]]+(\./)?${name//./\\.}\]" "$cfg"; then
        ok "printer.cfg already includes $name"
        return 0
    fi
    backup_file "$cfg"
    if grep -Eq "^#[[:space:]]*\[include[[:space:]]+(\./)?${name//./\\.}\]" "$cfg"; then
        sed -i -E "s#^\#[[:space:]]*\[include[[:space:]]+(\./)?${name//./\\.}\]#[include ${name}]#" "$cfg"
    else
        python3 - "$cfg" "$name" <<'PY'
import sys
path, name = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
line = "[include %s]" % name
index = len(lines)
for i, text in enumerate(lines):
    if text.startswith("#*# <") or text.strip().startswith(
            ("[include overrides.cfg]", "[include macros/overrides.cfg]")):
        index = i
        break
lines.insert(index, line)
open(path, "w").write("\n".join(lines))
PY
    fi
    ok "printer.cfg includes $name"
}

hostmcu() {
    step "Klipper Linux host MCU"
    [[ -d "$KLIPPER_DIR" ]] || die "install Kalico first"
    guard_not_printing
    [[ -f "$KLIPPER_DIR/.config" ]] && cp "$KLIPPER_DIR/.config" "$KLIPPER_DIR/.config.before-hostmcu"
    printf 'CONFIG_LOW_LEVEL_OPTIONS=y\nCONFIG_MACH_LINUX=y\n' > "$KLIPPER_DIR/.config"
    make -C "$KLIPPER_DIR" olddefconfig >/dev/null
    make -C "$KLIPPER_DIR" clean >/dev/null
    make -C "$KLIPPER_DIR" -j"$(nproc)" >/dev/null
    sudo "$KLIPPER_DIR/scripts/flash-linux.sh" "$KLIPPER_DIR/out" >/dev/null
    sudo install -m 644 "$KLIPPER_DIR/scripts/klipper-mcu.service" /etc/systemd/system/klipper-mcu.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now klipper-mcu >/dev/null 2>&1
    ok "klipper_mcu running on /tmp/klipper_host_mcu"
    local cfg="$CONFIG_DIR/printer.cfg"
    if [[ -f "$cfg" ]] && grep -Eq '^#[[:space:]]*\[mcu rpi\]' "$cfg"; then
        if confirm "Enable [mcu rpi] in printer.cfg?" y; then
            backup_file "$cfg"
            sed -i -E 's/^#[[:space:]]*\[mcu rpi\]/[mcu rpi]/; s#^\#[[:space:]]*(serial:[[:space:]]*/tmp/klipper_host_mcu)#\1#' "$cfg"
            ok "[mcu rpi] enabled"
        fi
    fi
    mark_installed hostmcu
}

cartographer() {
    step "Cartographer3D plugin (official)"
    [[ -x "$KLIPPY_ENV/bin/python" ]] || die "install Kalico first"
    # Kalico does not ship Cartographer; the official plugin supports Kalico
    # and the K2 (non-critical reconnect, register_as_probe) directly.
    local conf
    conf="$(moonraker_conf)"
    if [[ -d "$LEGACY_CARTOGRAPHER_DIR" ]]; then
        info "replacing the former K2-OpenHost Cartographer fork"
        "$KLIPPY_ENV/bin/pip" uninstall -q -y cartographer3d-plugin || true
        mkdir -p "$BACKUP_DIR"
        mv "$LEGACY_CARTOGRAPHER_DIR" "$BACKUP_DIR/cartographer3d-plugin-k2openhost-$(date +%Y%m%d-%H%M%S)"
        ok "old fork moved to $BACKUP_DIR"
    fi
    # Moonraker updates the official plugin as a pip package.
    if has_section "$conf" "update_manager cartographer" && grep -q "cartographer3d-plugin-k2openhost" "$conf"; then
        backup_file "$conf"
        python3 - "$conf" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path).read()
text = re.sub(r"^\[update_manager cartographer\]\n(?:(?!^\[).*\n)*", "", text, flags=re.M)
open(path, "w").write(text)
PY
    fi
    local tmp
    tmp="$(mktemp -d)"
    git clone -q --depth 1 "$CARTOGRAPHER_REPO" "$tmp/cartographer"
    bash "$tmp/cartographer/scripts/install.sh" --klipper "$KLIPPER_DIR" --klippy-env "$KLIPPY_ENV"
    rm -rf "$tmp"
    add_section "$conf" "update_manager cartographer" <<EOF
type: python
channel: stable
virtualenv: ${KLIPPY_ENV}
project_name: cartographer3d-plugin
is_system_service: False
managed_services: klipper
info_tags:
    desc=Cartographer3D Plugin
EOF
    info "Connect Cartographer to a host USB port: the udev rule names it /dev/k2-cartographer."
    info "PRTouch stays the validated probe; enable Cartographer only after its own tests."
    if confirm "Include cartographer.cfg in printer.cfg now?" n; then
        add_include "$(printer_file cartographer.cfg)"
    fi
    mark_installed cartographer
}

shaketune() {
    step "Klippain Shake&Tune"
    clone_or_update "$SHAKETUNE_REPO" "$SHAKETUNE_DIR" main
    bash "$SHAKETUNE_DIR/install.sh"
    if [[ ! -f "$CONFIG_DIR/shaketune.cfg" ]]; then
        cat > "$CONFIG_DIR/shaketune.cfg" <<'EOF'
# Klippain Shake&Tune (https://github.com/Frix-x/klippain-shaketune)
[shaketune]
# result_folder: ~/printer_data/config/ShakeTune_results
# number_of_results_to_keep: 10
EOF
    fi
    add_include shaketune.cfg
    mark_installed shaketune
}

timelapse() {
    step "Moonraker timelapse"
    [[ -d "$MOONRAKER_DIR" ]] || die "install Moonraker first"
    apt_install ffmpeg
    clone_or_update "$TIMELAPSE_REPO" "$TIMELAPSE_DIR" main
    ln -sf "$TIMELAPSE_DIR/component/timelapse.py" "$MOONRAKER_DIR/moonraker/components/timelapse.py"
    add_section "$(moonraker_conf)" "timelapse" <<EOF
output_path: ${PRINTER_DATA}/timelapse
frame_path: /tmp/timelapse/printer
EOF
    add_section "$(moonraker_conf)" "update_manager timelapse" <<EOF
type: git_repo
primary_branch: main
path: ${TIMELAPSE_DIR}
origin: ${TIMELAPSE_REPO}
managed_services: klipper moonraker
EOF
    mkdir -p "$PRINTER_DATA/timelapse"
    info "The K2 profile already provides timelapse.cfg (macros)."
    restart_service moonraker
    mark_installed timelapse
}

crowsnest() {
    step "Crowsnest (webcam)"
    clone_or_update "$CROWSNEST_REPO" "$CROWSNEST_DIR"
    if [[ "$ASSUME_YES" == "1" ]]; then
        (cd "$CROWSNEST_DIR" && sudo CROWSNEST_UNATTENDED=1 make install)
    else
        (cd "$CROWSNEST_DIR" && sudo make install)
    fi
    mark_installed crowsnest
    if creality_cam_present; then
        creality_cam
    fi
}

# The K2 Pro chamber camera (USB 1d6c:0103, Creality CAM). Its firmware needs
# crowsnest at 25 fps (at 30 its auto exposure goes black) and its controls in
# crowsnest's v4l2ctl, which crowsnest sends before the stream starts.
CREALITY_CAM_ID="1d6c:0103"
CREALITY_CAM_GLOB="${K2OH_CREALITY_CAM_GLOB:-/dev/v4l/by-id/usb-Creality_3D_Technology_CREALITY_CAM_*-video-index0}"

creality_cam_present() { lsusb -d "$CREALITY_CAM_ID" >/dev/null 2>&1; }

creality_cam() {
    step "Creality chamber camera (crowsnest settings)"
    local conf="$CONFIG_DIR/crowsnest.conf" link rc=0
    local -a devices=()
    for link in $CREALITY_CAM_GLOB; do
        [[ -e "$link" ]] && devices+=("$link")
    done
    if [[ ${#devices[@]} -eq 0 ]]; then
        info "the Creality CAM is not connected: run './helper.sh install creality-cam' with it plugged in"
        return 0
    fi
    [[ -f "$conf" ]] || { warn "$conf not found: install crowsnest first"; return 0; }
    python3 "$FILES_DIR/camera/crowsnest_creality_cam.py" "$conf" "${devices[@]}" || rc=$?
    case "$rc" in
        0) ok "crowsnest: max_fps 25 and the camera controls in v4l2ctl"
           info "the camera takes them from its power-on: reboot the host to apply" ;;
        3) warn "no [cam] section in $conf uses ${devices[0]}: set its 'device:' to that path and run this again" ;;
        *) warn "could not update $conf" ;;
    esac
    mark_installed creality-cam
}

spoolman() {
    step "Spoolman"
    local conf url
    conf="$(moonraker_conf)"
    if has_section "$conf" "spoolman"; then
        ok "[spoolman] is already configured in moonraker.conf"
        return 0
    fi
    printf '    Spoolman server URL (for example http://192.168.1.10:7912): '
    read -r url || url=""
    [[ "$url" =~ ^https?:// ]] || die "a URL starting with http:// or https:// is required"
    backup_file "$conf"
    add_section "$conf" "spoolman" <<EOF
server: ${url}
sync_rate: 5
EOF
    restart_service moonraker
    info "Library profiles and slots keep their spoolman_id links."
    mark_installed spoolman
}

mobileraker() {
    step "Mobileraker companion"
    clone_or_update "https://github.com/Clon1998/mobileraker_companion.git" "$HOME/mobileraker_companion" main
    "$HOME/mobileraker_companion/scripts/install.sh"
    mark_installed mobileraker
}

octoeverywhere() {
    step "OctoEverywhere"
    clone_or_update "https://github.com/QuinnDamerell/OctoPrint-OctoEverywhere.git" "$HOME/octoeverywhere"
    (cd "$HOME/octoeverywhere" && ./install.sh)
    mark_installed octoeverywhere
}

# The host's CPU fan from Klipper ([host_fan], kalico-k2pro #74). On a CM5
# the fan header is the CM5's FAN_PWM/FAN_TACH, driven by the kernel's
# pwm-fan driver (hwmon "pwmfan") from the cpu-thermal zone. Klipper needs
# group write access to that hwmon's pwm1 and to the zone's mode (udev rule),
# and the kernel must get the fan back if Klipper dies (ExecStopPost).
HOST_FAN_SYSFS="${K2OH_SYSFS_ROOT:-/sys}"
HOST_FAN_RULE="${K2OH_HOST_FAN_RULE:-/etc/udev/rules.d/99-k2oh-host-fan.rules}"
HOST_FAN_DROPIN="${K2OH_HOST_FAN_DROPIN:-/etc/systemd/system/klipper.service.d/k2oh-host-fan.conf}"

host_fan_hwmon() {
    local h
    for h in "$HOST_FAN_SYSFS"/class/hwmon/hwmon*; do
        [[ "$(cat "$h/name" 2>/dev/null)" == "pwmfan" ]] && { echo "$h"; return 0; }
    done
    return 1
}

host_fan_zone() {
    local z
    for z in "$HOST_FAN_SYSFS"/class/thermal/thermal_zone*; do
        [[ "$(cat "$z/type" 2>/dev/null)" == "cpu-thermal" ]] && { echo "$z"; return 0; }
    done
    return 1
}

host_fan() {
    step "Host fan from Klipper (host_fan)"
    [[ -f "$KLIPPER_DIR/klippy/extras/host_fan.py" ]] || die "this Kalico has no host_fan: update Kalico first"
    local hwmon zone group name target src
    hwmon="$(host_fan_hwmon)" || { warn "no pwm-fan on this host (hwmon 'pwmfan'): nothing to do"; return 0; }
    zone="$(host_fan_zone)" || { warn "no cpu-thermal zone on this host: nothing to do"; return 0; }
    group="$(id -gn)"
    printf '%s\n' \
        '# K2-OpenHost installer helper: let Klipper ([host_fan]) drive the CPU fan.' \
        "SUBSYSTEM==\"hwmon\", ATTR{name}==\"pwmfan\", RUN+=\"/bin/chgrp $group /sys%p/pwm1\", RUN+=\"/bin/chmod g+w /sys%p/pwm1\"" \
        "SUBSYSTEM==\"thermal\", ATTR{type}==\"cpu-thermal\", RUN+=\"/bin/chgrp $group /sys%p/mode\", RUN+=\"/bin/chmod g+w /sys%p/mode\"" \
        | sudo tee "$HOST_FAN_RULE" >/dev/null
    sudo udevadm control --reload-rules
    sudo udevadm trigger --action=change --subsystem-match=hwmon --subsystem-match=thermal || true
    sudo udevadm settle || true
    sudo mkdir -p "$(dirname "$HOST_FAN_DROPIN")"
    printf '%s\n' \
        '# K2-OpenHost installer helper: give the CPU fan back to the kernel when' \
        '# Klipper stops, even after a crash ([host_fan] does it on a clean stop).' \
        '[Service]' \
        "ExecStopPost=-/bin/sh -c 'for z in /sys/class/thermal/thermal_zone*; do [ \"\$\$(cat \$\$z/type)\" = cpu-thermal ] && echo enabled > \$\$z/mode; done; true'" \
        | sudo tee "$HOST_FAN_DROPIN" >/dev/null
    sudo systemctl daemon-reload
    if [[ -w "$hwmon/pwm1" && -w "$zone/mode" ]]; then
        ok "Klipper can drive the fan ($hwmon, $zone)"
    else
        warn "$hwmon/pwm1 or $zone/mode is still not writable by $group: reboot the host"
    fi
    name="$(printer_file host_fan.cfg)"
    target="$CONFIG_DIR/$name"
    src="$KLIPPER_DIR/config/k2/macros/host_fan.cfg"
    if [[ -f "$target" ]]; then
        info "keeping your $target"
    elif [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$target")"
        cp "$src" "$target"
        ok "$name installed"
    else
        warn "$src not found: update Kalico"
    fi
    if [[ -f "$target" ]]; then
        add_include "$name"
    fi
    info "Restart Klipper to apply, not during a print. Commands: HOST_FAN_STATUS, SET_HOST_FAN."
    mark_installed host-fan
}

if [[ "${K2OH_EXTRAS_LIB_ONLY:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi

case "${1:-}" in
    hostmcu|cartographer|shaketune|timelapse|crowsnest|spoolman|mobileraker|octoeverywhere) "$1" ;;
    creality-cam) creality_cam ;;
    host-fan) host_fan ;;
    *) die "usage: $0 hostmcu|cartographer|shaketune|timelapse|crowsnest|creality-cam|host-fan|spoolman|mobileraker|octoeverywhere" ;;
esac
