# <img src=".github/assets/icons/sound.png" width="28" height="28"> Realtek ALC1220 Audio Fix

**Use headphones AND speakers at the same time on your Gigabyte X870E motherboard.**

---

## <img src=".github/assets/icons/tick.png" width="24" height="24"> Quick Start (New Users Start Here)

| Platform | Guide | Status |
|----------|-------|--------|
| <img src=".github/assets/icons/windows.png" width="20" height="20"> **Windows** | [Windows Quick Start Guide](windows/QUICK-START.md) | <img src=".github/assets/icons/warning.png" width="16" height="16"> Needs Testing |
| <img src=".github/assets/icons/linux.png" width="20" height="20"> **Linux** | [Linux Quick Start Guide](linux/QUICK-START.md) | <img src=".github/assets/icons/tick.png" width="16" height="16"> Verified |

> **Help wanted!** We need Windows testers. See [TESTING.md](TESTING.md) for details.

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
# Resolve the Realtek ALC1220 card dynamically
CARD="$(for codec in /proc/asound/card*/codec*; do grep -q '^Codec: Realtek ALC1220$' "$codec" 2>/dev/null && card="${codec%/codec*}" && echo "${card##*card}" && break; done)"

# Disable auto-mute
amixer -c "$CARD" cset name='Auto-Mute Mode' Disabled

# Enable both outputs
amixer -c "$CARD" cset name='Line Out Playback Switch' on,on
amixer -c "$CARD" cset name='Headphone Playback Switch' on,on

# Set volume
amixer -c "$CARD" sset Master 100%

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

### How The Codec Works

The motherboard exposes one Realtek ALC1220 codec with multiple widgets behind a single controller. The rear green jack and the front headphone jack are not separate sound cards. They are two output paths on the same codec, and the driver decides whether inserting a front-panel headphone plug should mute the rear line-out.

On Linux, the stable identifier is the codec identity reported in `/proc/asound/card*/codec*`, not the ALSA card number. HDMI audio, USB audio devices, and controller enumeration can reorder card indexes between boots or hardware changes.

On Windows, the same hardware is managed by one Realtek driver package. Realtek HD Audio Manager or Realtek Audio Console owns the routing policy, and the scripts in this repo try to set the driver's registry-backed options before a reboot reloads them.

### Signal Path Overview

| Part | Node | What it controls |
|------|------|------------------|
| Front headphone jack | `0x14` | Front-panel headphone output path |
| Rear line-out jack | `0x1b` | Rear green speaker/line-out path |
| Rear mic jack | `0x18` | Rear microphone input |
| Front mic jack | `0x19` | Front-panel microphone input |

The failure sequence is:

1. The front headphone jack reports a plug event.
2. Auto-mute logic engages.
3. The rear line-out path is suppressed.
4. Speakers go silent even though the codec is still present and the rear jack is still connected.

The fix is to disable the mute policy and keep both output paths enabled.

### What Is Unique About This Board

- The controller often appears under a generic name such as `HD-Audio Generic`, so `/proc/asound/cards` is not enough to identify the Realtek codec.
- The codec identity is stable in `/proc/asound/card*/codec*` as `Codec: Realtek ALC1220`.
- ALSA control names are more stable than numeric `numid` values.
- Windows driver behavior varies by Realtek package version, so the GUI remains the most authoritative control surface.

### Stable Linux Identification

```bash
for codec in /proc/asound/card*/codec*; do
  grep -H '^Codec: Realtek ALC1220$' "$codec"
done
```

After you resolve the right card from that codec path, inspect the mixer surface with:

```bash
amixer -c "$CARD" controls
```

### Control Map

| Feature | Linux control | Windows control | Effect |
|---------|---------------|-----------------|--------|
| Auto-mute policy | `Auto-Mute Mode` | Device Advanced Settings mute-rear option | Controls whether front jack insertion silences the rear speakers |
| Rear speaker path | `Line Out Playback Switch` | Rear line-out routing in the Realtek driver | Enables or disables the rear green jack playback path |
| Front headphone path | `Headphone Playback Switch` | Front headphone routing in the Realtek driver | Enables or disables the front-panel headphone path |
| Shared analog volume | `Master`, `Headphone+LO Playback Volume` | Windows playback volume | Controls analog output gain |
| Jack sensing | `Front Headphone Jack`, `Line Out Jack` | Jack detection option in the Realtek UI | Reports whether the driver thinks a plug is present |
| Dual-output behavior | Both playback switches enabled, auto-mute disabled | "Make front and rear output devices playback two different audio streams simultaneously" | Keeps both front and rear outputs available together |

Use control names first. Treat numeric `numid` values as observations on one tested board, not as a stable API.

### Codec Information

```text
Codec: Realtek ALC1220
Vendor ID: 0x10ec1220
Subsystem ID: 0x1458a0d5 (Gigabyte)
```

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
# Resolve the card (same as above)
CARD="$(for codec in /proc/asound/card*/codec*; do grep -q '^Codec: Realtek ALC1220$' "$codec" 2>/dev/null && card="${codec%/codec*}" && echo "${card##*card}" && break; done)"

amixer -c "$CARD" cset name='Auto-Mute Mode' Enabled
sudo alsactl store
```

Or use the restore script: `linux/restore-automute.sh`

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
