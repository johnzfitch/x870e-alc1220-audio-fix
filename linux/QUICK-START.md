# Linux Quick Start Guide

## The Problem
When you plug headphones into the front of your PC, your rear speakers stop working. This guide fixes that so both work at the same time.

---

## Quick Fix (Copy & Paste)

Open a terminal and paste this entire block:

```bash
curl -sL https://raw.githubusercontent.com/johnzfitch/x870e-alc1220-audio-fix/master/linux/fix-audio.sh | bash
```

Or if you downloaded the files:

```bash
cd ~/Downloads/x870e-alc1220-audio-fix-master/linux
chmod +x fix-audio.sh
./fix-audio.sh
```

---

## Step-by-Step Guide

### Step 1: Open a Terminal
- Press `Ctrl + Alt + T` on most Linux systems
- Or search for "Terminal" in your applications menu

### Step 2: Install Required Tools
**Ubuntu/Debian:**
```bash
sudo apt install alsa-utils
```

**Arch Linux:**
```bash
sudo pacman -S alsa-utils
```

**Fedora:**
```bash
sudo dnf install alsa-utils
```

### Step 3: Run the Fix
Copy and paste these commands one at a time:

```bash
# Resolve the Realtek ALC1220 card dynamically
CARD="$(for codec in /proc/asound/card*/codec*; do grep -q '^Codec: Realtek ALC1220$' "$codec" 2>/dev/null && card="${codec%/codec*}" && echo "${card##*card}" && break; done)"
```

Then run:

```bash
# Disable auto-mute
amixer -c "$CARD" cset name='Auto-Mute Mode' Disabled

# Turn on both outputs
amixer -c "$CARD" cset name='Line Out Playback Switch' on,on
amixer -c "$CARD" cset name='Headphone Playback Switch' on,on

# Set volume to max
amixer -c "$CARD" sset Master 100%

# Save settings so they stick after reboot
sudo alsactl store
```

---

## How Do I Know It Worked?

1. Plug headphones into the **front** of your PC
2. Plug speakers into the **green jack** on the **back**
3. Play a video or music
4. You should hear audio from **BOTH** at the same time

To check your settings:
```bash
./check-status.sh
```

You should see:
- Auto-Mute Mode: **0** (disabled)
- Line Out: **on,on**
- Headphone: **on,on**

---

## Undo the Changes

If you want speakers to mute when headphones are plugged in (default behavior), re-run the card lookup if needed, then restore:

```bash
# Re-detect card (skip if $CARD is still set from Step 3)
CARD="$(for codec in /proc/asound/card*/codec*; do grep -q '^Codec: Realtek ALC1220$' "$codec" 2>/dev/null && card="${codec%/codec*}" && echo "${card##*card}" && break; done)"

amixer -c "$CARD" cset name='Auto-Mute Mode' Enabled
sudo alsactl store
```

Or use the restore script: `./restore-automute.sh`

---

## Troubleshooting

### "amixer: command not found"
Install alsa-utils (see Step 2 above)

### Card lookup fails
Run `cat /proc/asound/cards` and confirm your system exposes a card with `Realtek ALC1220` in `/proc/asound/card*/codec*`

### Settings don't survive reboot
Make sure you ran `sudo alsactl store` after making changes

### No sound at all
Make sure your audio profile is set to analog:
```bash
# List your audio cards
pactl list cards short

# Set to analog (replace CARD_NAME with yours)
pactl set-card-profile CARD_NAME output:analog-stereo+input:analog-stereo
```

---

## Need More Help?

Open an issue on GitHub: https://github.com/johnzfitch/x870e-alc1220-audio-fix/issues
