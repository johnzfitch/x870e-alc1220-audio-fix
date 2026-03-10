#!/bin/bash
# Phase 4: Verify PipeWire dual-sink configuration.
#
# Run after Phase 3 kernel boot to determine which Phase 4 approach is needed:
#   A) Two sinks already exposed -> done, no Phase 4 config needed
#   B) One sink, two ports -> need WirePlumber rule (51-alc1220-dual-sink.lua)
#   C) One sink, one port -> UCM profile needed (ucm2-dual-dac.conf)

set -euo pipefail

header() {
    echo "=============================================================================="
    echo "$1"
    echo "=============================================================================="
}

header "Phase 4: PipeWire Dual-Sink Check — $(date -Iseconds)"
echo

# --- 1. ALSA PCM devices ---

header "1. ALSA PCM DEVICES"
echo "Looking for analog playback PCMs on the ALC1220 card..."
alc_card=""
for codec in /proc/asound/card*/codec*; do
    [ -e "$codec" ] || continue
    grep -q "^Codec: Realtek ALC1220$" "$codec" 2>/dev/null || continue
    alc_card=${codec%/codec*}; alc_card=${alc_card##*card}
    break
done

if [ -z "$alc_card" ]; then
    echo "  FATAL: ALC1220 not found"
    exit 1
fi
echo "  Card: $alc_card"

# Derive PCI path for PipeWire sink matching (e.g. "pci-0000_7a_00.6")
pci_path=$(readlink -f /sys/class/sound/card${alc_card}/device 2>/dev/null | xargs basename 2>/dev/null | tr ':.' '_' || true)
[ -n "$pci_path" ] && pci_path="pci-${pci_path}" || pci_path=""
echo "  PCI path: ${pci_path:-(could not derive)}"
echo

analog_pcms=0
for pcm in /proc/asound/card${alc_card}/pcm*p/info; do
    [ -e "$pcm" ] || continue
    name=$(grep "^name:" "$pcm" | cut -d' ' -f2-)
    id=$(grep "^id:" "$pcm" | cut -d' ' -f2-)
    dev=$(grep "^device:" "$pcm" | cut -d' ' -f2-)
    echo "  Device $dev: $id ($name)"
    # Count analog (not Digital/HDMI)
    echo "$name" | grep -qi "digital\|hdmi\|iec958" || analog_pcms=$((analog_pcms + 1))
done
echo
echo "  Analog playback PCMs: $analog_pcms"
echo

# --- 2. PipeWire cards & profiles ---

header "2. PIPEWIRE CARD PROFILES"
if command -v pactl &>/dev/null && [ -n "$pci_path" ]; then
    echo "Available profiles for ALC1220 card:"
    pactl list cards 2>/dev/null | awk -v pat="$pci_path" '$0 ~ pat{found=1} found && /Profiles:/{prof=1} prof && /^$/{prof=0} prof{print}' || echo "  (could not list)"
    echo
    echo "Active profile:"
    pactl list cards 2>/dev/null | awk -v pat="$pci_path" '$0 ~ pat{found=1} found && /Active Profile:/{print; found=0}' || echo "  (could not determine)"
else
    echo "  pactl not available or PCI path unknown"
fi
echo

# --- 3. PipeWire sinks ---

header "3. PIPEWIRE SINKS"
alc_sinks=0
if command -v pactl &>/dev/null && [ -n "$pci_path" ]; then
    echo "All sinks:"
    pactl list sinks short 2>/dev/null || echo "  (failed)"
    echo
    echo "ALC1220-related sinks:"
    alc_sinks=$(pactl list sinks short 2>/dev/null | grep -c "$pci_path" || true)
    pactl list sinks short 2>/dev/null | grep "$pci_path" || echo "  (none)"
    echo
    echo "  Count: $alc_sinks"
elif command -v pactl &>/dev/null; then
    echo "  (PCI path unknown, showing all sinks)"
    pactl list sinks short 2>/dev/null || echo "  (failed)"
else
    echo "  pactl not available"
fi
echo

# --- 4. PipeWire nodes (detailed) ---

header "4. PIPEWIRE OUTPUT NODES"
if command -v pw-cli &>/dev/null; then
    match="${pci_path:-ALC1220}"
    pw-cli ls Node 2>/dev/null | grep -B2 -A5 "${match}\|ALC1220\|Generic_1" || echo "  (none matching)"
else
    echo "  pw-cli not available"
fi
echo

# --- 5. Sink ports ---

header "5. SINK PORTS (per-sink)"
if command -v pactl &>/dev/null && [ -n "$pci_path" ]; then
    pactl list sinks 2>/dev/null | awk -v pat="$pci_path" '
        /Name:/ && $0 ~ pat {found=1; print}
        found && /Ports:/{ports=1}
        ports && /^$/{ports=0; found=0}
        ports{print}
    ' || echo "  (could not list)"
else
    echo "  pactl not available or PCI path unknown"
fi
echo

# --- 6. Verdict ---

header "6. VERDICT"
if [ "$analog_pcms" -ge 2 ] && [ "$alc_sinks" -ge 2 ]; then
    echo "  TWO SINKS DETECTED — dual-DAC routing is fully active."
    echo "  No Phase 4 configuration needed."
    echo "  Test: open pavucontrol and route different apps to each sink."
elif [ "$analog_pcms" -ge 2 ] && [ "$alc_sinks" -eq 1 ]; then
    echo "  TWO PCMs but ONE SINK — PipeWire merged outputs."
    echo "  Action: install WirePlumber rule to split sinks."
    echo "    cp 51-alc1220-dual-sink.lua ~/.config/wireplumber/wireplumber.conf.d/"
    echo "    systemctl --user restart wireplumber pipewire"
    echo "  Or try pro-audio profile:"
    [ -n "$pci_path" ] && echo "    pactl set-card-profile alsa_card.${pci_path} pro-audio"
elif [ "$analog_pcms" -eq 1 ]; then
    echo "  ONE PCM — kernel did not create a second analog output."
    echo "  Phase 3 kernel patch may need VARIANT C (forced connection override)."
    echo "  Or UCM profile needed: install ucm2-dual-dac.conf"
else
    echo "  UNEXPECTED STATE — $analog_pcms analog PCMs, $alc_sinks sinks."
    echo "  Check probe.sh output for diagnostics."
fi
echo
