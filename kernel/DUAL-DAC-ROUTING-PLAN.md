# Dual-DAC Independent Routing Plan

## Goal

Route front headphone (0x14) and rear line-out (0x1b) through separate
DACs so PipeWire exposes them as independent sinks, enabling per-app
audio routing (e.g. Discord to headphones, music to speakers).

## Hardware Constraint

Node 0x14 (front HP) has exactly **one** hardware connection: mixer
0x0c, fed by DAC 0x02.  This cannot be changed — it is hardwired in
the codec.

Node 0x1b (rear line-out) has **five** hardware connections:
0x0c, 0x0d, 0x0e, 0x0f, 0x26.  The `gb_x570` fixup currently
overrides this to `{0x0c}` only, forcing both outputs onto DAC 0x02.

The target routing is:

```
0x14 (Front HP)     → 0x0c → DAC 0x02  (unchanged, no choice)
0x1b (Rear LineOut) → 0x0d → DAC 0x03  (currently blocked by fixup)
```

Each DAC has independent 88-step volume (Amp-Out 0x00–0x57), so
per-output volume control is hardware-supported.

## Risk Assessment

### What the gb_x570 coef writes do

```c
WRITE_COEF(0x07, 0x03c0)  // unknown — may configure amp bias or clocking
WRITE_COEF(0x1a, 0x01c1)  // unknown — may configure output routing
WRITE_COEF(0x1b, 0x0202)  // unknown — shares index with node 0x1b coincidentally
WRITE_COEF(0x43, 0x3005)  // unknown — may configure jack detection
```

These are vendor-specific internal registers.  Their function is not
documented publicly.  They may assume both outputs share DAC 0x02.
If any coef configures internal analog muxing to route DAC 0x02 to
both output amplifiers, moving 0x1b to DAC 0x03 could result in
silence on the rear jack or distorted output.

### What could go wrong

1. Rear line-out goes silent (coefs route only DAC 0x02 to the rear amp)
2. Audio distortion (impedance mismatch if DAC 0x03 is not configured)
3. PipeWire does not discover two sinks (ACP profile logic may still
   merge them into one sink with two ports)
4. Volume linkage breaks (Master control may only affect DAC 0x02)

None of these risk hardware damage.  Worst case is silence or noise
that a reboot fixes.

## Phases

### Phase 1: Ship the auto-mute fix (DONE)

- `suppress_auto_mute = 1` via kernel patch or runtime script
- Both outputs active, shared DAC, same audio on both
- This is the safe baseline that works today

### Phase 2: Probe dual-DAC at runtime (NO KERNEL CHANGES)

Install `alsa-tools` for `hda-verb`:

```
sudo pacman -S alsa-tools
```

Then run these tests in order.  Each step is independently reversible
by rebooting.

#### 2a. Read current coef values (non-destructive)

Record the current state so we can compare after changes:

```bash
# Read the four coefs the fixup writes
for idx in 0x07 0x1a 0x1b 0x43; do
  val=$(hda-verb /dev/snd/hwC3D0 0x20 0x500 $idx 2>/dev/null | tail -1)
  echo "COEF $idx = $val"
  data=$(hda-verb /dev/snd/hwC3D0 0x20 0xd00 0x0 2>/dev/null | tail -1)
  echo "  data = $data"
done
```

#### 2b. Boot with model=generic (skip all fixups)

```bash
# /etc/modprobe.d/test-generic.conf
options snd-hda-codec-realtek model=generic
```

Reboot.  Both outputs default to the codec's native connection lists.
The generic parser will see 0x1b has multiple connection options and
may auto-assign DAC 0x03 to it.

Check what happens:

```bash
# Did the parser find two PCMs?
cat /proc/asound/card*/pcm*/info | grep -A3 "stream: PLAYBACK"

# Did PipeWire expose two sinks?
pactl list sinks short | grep pci-0000_7a_00.6

# Are both outputs working?
speaker-test -c2 -D hw:3,0 -t wav  # test first PCM
speaker-test -c2 -D hw:3,1 -t wav  # test second PCM (if it exists)
```

