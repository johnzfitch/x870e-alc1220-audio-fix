#!/bin/bash
# Restore default auto-mute behavior
# Speakers will mute when headphones are plugged in

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

if ! CARD="$(find_alc1220_card)"; then
    echo "ERROR: Realtek ALC1220 not found"
    exit 1
fi

echo "Restoring auto-mute (default behavior) on card $CARD..."
amixer -c "$CARD" cset name='Auto-Mute Mode' Enabled > /dev/null

if sudo alsactl store 2>/dev/null; then
    echo "Settings saved."
fi

echo "Auto-mute enabled. Speakers will mute when headphones plugged in."
