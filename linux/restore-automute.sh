#!/bin/bash
# Restore default auto-mute behavior
# Speakers will mute when headphones are plugged in

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
    exit 1
fi

echo "Restoring auto-mute (default behavior) on card $CARD..."
amixer -c $CARD cset numid=9 1 > /dev/null

if sudo alsactl store 2>/dev/null; then
    echo "Settings saved."
fi

echo "Auto-mute enabled. Speakers will mute when headphones plugged in."
