#!/bin/bash
# Generate a proper kernel patch for submission
# This script clones the sound tree, applies our changes, and generates
# a checkpatch-clean patch ready for submission.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/workdir"
SOUND_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/tiwai/sound.git"
BRANCH="for-next"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { printf "${GREEN}==>${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}WARNING:${NC} %s\n" "$*"; }
err() { printf "${RED}ERROR:${NC} %s\n" "$*" >&2; }
die() { err "$@"; exit 1; }

check_git_config() {
    local name email
    name=$(git config --get user.name 2>/dev/null || true)
    email=$(git config --get user.email 2>/dev/null || true)

    if [[ -z "$name" || -z "$email" ]]; then
        die "Git user.name and user.email must be configured.
Set them with:
  git config --global user.name \"Your Real Name\"
  git config --global user.email \"your.real@email.com\"

Kernel patches require real identity (no anonymous contributions)."
    fi

    log "Patch will be signed by: $name <$email>"
    read -rp "Is this correct? [Y/n] " confirm
    [[ ! "$confirm" =~ ^[Nn] ]] || die "Configure git user.name/email first"
}

clone_sound_tree() {
    if [[ -d "$WORK_DIR/sound" ]]; then
        log "Updating existing sound tree..."
        cd "$WORK_DIR/sound"
        git fetch origin
        git checkout "$BRANCH"
        git reset --hard "origin/$BRANCH"
    else
        log "Cloning sound tree (this may take a minute)..."
        mkdir -p "$WORK_DIR"
        git clone --depth=100 --single-branch -b "$BRANCH" "$SOUND_REPO" "$WORK_DIR/sound"
        cd "$WORK_DIR/sound"
    fi
}

apply_changes() {
    # Kernel reorganized HDA codecs in 2024 - ALC882 family (includes ALC1220)
    # is now in sound/hda/codecs/realtek/alc882.c
    local patch_file="$WORK_DIR/sound/sound/hda/codecs/realtek/alc882.c"

    [[ -f "$patch_file" ]] || die "alc882.c not found - kernel tree structure may have changed"

    log "Applying changes to alc882.c..."

    # Create a branch for our work
    git checkout -B alc1220-dual-dac

    # Find insertion points and apply changes using ed/sed
    # This is the tricky part - we need to find the right locations

    local tmp_file
    tmp_file=$(mktemp)

    # 1. Add enum entry after ALC1220_FIXUP_GB_X570
    # Pattern must be specific to avoid matching model table entry
    if ! grep -q "ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE" "$patch_file"; then
        sed -i '/^	ALC1220_FIXUP_GB_X570,$/a\	ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE,' "$patch_file"
    fi

    # 2. Add function after alc1220_fixup_gb_x570 function
    if ! grep -q "alc1220_fixup_gb_aorus_no_automute" "$patch_file"; then
        # Find the end of alc1220_fixup_gb_x570 and insert after
        awk '
        /^static void alc1220_fixup_gb_x570\(/ { in_func=1 }
        in_func && /^}$/ {
            print
            print ""
            print "/* Gigabyte X570S/X870E Aorus boards: enable independent DAC routing"
            print " * by not restricting pin 0x1b'"'"'s connection list, and suppress auto-mute"
            print " * so front headphone insertion does not silence rear line-out."
            print " */"
            print "static void alc1220_fixup_gb_aorus_no_automute(struct hda_codec *codec,"
            print "					       const struct hda_fixup *fix,"
            print "					       int action)"
            print "{"
            print "	struct alc_spec *spec = codec->spec;"
            print ""
            print "	if (action == HDA_FIXUP_ACT_PRE_PROBE)"
            print "		spec->gen.suppress_auto_mute = 1;"
            print "}"
            in_func=0
            next
        }
        { print }
        ' "$patch_file" > "$tmp_file" && mv "$tmp_file" "$patch_file"
    fi

    # 3. Add fixup table entry after ALC1220_FIXUP_GB_X570 entry
    if ! grep -q '\[ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE\]' "$patch_file"; then
        sed -i '/\[ALC1220_FIXUP_GB_X570\] = {/,/^	},$/{ /^	},$/a\
	[ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE] = {\
		.type = HDA_FIXUP_FUNC,\
		.v.func = alc1220_fixup_gb_aorus_no_automute,\
	},
}' "$patch_file"
    fi

    # 4. Update the quirk table entry for 0xa0d5
    sed -i 's/SND_PCI_QUIRK(0x1458, 0xa0d5, "Gigabyte X570S Aorus Master", ALC1220_FIXUP_GB_X570)/SND_PCI_QUIRK(0x1458, 0xa0d5, "Gigabyte X570S\/X870E Aorus", ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE)/' "$patch_file"

    # 5. Add model table entry after gb-x570
    if ! grep -q 'gb-aorus-no-automute' "$patch_file"; then
        sed -i '/{.id = ALC1220_FIXUP_GB_X570, .name = "gb-x570"},/a\	{.id = ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE, .name = "gb-aorus-no-automute"},' "$patch_file"
    fi

    log "Changes applied. Verifying..."

    # Verify all changes are present
    grep -q "ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE" "$patch_file" || die "Enum entry missing"
    grep -q "alc1220_fixup_gb_aorus_no_automute" "$patch_file" || die "Function missing"
    grep -q "gb-aorus-no-automute" "$patch_file" || die "Model entry missing"

    log "All changes verified."
}

