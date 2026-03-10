-- Phase 4 — WirePlumber rule for ALC1220 dual-sink split
--
-- USE WHEN: Phase 3 kernel patch produces two analog PCMs but PipeWire
-- merges them into a single sink with two ports (instead of two sinks).
--
-- This rule forces PipeWire to expose each analog PCM as an independent
-- sink node, enabling per-app routing in pavucontrol / Helvum / etc.
--
-- INSTALL:
--   mkdir -p ~/.config/wireplumber/wireplumber.conf.d
--   cp 51-alc1220-dual-sink.lua \
--     ~/.config/wireplumber/wireplumber.conf.d/51-alc1220-dual-sink.lua
--   systemctl --user restart wireplumber pipewire
--
-- REMOVE:
--   rm ~/.config/wireplumber/wireplumber.conf.d/51-alc1220-dual-sink.lua
--   systemctl --user restart wireplumber pipewire
--
-- TODO: This is a DRAFT. The device.name and node.name patterns depend
-- on Phase 3 results. Run `pw-dump` after Phase 3 boot to find the
-- actual names, then update the match rules below.

-- Force the pro-audio profile which exposes each PCM as a separate node.
-- The default profile (HiFi) may merge outputs into ports on one node.
alsa_monitor.rules = {
  {
    matches = {
      {
        -- Match our ALC1220 card by ALSA card name or PCI path
        { "device.name", "matches", "alsa_card.pci-0000_7a_00.6*" },
      },
    },
    apply_properties = {
      -- Option A: Force pro-audio profile (exposes every PCM as a node)
      -- Uncomment if the default profile merges outputs.
      -- ["device.profile"] = "pro-audio",

      -- Option B: Set the ACP profile that maps to dual-output
      -- Uncomment after confirming the profile name from `pactl list cards`
      -- ["device.profile"] = "output:analog-stereo+output:analog-stereo-2",
    },
  },

  -- If pro-audio profile is used, give friendly names to the raw nodes
  {
    matches = {
      {
        { "node.name", "matches", "alsa_output.pci-0000_7a_00.6*" },
        { "audio.channel", "equals", "FL" },  -- first stereo pair
      },
    },
    apply_properties = {
      -- TODO: update node.description after confirming which PCM is which
      ["node.description"] = "Headphones (Front Panel)",
    },
  },
  {
    matches = {
      {
        { "node.name", "matches", "alsa_output.pci-0000_7a_00.6*" },
        { "object.serial", "not-equals", "" },  -- second output node
      },
    },
    apply_properties = {
      ["node.description"] = "Speakers (Rear Line Out)",
    },
  },
}
