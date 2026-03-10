# Windows Audio Fix - Gigabyte X870E ALC1220

Enable simultaneous headphone and speaker output on Gigabyte X870E motherboards in Windows.

## Quick Fix

### Method 1: Realtek HD Audio Manager (Recommended)

1. Open **Realtek HD Audio Manager** from system tray or Control Panel
2. Click **Device Advanced Settings** (gear icon)
3. Check: **"Make front and rear output devices playback two different audio streams simultaneously"**
4. Click **OK**

This creates a second audio device "Realtek HD Audio 2nd output" for independent control.

### Method 2: Disable Auto-Mute

1. Open **Realtek HD Audio Manager**
2. Go to **Device Advanced Settings**
3. Uncheck: **"Mute the rear output device, when a front headphone plugged in"**
4. Click **OK**

### Method 3: Disable Jack Detection

1. Open **Realtek HD Audio Manager**
2. Click the **yellow folder icon** (top-right)
3. Check: **"Disable front panel jack detection"**
4. Click **OK**

## Automated Fix

Run PowerShell as Administrator:

```powershell
.\fix-audio.ps1
```

Or use the batch wrapper:

```bat
fix-audio.bat
```

`fix-audio-registry.ps1` remains available as a compatibility alias to `fix-audio.ps1`.

## Files

| File | Description |
|------|-------------|
| `fix-audio.ps1` | Primary PowerShell fix that updates Realtek registry settings |
| `fix-audio.bat` | Administrator-friendly wrapper for `fix-audio.ps1` |
| `fix-audio-registry.ps1` | Compatibility alias to `fix-audio.ps1` |
| `restore-defaults.ps1` | Restore default auto-mute behavior |
| `restore-defaults.bat` | Wrapper for `restore-defaults.ps1` |

## How Windows Controls This

Windows does not expose the rear speakers and front headphones as separate hardware cards. The Realtek driver owns one codec and decides whether the front jack should mute the rear line-out. The GUI setting in Realtek HD Audio Manager or Realtek Audio Console is the authoritative control surface, while the scripts in this folder are a best-effort way to write the same driver settings in the registry and then reboot so the driver reloads them.

## Realtek Audio Console (Windows Store)

If using the Windows Store version:

1. Open **Realtek Audio Console**
2. Click **Device Advanced Settings** (left sidebar)
3. Under Playback Device, enable dual stream mode

## Troubleshooting

### Realtek Audio Manager Missing

Download from Gigabyte support page or use Microsoft generic driver:

1. Open **Device Manager**
2. Right-click audio device > **Update driver**
3. **Browse my computer** > **Let me pick from a list**
4. Select **High Definition Audio Device**

### Options Missing in Newer Drivers

Realtek drivers v2.67+ removed some options. Install older driver (v2.62) from Gigabyte support.

### No Second Audio Device

After enabling dual stream mode, restart Windows for the second device to appear.

### Automated Fix Runs But Audio Behavior Does Not Change

Some Realtek driver packages do not honor these registry keys. If that happens, use Realtek HD Audio Manager or Realtek Audio Console directly and verify the advanced playback settings there.

## Driver Downloads

- [Gigabyte X870E Support Page](https://www.gigabyte.com/Motherboard/X870E-AORUS-XTREME-AI-TOP/support#support-dl)
- Look for "Realtek HD Audio Driver" under Audio section
