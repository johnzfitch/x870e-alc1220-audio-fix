#!/bin/bash
# Phase 2c: Apply gb_x570 coefficient writes manually.
#
# Use after booting with model=generic (Phase 2b). If 2b produced
# silence on the rear output, these coefs may restore it while
# keeping the generic parser's dual-DAC connection lists.
#
# Requires: hda-verb (alsa-tools), root
# Reversible: reboot clears all runtime verb changes

set -euo pipefail

CODEC_NAME="Realtek ALC1220"

die() { echo "FATAL: $*" >&2; exit 1; }

find_alc1220_hwdev() {
    local codec card
    for codec in /proc/asound/card*/codec*; do
        [ -e "$codec" ] || continue
        grep -q "^Codec: ${CODEC_NAME}$" "$codec" 2>/dev/null || continue
        card=${codec%/codec*}; card=${card##*card}
        local dev="/dev/snd/hwC${card}D0"
        [ -c "$dev" ] && printf '%s\n' "$dev" && return 0
    done
    return 1
}

command -v hda-verb &>/dev/null || die "hda-verb not found (pacman -S alsa-tools)"
[ "$(id -u)" -eq 0 ] || die "must run as root"

HWDEV=$(find_alc1220_hwdev) || die "ALC1220 hwdep device not found"
echo "=== Phase 2c: Apply gb_x570 coefficients ==="
echo "Device: $HWDEV"
echo

# gb_x570 coefficient table from patch_realtek.c
# Each pair: SET_COEF_INDEX, then SET_PROC_COEF
COEFS=(
    "0x07 0x03c0"
    "0x1a 0x01c1"
    "0x1b 0x0202"
    "0x43 0x3005"
)

for pair in "${COEFS[@]}"; do
    idx=${pair%% *}
    val=${pair##* }
    echo -n "  COEF $idx <- $val ... "
    hda-verb "$HWDEV" 0x20 0x500 "$idx" >/dev/null 2>&1  # SET_COEF_INDEX
    hda-verb "$HWDEV" 0x20 0x400 "$val" >/dev/null 2>&1  # SET_PROC_COEF
    # Verify
    hda-verb "$HWDEV" 0x20 0x500 "$idx" >/dev/null 2>&1
    readback=$(hda-verb "$HWDEV" 0x20 0xc00 0x0 2>/dev/null | tail -1)
    echo "readback: $readback"
done

echo
echo "Coefs applied. Test audio on both outputs, then run:"
echo "  sudo ./probe.sh > phase2c-results.log"
