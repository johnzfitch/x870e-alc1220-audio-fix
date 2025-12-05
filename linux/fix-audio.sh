#!/bin/bash
# Gigabyte X870E ALC1220 Audio Fix
# Enables simultaneous headphone and speaker output

set -e

CARD=2

echo "=== Gigabyte X870E ALC1220 Audio Fix ==="
echo

# Check if card exists
if ! grep -q "Realtek ALC1220" /proc/asound/card${CARD}/codec* 2>/dev/null; then
    echo "Warning: ALC1220 not found on card $CARD"
    echo "Searching for correct card..."
    for i in 0 1 2 3 4; do
        if grep -q "Realtek ALC1220" /proc/asound/card${i}/codec* 2>/dev/null; then
            CARD=$i
            echo "Found ALC1220 on card $CARD"
            break
        fi
    done
fi

echo "Using sound card: $CARD"
echo

# Disable auto-mute
echo "[1/4] Disabling auto-mute..."
amixer -c $CARD cset numid=9 0 > /dev/null
echo "      Auto-mute: DISABLED"

# Enable line out
echo "[2/4] Enabling line out (rear speakers)..."
amixer -c $CARD cset numid=2 on,on > /dev/null
echo "      Line Out: ON"

# Enable headphones
echo "[3/4] Enabling headphones (front panel)..."
amixer -c $CARD cset numid=3 on,on > /dev/null
echo "      Headphones: ON"

# Set volume
echo "[4/4] Setting volume to 100%..."
amixer -c $CARD sset Master 100% > /dev/null
amixer -c $CARD sset 'Headphone+LO' 100% > /dev/null 2>&1 || true
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
