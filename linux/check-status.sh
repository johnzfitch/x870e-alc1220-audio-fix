#!/bin/bash
# Check current ALC1220 audio configuration

# Auto-detect card number
CARD=""
for i in 0 1 2 3 4; do
    if grep -q "Realtek ALC1220" /proc/asound/card${i}/codec* 2>/dev/null; then
        CARD=$i
        break
    fi
done

if [ -z "$CARD" ]; then
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
amixer -c $CARD cget numid=9 2>/dev/null | grep "values=" | sed 's/.*values=/  /'
echo "  (0=Disabled, 1=Enabled)"
echo

echo "Line Out Playback Switch:"
amixer -c $CARD cget numid=2 2>/dev/null | grep "values=" | sed 's/.*values=/  /'
echo

echo "Headphone Playback Switch:"
amixer -c $CARD cget numid=3 2>/dev/null | grep "values=" | sed 's/.*values=/  /'
echo

echo "Master Volume:"
amixer -c $CARD sget Master 2>/dev/null | grep "Mono:" | sed 's/.*Mono:/  /'
echo

echo "Jack Detection:"
amixer -c $CARD cget numid=24 2>/dev/null | grep "values=" | sed 's/.*values=/  Front Headphone Jack: /'
amixer -c $CARD cget numid=23 2>/dev/null | grep "values=" | sed 's/.*values=/  Line Out Jack: /'
