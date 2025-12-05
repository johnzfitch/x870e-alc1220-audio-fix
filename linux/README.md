# Linux Audio Fix - Gigabyte X870E ALC1220

Enable simultaneous headphone and speaker output on Gigabyte X870E motherboards.

## Quick Fix

Run the automated script:

```bash
./fix-audio.sh
```

Or manually:

```bash
# Disable auto-mute
amixer -c 2 cset numid=9 0

# Enable both outputs
amixer -c 2 cset numid=2 on,on  # Line Out
amixer -c 2 cset numid=3 on,on  # Headphones

# Set volume
amixer -c 2 sset Master 100%

# Save settings
sudo alsactl store
```

## Requirements

- `alsa-utils` package (for amixer/alsactl)
- Realtek ALC1220 codec (card 2 by default)

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
amixer -c 2 cget numid=9
# Should show: values=0

# Check outputs enabled
amixer -c 2 cget numid=2  # Line Out: on,on
amixer -c 2 cget numid=3  # Headphone: on,on
```

## PipeWire/PulseAudio

Ensure analog profile is active:

```bash
pactl set-card-profile alsa_card.pci-0000_7a_00.6 "output:analog-stereo+input:analog-stereo"
```

## Visual Mixer

```bash
alsamixer -c 2
```

## Troubleshooting

### Wrong Card Number

Find your ALC1220 card:
```bash
cat /proc/asound/cards | grep -i realtek
```

Edit scripts to use correct card number if not 2.

### Settings Lost After Reboot

Ensure alsa-restore service runs:
```bash
systemctl status alsa-restore.service
```

Or manually restore:
```bash
sudo alsactl restore
```
