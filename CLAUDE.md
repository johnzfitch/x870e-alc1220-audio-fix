# ALC1220 Audio Fix — Agent Context

## The Board

- **Gigabyte X870E AORUS XTREME AI TOP** (DMI board_name confirms)
- Audio: Realtek ALC1220 codec + ESS ES9118 DAC (headphone amp)
- HDA subsystem ID: `0x1458:0xa0d5` (confirmed from live PCI config space + codec AFG)
- PCI controller: AMD Ryzen HD Audio Controller `1022:15e3`
- 2 rear jacks (line-out, mic), front-panel headphone/mic header
- ALSA card number varies by system (not hardcoded)

## The Problem

The ALC1220 driver's auto-mute logic mutes the rear line-out when
headphones are inserted in the front panel jack. Desktop users need
both outputs active simultaneously.

## The Fix (Runtime)

`linux/fix-audio.sh` dynamically detects the ALC1220 card by scanning
`/proc/asound/card*/codec*` for `Codec: Realtek ALC1220`, then
validates the card has the expected controls (`Auto-Mute Mode`,
`Line Out Playback Switch`, `Headphone Playback Switch`) before
applying changes. Controls are addressed by name, not by numid.

## The Fix (Kernel)

`kernel/0001-ALSA-hda-realtek-*.patch` adds a new fixup
`ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE` that wraps the existing
`alc1220_fixup_gb_x570` and sets `suppress_auto_mute = 1`. The
`model=gb-aorus-no-automute` name is registered for the firmware
loader path. Uses local `struct alc_spec *spec` variable consistent
with rest of `patch_realtek.c`.

Only the `0xa0d5` quirk entry is changed. The X570 Aorus Master
(`0xa0cd`) and X570 Aorus Xtreme (`0xa0ce`) entries are left on
vanilla `ALC1220_FIXUP_GB_X570` since we cannot test those boards.

The `.fw` and modprobe `.conf` in `kernel/` only work after the
kernel patch is applied. Without it, use the runtime scripts.

## Subsystem ID

`0x1458:0xa0d5` is shared between the X570S Aorus Master and our
X870E board. Gigabyte reuses subsystem IDs across generations when
the audio layout is identical. The kernel quirk matches on subsystem
ID, not board name or chipset.

`SND_PCI_QUIRK` only matches on `subvendor:subdevice`. There is no
mechanism to also match on the primary PCI device ID (`1022:15e3`
vs `1022:1487`). The separate fixup wrapping `gb_x570` is the
correct approach for adding board-family-specific behavior while
leaving the base X570 fixup available for other entries.

## What This Is NOT

- Not a fix for all X870E boards (different models use different codecs)
- Not related to the X870E AORUS XTREME X3D AI TOP (uses ES9280AC +
  ES9080, entirely different audio hardware, different subsystem ID)
- Not a fix for non-Gigabyte boards

## Codec Topology (from /proc/asound/card3/codec#0)

```
DAC 0x02 -> Mixer 0x0c -> Pin 0x14 (Front HP, hardwired to 0x0c only)
                       -> Pin 0x1b (Rear LineOut, forced to 0x0c by gb_x570)
DAC 0x03 -> Mixer 0x0d    (idle, target for dual-DAC routing)
DAC 0x04 -> Mixer 0x0e    (idle)
DAC 0x05 -> Mixer 0x0f    (idle)
DAC 0x25 -> Mixer 0x26    (idle)
```

Pin 0x14 has 1 hardware connection (0x0c). Cannot be remapped.
Pin 0x1b has 5 hardware connections (0x0c 0x0d 0x0e 0x0f 0x26).
Currently overridden to {0x0c} by the gb_x570 fixup.

## Dual-DAC Routing Phases

`kernel/DUAL-DAC-ROUTING-PLAN.md` describes the phased approach.

| Phase | Status | Key File |
|-------|--------|----------|
| 1: Auto-mute fix | DONE | `kernel/0001-ALSA-*.patch` |
| 2a: Read coefs | DONE | `kernel/probe-logs/phase2a-coef-read.log` |
| 2b: model=generic boot | PREPARED | `kernel/probe-logs/test-generic.conf` + `probe.sh` |
| 2c: Manual coef writes | PREPARED | `kernel/probe-logs/phase2c-apply-coefs.sh` |
| 2d: Force connection select | PREPARED | `kernel/probe-logs/phase2d-select-dac.sh` |
| 3: Kernel dual-DAC patch | DRAFT | `kernel/0002-ALSA-*.patch` (3 variants) |
| 4: PipeWire dual-sink | DRAFT | `kernel/phase4/` (UCM + WirePlumber) |

Next step: Phase 2b — install `test-generic.conf`, reboot, run `probe.sh`.

## Windows Driver RE

The Realtek Windows driver (6.0.9927.1) analysis confirmed:
- Our SSID has zero special-case handling (generic ALC1220 path)
- Connection list restriction on 0x1b is Linux-kernel-only
- Coef writes are codec-family defaults, not board-specific
- Full analysis: `kernel/probe-logs/rtaiodat-reverse-engineering.log`

## Indexed Documentation

The `docs/` directory contains board manuals and the Gigabyte ALC1220
audio guide, indexed via llmx. The audio guide covers both the
ALC1220 + ES9118 variant (our board) and the ES9280AC + ES9080
variant (X3D board, not our concern) in the same PDF.

## Key Files

- `linux/fix-audio.sh` — runtime fix (production)
- `linux/check-status.sh` — diagnostic
- `linux/restore-automute.sh` — undo
- `kernel/0001-ALSA-*.patch` — Phase 1 upstream kernel patch
- `kernel/0002-ALSA-*.patch` — Phase 3 dual-DAC patch (draft, 3 variants)
- `kernel/gigabyte-x870e-alc1220.fw` — HDA firmware patch file
- `kernel/snd-hda-x870e.conf` — modprobe config
- `kernel/DUAL-DAC-ROUTING-PLAN.md` — master plan
- `kernel/probe-logs/probe.sh` — universal state capture (all phases)
- `kernel/probe-logs/phase2c-apply-coefs.sh` — manual coef writer
- `kernel/probe-logs/phase2d-select-dac.sh` — force DAC 0x03 on 0x1b
- `kernel/phase4/ucm2-dual-dac.conf` — UCM2 dual-output profile
- `kernel/phase4/51-alc1220-dual-sink.lua` — WirePlumber split rule
- `kernel/phase4/phase4-check.sh` — PipeWire dual-sink verifier
- `docs/` — board manuals (llmx indexed)
- `drivers/bios/` — BIOS F11 image
- `drivers/realtek/` — Windows Realtek DCH driver 6.0.9927.1
