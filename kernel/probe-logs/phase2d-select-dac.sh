#!/bin/bash
# Phase 2d: Force node 0x1b to mixer 0x0d (DAC 0x03) via connection select.
#
# Use if Phase 2b's generic parser didn't auto-split outputs.
# This manually switches the rear line-out from DAC 0x02 to DAC 0x03.
#
# Requires: hda-verb (alsa-tools), root
# Reversible: reboot, or run with --restore to switch back to 0x0c

set -euo pipefail

CODEC_NAME="Realtek ALC1220"
NID_LINEOUT="0x1b"

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

# Node 0x1b hardware connection list (from codec silicon):
#   Index 0 = 0x0c (mixer for DAC 0x02) — current, shared with 0x14
#   Index 1 = 0x0d (mixer for DAC 0x03) — target for dual-DAC
#   Index 2 = 0x0e (mixer for DAC 0x04)
#   Index 3 = 0x0f (mixer for DAC 0x05)
#   Index 4 = 0x26 (mixer for DAC 0x25)

if [ "${1:-}" = "--restore" ]; then
    echo "=== Phase 2d: Restore 0x1b -> 0x0c (DAC 0x02, shared) ==="
    echo "Device: $HWDEV"
    echo
    # SET_CONNECT_SELECT (verb 0x701) on NID 0x1b, index 0 = mixer 0x0c
    hda-verb "$HWDEV" "$NID_LINEOUT" 0x701 0x00 >/dev/null 2>&1
    sel=$(hda-verb "$HWDEV" "$NID_LINEOUT" 0xf01 0x0 2>/dev/null | tail -1)
    echo "  0x1b connection select: $sel (should be 0x0 = mixer 0x0c)"
    echo "  Restored to shared-DAC configuration."
    exit 0
fi

echo "=== Phase 2d: Force 0x1b -> 0x0d (DAC 0x03, independent) ==="
echo "Device: $HWDEV"
echo

# Read current selection
cur=$(hda-verb "$HWDEV" "$NID_LINEOUT" 0xf01 0x0 2>/dev/null | tail -1)
echo "  Current connection select: $cur"

# SET_CONNECT_SELECT (verb 0x701) on NID 0x1b, index 1 = mixer 0x0d
echo "  Setting connection select to index 1 (mixer 0x0d -> DAC 0x03)..."
hda-verb "$HWDEV" "$NID_LINEOUT" 0x701 0x01 >/dev/null 2>&1

# Verify
sel=$(hda-verb "$HWDEV" "$NID_LINEOUT" 0xf01 0x0 2>/dev/null | tail -1)
echo "  New connection select: $sel (should be 0x1 = mixer 0x0d)"
echo

# Check if DAC 0x03 has a stream assigned
echo "  Checking DAC 0x03 stream state..."
CODEC_FILE=$(ls /proc/asound/card*/codec* 2>/dev/null | grep "$(echo "$HWDEV" | grep -oP 'C\Kd+')" | head -1)
if [ -n "$CODEC_FILE" ]; then
    dac03=$(sed -n '/^Node 0x03/,/^Node/{/Converter:/p}' "$CODEC_FILE" | head -1)
    echo "  DAC 0x03: $dac03"
fi

echo
echo "Connection select changed. The kernel's generic parser may need"
echo "to re-enumerate to assign a stream to DAC 0x03."
echo
echo "Test: play audio and check if rear output works."
echo "  speaker-test -c2 -D hw:$(echo "$HWDEV" | grep -oP 'C\K[0-9]+'),0 -t wav"
echo
echo "Then capture state:"
echo "  sudo ./probe.sh > phase2d-results.log"
echo
echo "Restore with: sudo $0 --restore"
