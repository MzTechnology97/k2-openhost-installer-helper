#!/usr/bin/env bash
# host-fan: the udev rule gives the user's group pwm1 and the cpu-thermal
# zone's mode, the klipper.service drop-in hands the fan back to the kernel,
# host_fan.cfg is installed and included once; no pwm-fan changes nothing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail_test() { echo "FAIL: $*" >&2; exit 1; }

export HOME="$TMP/home" HELPER_DIR="$ROOT" KLIPPER_DIR="$TMP/klipper"
export PRINTER_DATA="$TMP/home/printer_data" K2OH_GATE_DROPIN="$TMP/no-gate.conf"
export K2OH_EXTRAS_LIB_ONLY=1 K2OH_SYSFS_ROOT="$TMP/sys"
export K2OH_HOST_FAN_RULE="$TMP/etc/udev/rules.d/99-k2oh-host-fan.rules"
export K2OH_HOST_FAN_DROPIN="$TMP/etc/systemd/system/klipper.service.d/k2oh-host-fan.conf"
mkdir -p "$PRINTER_DATA/config" "$KLIPPER_DIR/klippy/extras" "$KLIPPER_DIR/config/k2/macros" "$TMP/etc/udev/rules.d"
touch "$KLIPPER_DIR/klippy/extras/host_fan.py"
printf '[host_fan cm5_fan]\ntarget_temp: 55\n' > "$KLIPPER_DIR/config/k2/macros/host_fan.cfg"
printf '[mcu]\nserial: /dev/x\n[include macros/print.cfg]\n[include macros/overrides.cfg]\n' > "$PRINTER_DATA/config/printer.cfg"

# shellcheck source=/dev/null
source "$ROOT/scripts/extras.sh"
sudo() { "$@"; }
udevadm() { echo "udevadm $*" >> "$TMP/log"; }
systemctl() { echo "systemctl $*" >> "$TMP/log"; }
confirm() { return 0; }

# 1. No pwm-fan: nothing is written.
out="$(host_fan 2>&1)" || fail_test "host_fan failed without a fan: $out"
grep -q "no pwm-fan" <<<"$out" || fail_test "missing fan not reported: $out"
[[ ! -e "$K2OH_HOST_FAN_RULE" ]] || fail_test "rule written without a fan"

# 2. A CM5-like sysfs.
mkdir -p "$TMP/sys/class/hwmon/hwmon0" "$TMP/sys/class/hwmon/hwmon2" "$TMP/sys/class/thermal/thermal_zone0"
echo cpu_thermal > "$TMP/sys/class/hwmon/hwmon0/name"
echo pwmfan > "$TMP/sys/class/hwmon/hwmon2/name"
echo 75 > "$TMP/sys/class/hwmon/hwmon2/pwm1"
echo cpu-thermal > "$TMP/sys/class/thermal/thermal_zone0/type"
echo enabled > "$TMP/sys/class/thermal/thermal_zone0/mode"
out="$(host_fan 2>&1)" || fail_test "host_fan failed: $out"
group="$(id -gn)"
grep -q "ATTR{name}==\"pwmfan\", RUN+=\"/bin/chgrp $group /sys%p/pwm1\"" "$K2OH_HOST_FAN_RULE" || fail_test "hwmon rule: $(cat "$K2OH_HOST_FAN_RULE")"
grep -q "ATTR{type}==\"cpu-thermal\", RUN+=\"/bin/chgrp $group /sys%p/mode\", RUN+=\"/bin/chmod g+w /sys%p/mode\"" "$K2OH_HOST_FAN_RULE" || fail_test "thermal rule"
grep -q '^\[Service\]$' "$K2OH_HOST_FAN_DROPIN" || fail_test "no [Service] in the drop-in"
grep -qF 'ExecStopPost=-/bin/sh -c '"'"'for z in /sys/class/thermal/thermal_zone*; do [ "$$(cat $$z/type)" = cpu-thermal ] && echo enabled > $$z/mode; done; true'"'" "$K2OH_HOST_FAN_DROPIN" \
    || fail_test "drop-in: $(cat "$K2OH_HOST_FAN_DROPIN")"
grep -q "udevadm control --reload-rules" "$TMP/log" || fail_test "udev rules not reloaded"
grep -q "udevadm trigger --action=change --subsystem-match=hwmon --subsystem-match=thermal" "$TMP/log" || fail_test "udev not triggered"
grep -q "systemctl daemon-reload" "$TMP/log" || fail_test "no daemon-reload"
grep -q "systemctl restart" "$TMP/log" && fail_test "Klipper restarted by the installer"
grep -q "Klipper can drive the fan" <<<"$out" || fail_test "writable fan not reported: $out"
[[ -f "$PRINTER_DATA/config/macros/host_fan.cfg" ]] || fail_test "host_fan.cfg not installed"
grep -q '^\[include macros/host_fan.cfg\]' "$PRINTER_DATA/config/printer.cfg" || fail_test "include not added"
inc=$(grep -n '^\[include macros/host_fan.cfg\]' "$PRINTER_DATA/config/printer.cfg" | cut -d: -f1)
ovr=$(grep -n '^\[include macros/overrides.cfg\]' "$PRINTER_DATA/config/printer.cfg" | cut -d: -f1)
(( inc < ovr )) || fail_test "include not before overrides.cfg"
grep -q "Restart Klipper to apply, not during a print" <<<"$out" || fail_test "no restart hint"

# 3. A second run keeps the user's file and adds no second include.
echo "# mine" >> "$PRINTER_DATA/config/macros/host_fan.cfg"
out="$(host_fan 2>&1)" || fail_test "second run failed: $out"
grep -q "# mine" "$PRINTER_DATA/config/macros/host_fan.cfg" || fail_test "user's host_fan.cfg replaced"
[[ "$(grep -c '^\[include macros/host_fan.cfg\]' "$PRINTER_DATA/config/printer.cfg")" == 1 ]] || fail_test "include duplicated"

# 4. Kalico without host_fan: refused.
rm "$KLIPPER_DIR/klippy/extras/host_fan.py"
if out="$(host_fan 2>&1)"; then fail_test "host_fan ran without the Kalico module"; fi
grep -q "update Kalico first" <<<"$out" || fail_test "old Kalico not reported: $out"

echo "host-fan tests passed"
