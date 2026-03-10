# Linux Audio Fix - Gigabyte X870E ALC1220

Enable simultaneous headphone and speaker output on Gigabyte X870E motherboards.

## Quick Fix

Run the automated script:

```bash
./fix-audio.sh
```

Or manually:

```bash
# Resolve the Realtek ALC1220 card dynamically
CARD="$(for codec in /proc/asound/card*/codec*; do grep -q '^Codec: Realtek ALC1220$' "$codec" 2>/dev/null && card="${codec%/codec*}" && echo "${card##*card}" && break; done)"

# Disable auto-mute
amixer -c "$CARD" cset name='Auto-Mute Mode' Disabled

# Enable both outputs
amixer -c "$CARD" cset name='Line Out Playback Switch' on,on
amixer -c "$CARD" cset name='Headphone Playback Switch' on,on

# Set volume
amixer -c "$CARD" sset Master 100%

# Save settings
sudo alsactl store
```

## Requirements

- `alsa-utils` package (for amixer/alsactl)
- Realtek ALC1220 codec (card number varies by system)

Install on Arch Linux:
```bash
sudo pacman -S alsa-utils
```

Install on Ubuntu/Debian:
```bash
sudo apt install alsa-utils
```

## Files

| File | Description |
|------|-------------|
| `fix-audio.sh` | Automated fix script |
| `restore-automute.sh` | Restore default auto-mute behavior |
| `check-status.sh` | Check current audio configuration |

## Verify Fix

```bash
# Check auto-mute is disabled
amixer -c "$CARD" cget name='Auto-Mute Mode'
# Should show: values=0

# Check outputs enabled
amixer -c "$CARD" cget name='Line Out Playback Switch'
amixer -c "$CARD" cget name='Headphone Playback Switch'
```

## PipeWire/PulseAudio

Ensure analog profile is active:

```bash
pactl set-card-profile alsa_card.pci-0000_7a_00.6 "output:analog-stereo+input:analog-stereo"
```

## Visual Mixer

```bash
alsamixer -c "$CARD"
```

## Troubleshooting

### Wrong Card Number

Find your ALC1220 card:
```bash
for codec in /proc/asound/card*/codec*; do
  grep -H '^Codec: Realtek ALC1220$' "$codec"
done
```

Use the detected `CARD` value in the manual `amixer` commands. `fix-audio.sh` auto-detects the ALC1220 card and addresses the controls by name.

### Settings Lost After Reboot

Ensure alsa-restore service runs:
```bash
systemctl status alsa-restore.service
```

Or manually restore:
```bash
sudo alsactl restore
```
