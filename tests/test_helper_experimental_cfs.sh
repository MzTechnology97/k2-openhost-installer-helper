#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" K2OH_HELPER_LIB_ONLY=1 HELPER_DIR="$ROOT"
mkdir -p "$HOME"
# shellcheck source=/dev/null
source "$ROOT/helper.sh"

fail_test() { echo "FAIL: $*" >&2; exit 1; }
FW_DIR="$TMP/fw"
mkdir -p "$FW_DIR"
IMAGE="$FW_DIR/cfs0_050_G32-cfs0_000_153-rfid-diag-ro-v2_1.bin"
printf 'experimental-menu-fixture' > "$IMAGE"
SHA="$(sha256sum "$IMAGE" | awk '{print $1}')"
cat > "$FW_DIR/manifest.json" <<JSON
{
  "schema": 1,
  "candidates": [
    {
      "id": "fixture",
      "filename": "$(basename "$IMAGE")",
      "sha256": "$SHA",
      "hardware": "cfs0_050_G32",
      "application": "cfs0_000_153",
      "description": "Fixture candidate"
    }
  ]
}
JSON
CUSTOM_CFS_DIR="$FW_DIR"
CUSTOM_CFS_MANIFEST="$FW_DIR/manifest.json"

# Exact acknowledgement must invoke the guarded t113 apply path with the
# manifest SHA and the standard custom-image arguments.
CALLED="$TMP/called"
run() { printf '%s\n' "$*" > "$CALLED"; }
# Unit fixture: do not query or write the actual attached printer.
SAVED_EXPERIMENTAL_IDLE_GUARD="$(declare -f experimental_cfs_require_idle)"
experimental_cfs_require_idle() { :; }
experimental_cfs_menu <<< "FLASH EXPERIMENTAL CFS" > "$TMP/out-ok" 2>&1
[[ -f "$CALLED" ]] || fail_test "correct acknowledgement did not invoke t113 helper"
grep -Fq "t113.sh mcu-fw apply --cfs --cfs-image $IMAGE --cfs-sha256 $SHA" "$CALLED" \
    || fail_test "wrong t113 custom-CFS invocation"
grep -Fq "EXPERIMENTAL FIRMWARE DISCLAIMER" "$TMP/out-ok" \
    || fail_test "disclaimer not shown"
grep -Fq "cfs0_050_G32" "$TMP/out-ok" || fail_test "hardware target missing from disclaimer"
grep -Fq "cfs0_000_153" "$TMP/out-ok" || fail_test "application target missing from disclaimer"

# A wrong phrase must cancel, even if global --yes/unattended mode is enabled.
rm -f "$CALLED"
ASSUME_YES=1
experimental_cfs_menu <<< "yes" > "$TMP/out-no" 2>&1
[[ ! -e "$CALLED" ]] || fail_test "--yes bypassed experimental acknowledgement"
grep -Fq "cancelled" "$TMP/out-no" || fail_test "cancellation not reported"
ASSUME_YES=0

# Hash mismatch must fail before the t113 helper can be invoked.
rm -f "$CALLED"
python3 - "$CUSTOM_CFS_MANIFEST" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['candidates'][0]['sha256']='0'*64
json.dump(d, open(p,'w'), indent=2)
PY
(
  experimental_cfs_menu <<< "FLASH EXPERIMENTAL CFS"
) > "$TMP/out-badhash" 2>&1 && fail_test "bad SHA accepted"
[[ ! -e "$CALLED" ]] || fail_test "t113 helper invoked after bad SHA"

# Manifest identity must agree with the filename.
python3 - "$CUSTOM_CFS_MANIFEST" "$SHA" <<'PY'
import json, sys
p,sha=sys.argv[1:]
d=json.load(open(p))
d['candidates'][0]['sha256']=sha
d['candidates'][0]['hardware']='cfs0_050_G30'
json.dump(d, open(p,'w'), indent=2)
PY
(
  experimental_cfs_menu <<< "FLASH EXPERIMENTAL CFS"
) > "$TMP/out-badid" 2>&1 && fail_test "manifest/filename identity mismatch accepted"
[[ ! -e "$CALLED" ]] || fail_test "t113 helper invoked with mismatched identity"

# Test the actual guard with a mock HTTP response (no CM5 request).
eval "$SAVED_EXPERIMENTAL_IDLE_GUARD"
curl() {
    printf '%s\n' '{"result":{"status":{"print_stats":{"state":"standby"},"box":{"state":"IDLE","operation":{"active":false}}}}}'
}
experimental_cfs_require_idle || fail_test "idle state should allow supervised flashing"
curl() {
    printf '%s\n' '{"result":{"status":{"print_stats":{"state":"printing"},"box":{"state":"PRINT","operation":{"active":true}}}}}'
}
( experimental_cfs_require_idle ) > "$TMP/out-printing" 2>&1 && fail_test "active print accepted by flash interlock"
grep -Fq "Unsafe CFS flash state" "$TMP/out-printing" || fail_test "missing active-print failure"
curl() { return 22; }
( experimental_cfs_require_idle ) > "$TMP/out-down" 2>&1 && fail_test "unreachable Moonraker allowed flash"
grep -Fq "Cannot prove" "$TMP/out-down" || fail_test "missing fail-closed response"

# Validate the shipped menu order and exact files, independently of the mock menu.
python3 - "$ROOT/firmware/custom-cfs" <<'CATALOG'
import pathlib,json,hashlib,sys
p=pathlib.Path(sys.argv[1]);rows=json.loads((p/'manifest.json').read_text())['candidates']
assert len(rows)==2
assert 'R3-CANDIDATE' in rows[0]['filename'] and 'RDG2.bin' in rows[1]['filename']
for row in rows:
    assert hashlib.sha256((p/row['filename']).read_bytes()).hexdigest()==row['sha256']
assert rows[0]['sha256']==json.loads((p/'SGF1-RH1-R3-firmware-manifest.json').read_text())['sha256']
CATALOG
echo "experimental CFS menu tests: PASS"
