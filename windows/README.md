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

Or use the registry fix:

```powershell
.\fix-audio-registry.ps1
```

## Files

| File | Description |
|------|-------------|
| `fix-audio.ps1` | Automated fix via Realtek settings |
| `fix-audio-registry.ps1` | Registry-based fix |
| `restore-defaults.ps1` | Restore default auto-mute behavior |

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

## Driver Downloads

- [Gigabyte X870E Support Page](https://www.gigabyte.com/Motherboard/X870E-AORUS-XTREME-AI-TOP/support#support-dl)
- Look for "Realtek HD Audio Driver" under Audio section