If model=generic produces two working sinks, Phase 3 is mostly
PipeWire profile work.  If it produces silence on one output, the
coef writes are needed and we proceed to 2c.

#### 2c. model=generic + manual coef writes

If 2b produces silence, apply the coefs manually after boot:

```bash
# Write the gb_x570 coefs via hda-verb
hda-verb /dev/snd/hwC3D0 0x20 0x500 0x07
hda-verb /dev/snd/hwC3D0 0x20 0x400 0x03c0
hda-verb /dev/snd/hwC3D0 0x20 0x500 0x1a
hda-verb /dev/snd/hwC3D0 0x20 0x400 0x01c1
hda-verb /dev/snd/hwC3D0 0x20 0x500 0x1b
hda-verb /dev/snd/hwC3D0 0x20 0x400 0x0202
hda-verb /dev/snd/hwC3D0 0x20 0x500 0x43
hda-verb /dev/snd/hwC3D0 0x20 0x400 0x3005
```

Then test audio again.  This tells us whether the coefs are
independent of the DAC routing.

#### 2d. Force dual-DAC with connection select

If the generic parser didn't auto-split, manually select 0x0d for
node 0x1b:

```bash
# Set connection select on node 0x1b to index 1 (mixer 0x0d)
hda-verb /dev/snd/hwC3D0 0x1b 0x701 0x01
```

Verify with:

```bash
cat /proc/asound/card3/codec#0 | grep -A5 "^Node 0x1b"
```

This changes the live routing without touching the kernel.

### Phase 3: Kernel fixup (only after Phase 2 succeeds)

Write `alc1220_fixup_gb_aorus_dual_dac()`:

```c
static void alc1220_fixup_gb_aorus_dual_dac(struct hda_codec *codec,
                                            const struct hda_fixup *fix,
                                            int action)
{
    struct alc_spec *spec = codec->spec;

    switch (action) {
    case HDA_FIXUP_ACT_PRE_PROBE:
        /* Do NOT override 0x1b's connection list — let the generic
         * parser discover DAC 0x03 via mixer 0x0d as a second output.
         * Only override 0x14 to 0x0c (it has no other options anyway). */
        spec->gen.suppress_auto_mute = 1;
        break;
    case HDA_FIXUP_ACT_INIT:
        /* Apply coefs if Phase 2c proved they are needed */
        alc_process_coef_fw(codec, gb_x570_coefs);
        break;
    }
}
```

Whether to include the coef writes depends on Phase 2b vs 2c results.

### Phase 4: PipeWire profile (only after Phase 3)

If the kernel exposes two PCM playback devices, PipeWire's ACP layer
should auto-discover them.  If it doesn't, a custom WirePlumber rule
or ALSA UCM profile would be needed:

```
# /usr/share/alsa/ucm2/HDA-Generic/X870E-ALC1220.conf
# Define separate SectionDevice entries for Headphones and Speakers
# pointing at different PCM devices
```

This is the least-certain phase — PipeWire's behavior depends on how
the generic parser names and exposes the second output.

## Rollback

Every phase is independently reversible:

- Phase 2: reboot (runtime changes are volatile)
- Phase 3: remove modprobe option or revert kernel patch
- Phase 4: delete UCM profile

No phase risks hardware damage.  Worst case is silence or noise until
reboot.

## Decision Points

After Phase 2b, one of three outcomes:

1. **Two sinks, both working** → Phase 3 is trivial, skip coefs
2. **Two sinks, rear silent until coefs applied** → Phase 3 needs coefs
3. **One sink despite dual-DAC** → PipeWire needs profile work (Phase 4)
   before Phase 3 is useful

Start with Phase 2a (read coefs) and 2b (model=generic).  These are
zero-risk and tell us everything we need to decide the rest.
