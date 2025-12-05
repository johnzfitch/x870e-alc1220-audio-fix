# <img src=".github/assets/icons/sound.png" width="28" height="28"> Realtek ALC1220 Audio Fix

**Use headphones AND speakers at the same time on your Gigabyte X870E motherboard.**

---

## <img src=".github/assets/icons/tick.png" width="24" height="24"> Quick Start (New Users Start Here)

| Platform | Guide |
|----------|-------|
| <img src=".github/assets/icons/windows.png" width="20" height="20"> **Windows** | [Windows Quick Start Guide](windows/QUICK-START.md) |
| <img src=".github/assets/icons/linux.png" width="20" height="20"> **Linux** | [Linux Quick Start Guide](linux/QUICK-START.md) |

---

## The Problem

On Gigabyte X870E motherboards with Realtek ALC1220, plugging headphones into the front panel jack automatically mutes the rear speaker/line-out (auto-mute feature). Users cannot use both outputs simultaneously or independently route audio to each.

```
Front Headphone Jack → Audio plays
Rear Line Out → MUTED (auto-mute enabled by default)
```

## Solution

Disable the auto-mute feature in ALSA and enable both output switches.

### Linux Quick Fix

```bash
# Disable auto-mute (numid=9: 0=disabled, 1=enabled)
amixer -c 2 cset numid=9 0

# Enable both outputs
amixer -c 2 cset numid=2 on,on  # Line Out
amixer -c 2 cset numid=3 on,on  # Headphones

# Set volume
amixer -c 2 sset Master 100%

# Save settings (persists after reboot)
sudo alsactl store
```

### Windows Quick Fix

1. Open **Realtek HD Audio Manager**
2. Go to **Device Advanced Settings**
3. Check: **"Make front and rear output devices playback two different audio streams simultaneously"**
4. Or uncheck: **"Mute the rear output device, when a front headphone plugged in"**

---

## Documentation

| File | Description |
|------|-------------|
| [linux/README.md](linux/README.md) | Detailed Linux setup guide |
| [windows/README.md](windows/README.md) | Detailed Windows setup guide |
| [linux/fix-audio.sh](linux/fix-audio.sh) | Linux fix script |

---

## Current State

| Item | Status |
|------|--------|
| Front Headphones | Working |
| Rear Line Out (Speakers) | Working |
| Simultaneous Output | Working |
| Auto-mute | Disabled |
| Settings Persistence | Saved via alsactl |

---

## Technical Details

### Codec Information

```
Codec: Realtek ALC1220
Vendor ID: 0x10ec1220
Subsystem ID: 0x1458a0d5 (Gigabyte)
```

### Pin Configuration

| Node | Function | Pin Default |
|------|----------|-------------|
| 0x14 | Front Headphone Jack | 0x0221401f |
| 0x1b | Rear Line Out | 0x01014010 |
| 0x18 | Rear Mic | 0x01a19040 |
| 0x19 | Front Mic | 0x02a19050 |

### ALSA Controls

| numid | Control | Values |
|-------|---------|--------|
| 9 | Auto-Mute Mode | 0=Disabled, 1=Enabled |
| 2 | Line Out Playback Switch | on/off |
| 3 | Headphone Playback Switch | on/off |
| 19 | Master Playback Volume | 0-87 |
| 1 | Headphone+LO Playback Volume | 0-87 |

### PipeWire/PulseAudio

Ensure analog stereo profile is active (find your card name with `pactl list cards`):

```bash
pactl set-card-profile <YOUR_CARD_NAME> "output:analog-stereo+input:analog-stereo"
# Example: pactl set-card-profile alsa_card.pci-0000_7a_00.6 "output:analog-stereo+input:analog-stereo"
```

---

## Restore Auto-Mute

If you prefer the default behavior (speakers mute when headphones plugged in):

```bash
amixer -c 2 cset numid=9 1
sudo alsactl store
```

---

## Tested Hardware

- **Motherboard**: Gigabyte X870E AORUS AI TOP
- **Audio Codec**: Realtek ALC1220
- **OS**: Linux (any distro with ALSA), Windows 10/11

---

## Tested Configurations

- Arch Linux + PipeWire
- Should work on any Linux distro with ALSA/PipeWire/PulseAudio

---

## Related Issues

This is a common issue with Realtek HD Audio codecs on gaming motherboards. The auto-mute feature is designed for laptops but causes problems on desktops where users want to use both front and rear audio jacks.

## License

MIT
