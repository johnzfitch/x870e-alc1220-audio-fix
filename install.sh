#!/bin/bash
# ALC1220 Dual-DAC Audio Fix Installer
# For: Gigabyte X870E / X570S AORUS boards with ALC1220 codec
# Subsystem ID: 0x1458:0xa0d5
#
# This installer applies a firmware patch that:
#   1. Routes rear line-out to DAC 0x03 (independent from front headphone)
#   2. Disables auto-mute (front HP insertion won't silence rear output)
#
# Works on stock kernels - no kernel patch required.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW_FILE="kernel/gigabyte-x870e-alc1220.fw"
MODPROBE_FILE="kernel/snd-hda-x870e.conf"
FW_DEST="/lib/firmware/gigabyte-x870e-alc1220.fw"
MODPROBE_DEST="/etc/modprobe.d/snd-hda-x870e.conf"
EXPECTED_SUBSYS="0x1458a0d5"

log() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }
die() { err "$@"; exit 1; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root (try: sudo $0)"
    fi
}

check_files() {
    [[ -f "$SCRIPT_DIR/$FW_FILE" ]] || die "Missing firmware file: $FW_FILE"
    [[ -f "$SCRIPT_DIR/$MODPROBE_FILE" ]] || die "Missing modprobe config: $MODPROBE_FILE"
}

detect_codec() {
    local codec_file subsys_id

    # Find ALC1220 codec
    for codec_file in /proc/asound/card*/codec*; do
        [[ -f "$codec_file" ]] || continue
        if grep -q "Codec: Realtek ALC1220" "$codec_file" 2>/dev/null; then
            subsys_id=$(grep "Subsystem Id:" "$codec_file" | awk '{print $3}')
            if [[ "$subsys_id" == "$EXPECTED_SUBSYS" ]]; then
                log "Found ALC1220 codec with subsystem $subsys_id"
                return 0
            else
                log "Found ALC1220 but subsystem $subsys_id != $EXPECTED_SUBSYS"
                log "This fix is designed for Gigabyte X870E/X570S AORUS boards."
                read -rp "Continue anyway? [y/N] " confirm
                [[ "$confirm" =~ ^[Yy] ]] || exit 1
                return 0
            fi
        fi
    done

    die "ALC1220 codec not found. This fix only applies to Gigabyte X870E/X570S AORUS boards."
}

remove_conflicting_configs() {
    local conflicts=(
        "/etc/modprobe.d/test-generic.conf"
    )
    for f in "${conflicts[@]}"; do
        if [[ -f "$f" ]]; then
            log "Removing conflicting config: $f"
            rm -f "$f"
        fi
    done
}

install_files() {
    log "Installing firmware patch to $FW_DEST"
    cp "$SCRIPT_DIR/$FW_FILE" "$FW_DEST"
    chmod 644 "$FW_DEST"

    log "Installing modprobe config to $MODPROBE_DEST"
    cp "$SCRIPT_DIR/$MODPROBE_FILE" "$MODPROBE_DEST"
    chmod 644 "$MODPROBE_DEST"
}

show_status() {
    log ""
    log "Installation complete."
    log ""
    log "Installed files:"
    log "  $FW_DEST"
    log "  $MODPROBE_DEST"
    log ""
    log "To activate, either:"
    log "  1. Reboot (recommended)"
    log "  2. Reload the audio module:"
    log "     sudo modprobe -r snd_hda_intel && sudo modprobe snd_hda_intel"
    log ""
    log "After reboot, verify with:"
    log "  cat /proc/asound/card*/codec* | grep -A3 'Node 0x1b'"
    log "  # Should show: Connection: ... 0x0d* ..."
    log ""
}

uninstall() {
    log "Uninstalling ALC1220 fix..."
    [[ -f "$FW_DEST" ]] && rm -v "$FW_DEST"
    [[ -f "$MODPROBE_DEST" ]] && rm -v "$MODPROBE_DEST"
    log "Uninstall complete. Reboot to restore default behavior."
    exit 0
}

usage() {
    cat <<EOF
Usage: sudo $0 [OPTIONS]

Options:
  --install     Install the ALC1220 dual-DAC fix (default)
  --uninstall   Remove the fix and restore defaults
  --check       Check if compatible hardware is present
  --help        Show this help

This fix enables independent audio routing for:
  - Front panel headphone jack (DAC 0x02)
  - Rear line-out jack (DAC 0x03)

Both outputs work simultaneously without auto-mute interference.
EOF
    exit 0
}

main() {
    local action="install"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install)   action="install"; shift ;;
            --uninstall) action="uninstall"; shift ;;
            --check)     action="check"; shift ;;
            --help|-h)   usage ;;
            *)           die "Unknown option: $1" ;;
        esac
    done

    case "$action" in
        check)
            detect_codec
            log "Hardware check passed."
            ;;
        uninstall)
            check_root
            uninstall
            ;;
        install)
            check_root
            check_files
            detect_codec
            remove_conflicting_configs
            install_files
            show_status
            ;;
    esac
}

main "$@"
