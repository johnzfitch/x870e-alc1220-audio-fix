#!/bin/bash
# Check current ALC1220 audio configuration

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

show_value() {
    amixer -c "$CARD" cget "$1" 2>/dev/null | sed -n "s/^  : values=/  /p"
}

if ! CARD="$(find_alc1220_card)"; then
    echo "ERROR: Realtek ALC1220 not found"
    echo "Available sound cards:"
    cat /proc/asound/cards
    exit 1
fi

echo "=== ALC1220 Audio Status (Card $CARD) ==="
echo

echo "Sound Card:"
cat /proc/asound/card${CARD}/codec* 2>/dev/null | grep -E "^Codec:" || echo "Card $CARD not found"
echo

echo "Auto-Mute Mode:"
show_value "iface=MIXER,name='Auto-Mute Mode'"
echo

echo "Line Out Playback Switch:"
show_value "iface=MIXER,name='Line Out Playback Switch'"
echo

echo "Headphone Playback Switch:"
show_value "iface=MIXER,name='Headphone Playback Switch'"
echo

echo "Master Volume:"
amixer -c "$CARD" sget Master 2>/dev/null | grep "Mono:" | sed 's/.*Mono:/  /'
echo

echo "Jack Detection:"
show_value "iface=CARD,name='Front Headphone Jack'" | sed 's/^  /  Front Headphone Jack: /'
show_value "iface=CARD,name='Line Out Jack'" | sed 's/^  /  Line Out Jack: /'
