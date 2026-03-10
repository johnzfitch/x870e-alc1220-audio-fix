#!/bin/bash
# Universal ALC1220 state capture for dual-DAC routing phases.
# Writes structured output to stdout; redirect to a log file per phase.
#
# Usage:
#   sudo ./probe.sh > phase2b-results.log
#   sudo ./probe.sh > phase2c-results.log
#   ...

set -euo pipefail

CODEC_NAME="Realtek ALC1220"

die() { echo "FATAL: $*" >&2; exit 1; }

# --- Detect card ---

find_alc1220() {
    local codec card
    for codec in /proc/asound/card*/codec*; do
        [ -e "$codec" ] || continue
        grep -q "^Codec: ${CODEC_NAME}$" "$codec" 2>/dev/null || continue
        card=${codec%/codec*}; card=${card##*card}
        printf '%s\n' "$card"
        return 0
    done
    return 1
}

CARD=$(find_alc1220) || die "ALC1220 not found in /proc/asound"
HWDEV="/dev/snd/hwC${CARD}D0"
CODEC_FILE=$(ls /proc/asound/card${CARD}/codec* 2>/dev/null | head -1)
[ -r "$CODEC_FILE" ] || die "Cannot read $CODEC_FILE"
[ -c "$HWDEV" ] || die "hwdep device $HWDEV not found (need root?)"

header() {
    echo "=============================================================================="
    echo "$1"
    echo "=============================================================================="
}

# --- Begin capture ---

header "ALC1220 State Capture — $(date -Iseconds)"
echo "Card:       $CARD"
echo "hwdep:      $HWDEV"
echo "Codec file: $CODEC_FILE"
echo "Kernel:     $(uname -r)"
echo "Model:      $(cat /sys/module/snd_hda_codec_realtek/parameters/model 2>/dev/null || echo '(default)')"
echo

# --- 1. Codec identity ---

header "1. CODEC IDENTITY"
head -6 "$CODEC_FILE"
echo

# --- 2. Pin 0x14 (Front HP) ---

header "2. PIN 0x14 — FRONT HEADPHONE"
sed -n '/^Node 0x14/,/^Node 0x/{ /^Node 0x14/p; /^Node 0x[^1]/!{ /^Node 0x14/!p; }; }' "$CODEC_FILE"
echo

# --- 3. Pin 0x1b (Rear Line-Out) ---

header "3. PIN 0x1b — REAR LINE-OUT"
sed -n '/^Node 0x1b/,/^Node 0x/{ /^Node 0x1b/p; /^Node 0x[^1]/!{ /^Node 0x1b/!p; }; }' "$CODEC_FILE"
echo

# --- 4. Connection lists (critical for dual-DAC) ---

header "4. CONNECTION LISTS"
for nid in 0x14 0x1b; do
    echo "--- Node $nid ---"
    grep -A2 "^Node $nid" "$CODEC_FILE" | grep -i "connection"
    # Read live connection select via GET_CONNECT_SELECT (0xf01)
    sel=$(hda-verb "$HWDEV" "$nid" 0xf01 0x0 2>/dev/null | tail -1) || sel="(read failed)"
    echo "  Live connection select: $sel"
    echo
done

# --- 5. DAC stream assignments ---

header "5. DAC STREAM ASSIGNMENTS"
for dac in 0x02 0x03 0x04 0x05 0x25; do
    echo -n "DAC $dac: "
    sed -n "/^Node $dac/,/^Node/{/Converter:/p}" "$CODEC_FILE" | head -1
done
echo

# --- 6. Coefficient registers ---

header "6. COEFFICIENT REGISTERS"
for idx in 0x07 0x1a 0x1b 0x43; do
    hda-verb "$HWDEV" 0x20 0x500 "$idx" >/dev/null 2>&1
    val=$(hda-verb "$HWDEV" 0x20 0xc00 0x0 2>/dev/null | tail -1)
    echo "  COEF $idx = $val"
done
echo

# --- 7. PCM playback devices ---

header "7. PCM PLAYBACK DEVICES"
for pcm in /proc/asound/card${CARD}/pcm*p/info; do
    [ -e "$pcm" ] || continue
    echo "--- $pcm ---"
    cat "$pcm"
    echo
done

# --- 8. ALSA controls ---

header "8. ALSA CONTROLS (output-related)"
for ctl in 'Auto-Mute Mode' 'Line Out Playback Switch' 'Headphone Playback Switch' \
           'Master Playback Volume' 'Headphone+LO Playback Volume'; do
    val=$(amixer -c "$CARD" cget "iface=MIXER,name='$ctl'" 2>/dev/null | sed -n 's/^  : values=//p') || val="(not found)"
    printf "  %-40s %s\n" "$ctl" "$val"
done
echo

# --- 9. PipeWire sinks ---

header "9. PIPEWIRE SINKS"
if command -v pactl &>/dev/null; then
    pactl list sinks short 2>/dev/null | grep -i "pci-0000_7a_00.6\|Generic_1\|alc1220" || echo "  (no matching sinks)"
    echo
    echo "All sinks:"
    pactl list sinks short 2>/dev/null || echo "  (pactl failed)"
else
    echo "  pactl not available"
fi
echo

# --- 10. Dual-DAC verdict ---

header "10. DUAL-DAC VERDICT"

# Count analog playback PCMs
pcm_count=0
for pcm in /proc/asound/card${CARD}/pcm*p/info; do
    [ -e "$pcm" ] || continue
    grep -q "ANALOG" "$pcm" 2>/dev/null || grep -q "name: ALC1220 Analog" "$pcm" 2>/dev/null && pcm_count=$((pcm_count + 1))
done
echo "  Analog playback PCMs: $pcm_count"

# Check 0x1b in-driver connection count
conn_line=$(grep -A1 "^Node 0x1b" "$CODEC_FILE" | grep "In-driver Connection" || true)
if [ -n "$conn_line" ]; then
    in_driver_count=$(echo "$conn_line" | grep -oP 'In-driver Connection: \K\d+')
    echo "  Node 0x1b in-driver connections: $in_driver_count (1=restricted, >1=open)"
else
    hw_conn=$(grep -A1 "^Node 0x1b" "$CODEC_FILE" | grep "Connection:" | head -1)
    echo "  Node 0x1b connections: $hw_conn (no in-driver override)"
fi

# Check DAC 0x03 stream assignment
dac03_stream=$(sed -n '/^Node 0x03/,/^Node/{/Converter:/p}' "$CODEC_FILE" | head -1)
if echo "$dac03_stream" | grep -q "stream=0"; then
    echo "  DAC 0x03: idle (no stream assigned)"
else
    echo "  DAC 0x03: ACTIVE — $dac03_stream"
fi

# Count PipeWire sinks for this card
pw_count=$(pactl list sinks short 2>/dev/null | grep -c "pci-0000_7a_00.6" || true)
echo "  PipeWire sinks for ALC1220: $pw_count"

echo
if [ "$pcm_count" -ge 2 ] && [ "$pw_count" -ge 2 ]; then
    echo "  RESULT: DUAL-DAC ACTIVE — two analog PCMs, two PipeWire sinks"
elif [ "$pcm_count" -ge 2 ]; then
    echo "  RESULT: DUAL-PCM (kernel sees two outputs, PipeWire may need UCM profile)"
elif grep -q "In-driver Connection: 1" "$CODEC_FILE" 2>/dev/null; then
    echo "  RESULT: SINGLE-DAC (0x1b restricted to {0x0c} by fixup)"
else
    echo "  RESULT: SINGLE-PCM (parser did not split outputs — may need Phase 2d)"
fi
echo