create_commit() {
    cd "$WORK_DIR/sound"

    git add sound/hda/codecs/realtek/alc882.c

    # Check if there are actual changes
    if git diff --cached --quiet; then
        warn "No changes detected - patch may already be applied"
        return 1
    fi

    git commit -s -m "ALSA: hda/realtek: enable dual-DAC on Gigabyte X570S/X870E ALC1220

The ALC1220 codec on Gigabyte X570S Aorus Master and X870E AORUS
XTREME AI TOP boards (subsystem 0x1458:0xa0d5) has two usable output
paths:

  - Pin 0x14 (front HP): hardwired to mixer 0x0c -> DAC 0x02
  - Pin 0x1b (rear line-out): 5 connections (0x0c 0x0d 0x0e 0x0f 0x26)

The existing ALC1220_FIXUP_GB_X570 quirk overrides 0x1b's connection
list to {0x0c} only, forcing both outputs onto DAC 0x02. It also does
not suppress auto-mute, so inserting headphones silences the rear
line-out.

Desktop users need both outputs active simultaneously with independent
DAC routing for per-application audio (e.g., Discord to headphones,
music to speakers).

Add ALC1220_FIXUP_GB_AORUS_NO_AUTOMUTE which:
  - Does NOT restrict 0x1b's connection list, allowing the generic HDA
    parser to assign DAC 0x03 (via mixer 0x0d) as an independent output
  - Sets suppress_auto_mute so front HP insertion does not mute rear

The coefficient writes from gb_x570 are not required for audio output
on these boards, as confirmed by testing with model=generic and by
reverse-engineering the Windows Realtek driver which applies no
board-specific handling for this subsystem ID.

Tested on: Gigabyte X870E AORUS XTREME AI TOP
  ALC1220 codec, subsystem 0x1458:0xa0d5
  AMD Ryzen HD Audio Controller [1022:15e3]
  Kernel 6.18.13-arch1-1"

    log "Commit created."
}

generate_patch() {
    cd "$WORK_DIR/sound"

    log "Generating patch..."
    # Use HEAD~1 as base (the commit before our change)
    git format-patch --base=HEAD~1 -1 -o "$SCRIPT_DIR"

    local patch_name
    patch_name=$(ls -t "$SCRIPT_DIR"/0001-*.patch 2>/dev/null | head -1)

    if [[ -z "$patch_name" ]]; then
        die "Failed to generate patch"
    fi

    log "Patch generated: $patch_name"
    echo "$patch_name"
}

run_checkpatch() {
    local patch_file="$1"
    local checkpatch="$WORK_DIR/sound/scripts/checkpatch.pl"

    if [[ ! -x "$checkpatch" ]]; then
        warn "checkpatch.pl not found or not executable"
        return 0
    fi

    log "Running checkpatch.pl..."
    if "$checkpatch" --strict "$patch_file"; then
        log "checkpatch.pl: PASSED"
    else
        warn "checkpatch.pl reported issues - review and fix before submitting"
        return 1
    fi
}

show_next_steps() {
    local patch_file="$1"

    cat << EOF

${GREEN}============================================================${NC}
PATCH READY FOR REVIEW
${GREEN}============================================================${NC}

Generated: $patch_file

${YELLOW}Before submitting:${NC}
1. Review the patch carefully:
   less "$patch_file"

2. Test compile (optional but recommended):
   cd $WORK_DIR/sound
   make M=sound/hda

3. Get review from another person if possible

${YELLOW}To submit:${NC}
git send-email \\
  --to="tiwai@suse.de" \\
  --cc="alsa-devel@alsa-project.org" \\
  "$patch_file"

${YELLOW}Or configure git send-email first:${NC}
git config --global sendemail.smtpserver smtp.yourprovider.com
git config --global sendemail.smtpserverport 587
git config --global sendemail.smtpencryption tls
git config --global sendemail.smtpuser your@email.com

EOF
}

main() {
    log "ALC1220 Dual-DAC Kernel Patch Generator"
    echo

    check_git_config
    clone_sound_tree
    apply_changes
    create_commit
    patch_file=$(generate_patch)
    run_checkpatch "$patch_file" || true
    show_next_steps "$patch_file"
}

main "$@"
