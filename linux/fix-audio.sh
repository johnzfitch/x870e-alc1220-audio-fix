#!/bin/bash
# Gigabyte X870E ALC1220 Audio Fix
# Enables simultaneous headphone and speaker output

set -euo pipefail

find_alc1220_card() {
    local codec card

    for codec in /proc/asound/card*/codec*; do
        [ -e "$codec" ] || continue

        if ! grep -q "^Codec: Realtek ALC1220$" "$codec" 2>/dev/null; then
            continue
        fi

        card=${codec%/codec*}
        card=${card##*card}

        local controls
        controls="$(amixer -c "$card" controls 2>/dev/null)" || continue
        if echo "$controls" | grep -q "name='Line Out Playback Switch'" &&
           echo "$controls" | grep -q "name='Headphone Playback Switch'" &&
           echo "$controls" | grep -q "name='Auto-Mute Mode'"; then
            printf '%s\n' "$card"
            return 0
        fi
    done

    return 1
}

echo "=== Gigabyte X870E ALC1220 Audio Fix ==="
echo

if ! CARD="$(find_alc1220_card)"; then
    echo "ERROR: Could not find a Realtek ALC1220 card with Line Out, Headphone, and Auto-Mute controls."
    echo "Available sound cards:"
    cat /proc/asound/cards
    exit 1
fi

echo "Using sound card: $CARD"
echo

# Disable auto-mute
echo "[1/4] Disabling auto-mute..."
amixer -c "$CARD" cset name='Auto-Mute Mode' Disabled > /dev/null
echo "      Auto-mute: DISABLED"

# Enable line out
echo "[2/4] Enabling line out (rear speakers)..."
amixer -c "$CARD" cset name='Line Out Playback Switch' on,on > /dev/null
echo "      Line Out: ON"

# Enable headphones
echo "[3/4] Enabling headphones (front panel)..."
amixer -c "$CARD" cset name='Headphone Playback Switch' on,on > /dev/null
echo "      Headphones: ON"

# Set volume
echo "[4/4] Setting volume to 100%..."
amixer -c "$CARD" sset Master 100% > /dev/null
amixer -c "$CARD" sset 'Headphone+LO' 100% > /dev/null 2>&1 || true
echo "      Volume: 100%"

echo
echo "=== Saving settings ==="
if sudo alsactl store 2>/dev/null; then
    echo "Settings saved to /var/lib/alsa/asound.state"
else
    echo "Warning: Could not save settings (run with sudo for persistence)"
fi

echo
echo "=== Done ==="
echo "Both headphones and speakers should now output audio simultaneously."
