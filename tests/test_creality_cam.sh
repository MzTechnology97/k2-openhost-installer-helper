#!/usr/bin/env bash
# creality-cam: the [cam] section that uses the Creality CAM gets max_fps 25
# and the controls in v4l2ctl; other cams, comments and a user's own v4l2ctl
# are kept; a second run changes nothing; no matching section is reported.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail_test() { echo "FAIL: $*" >&2; exit 1; }
EDIT="$ROOT/files/camera/crowsnest_creality_cam.py"

mkdir -p "$TMP/dev/v4l/by-id" "$TMP/home/printer_data/config"
touch "$TMP/dev/video0" "$TMP/dev/video2"
CAM="$TMP/dev/v4l/by-id/usb-Creality_3D_Technology_CREALITY_CAM_X-video-index0"
ln -s "$TMP/dev/video0" "$CAM"
CONF="$TMP/home/printer_data/config/crowsnest.conf"

write_default() {
    cat > "$CONF" <<EOF
[crowsnest]
log_path: /tmp/crowsnest.log
log_level: verbose                      # Valid Options are quiet/verbose/debug

[cam 1]
mode: ustreamer                         # ustreamer - Provides MJPG and snapshots.
port: 8080                              # HTTP/MJPG stream/snapshot port
device: $TMP/dev/video0                     # See log for available devices
resolution: 640x480                     # <width>x<height> format
max_fps: 15                             # If hardware supports it, it will be forced.

[cam nozzle]
mode: ustreamer
port: 8081
device: $TMP/dev/video2
resolution: 640x480
max_fps: 30
EOF
}
value() { # value <section> <option>
    awk -v s="[$1]" -v o="$2" '
        /^\[/ { in_s = ($0 == s) }
        in_s && $0 ~ "^" o ":" { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print }' "$CONF"
}

# 1. Crowsnest's default file, the camera on /dev/video0: cam 1 is set up.
write_default
out="$(python3 "$EDIT" "$CONF" "$CAM")" || fail_test "edit failed: $out"
[[ "$(value "cam 1" max_fps)" == 25 ]] || fail_test "max_fps not 25"
[[ "$(value "cam 1" resolution)" == 1920x1080 ]] || fail_test "default resolution not raised"
grep -q "^v4l2ctl: brightness=128,.*auto_exposure=3 " "$CONF" || fail_test "v4l2ctl not added"
[[ "$(value "cam 1" device)" == "$TMP/dev/video0" ]] || fail_test "device changed"
grep -q "^mode: ustreamer                         # ustreamer - Provides" "$CONF" || fail_test "comment lost"
# The other camera is left alone.
[[ "$(value "cam nozzle" max_fps)" == 30 ]] || fail_test "nozzle max_fps changed"
[[ "$(awk '/^\[cam nozzle\]/{f=1} f && /^v4l2ctl:/' "$CONF")" == "" ]] || fail_test "nozzle got v4l2ctl"
[[ "$(grep -c '^v4l2ctl:' "$CONF")" == 1 ]] || fail_test "v4l2ctl added more than once"
ls "$CONF".k2oh-*.bak >/dev/null 2>&1 || fail_test "no backup"

# 2. A second run changes nothing.
cp "$CONF" "$TMP/first"
out="$(python3 "$EDIT" "$CONF" "$CAM")" || fail_test "second run failed: $out"
grep -q "already set" <<<"$out" || fail_test "second run not idempotent: $out"
cmp -s "$CONF" "$TMP/first" || fail_test "second run changed the file"

# 3. The user's own v4l2ctl and resolution are kept; manual exposure is flagged.
cat > "$CONF" <<EOF
[cam chamber]
device: $CAM
resolution: 1280x720
max_fps: 30 # set by hand
v4l2ctl: brightness=150,auto_exposure=1
EOF
out="$(python3 "$EDIT" "$CONF" "$CAM")" || fail_test "edit failed: $out"
[[ "$(value "cam chamber" max_fps)" == 25 ]] || fail_test "30 fps not lowered"
[[ "$(value "cam chamber" resolution)" == 1280x720 ]] || fail_test "user resolution changed"
[[ "$(value "cam chamber" v4l2ctl)" == "brightness=150,auto_exposure=1" ]] || fail_test "user v4l2ctl changed"
grep -q "WARNING: .*manual exposure" <<<"$out" || fail_test "manual exposure not flagged: $out"

# 4. No section on the camera: status 3, file untouched.
write_default
sed -i "s#device: $TMP/dev/video0 #device: $TMP/dev/video2 #" "$CONF"
cp "$CONF" "$TMP/before"
rc=0; out="$(python3 "$EDIT" "$CONF" "$CAM")" || rc=$?
[[ "$rc" == 3 ]] || fail_test "expected status 3, got $rc: $out"
cmp -s "$CONF" "$TMP/before" || fail_test "file changed without a matching section"

# 5. Through the helper: './helper.sh install creality-cam' path.
write_default
export HOME="$TMP/home" HELPER_DIR="$ROOT" K2OH_GATE_DROPIN="$TMP/no-gate.conf"
export PRINTER_DATA="$TMP/home/printer_data" K2OH_EXTRAS_LIB_ONLY=1
export K2OH_CREALITY_CAM_GLOB="$TMP/dev/v4l/by-id/usb-Creality_3D_Technology_CREALITY_CAM_*-video-index0"
# shellcheck source=/dev/null
source "$ROOT/scripts/extras.sh"
out="$(creality_cam 2>&1)" || fail_test "creality_cam failed: $out"
[[ "$(value "cam 1" max_fps)" == 25 ]] || fail_test "helper did not set max_fps: $out"
grep -q "reboot the host" <<<"$out" || fail_test "no reboot hint: $out"
# Camera not connected: nothing changes.
write_default
cp "$CONF" "$TMP/before"
K2OH_CREALITY_CAM_GLOB="$TMP/none/*" CREALITY_CAM_GLOB="$TMP/none/*"
out="$(creality_cam 2>&1)" || fail_test "creality_cam failed without camera: $out"
grep -q "not connected" <<<"$out" || fail_test "missing camera not reported: $out"
cmp -s "$CONF" "$TMP/before" || fail_test "file changed without the camera"

echo "creality-cam tests passed"
