# Windows Quick Start Guide

## The Problem
When you plug headphones into the front of your PC, your rear speakers stop working. This guide fixes that so both work at the same time.

---

## Easiest Fix (Recommended)

### Step 1: Open Realtek HD Audio Manager
- Look for a **speaker icon** in your system tray (bottom-right corner, near the clock)
- If you don't see it, search "Realtek" in the Start menu
- It might be called "Realtek HD Audio Manager" or "Realtek Audio Console"

### Step 2: Find the Setting
- Look for **"Device Advanced Settings"** (usually a gear icon or in the menu)
- Find the checkbox that says one of these:
  - "Make front and rear output devices playback two different audio streams simultaneously"
  - "Mute the rear output device, when a front headphone plugged in" (UNCHECK this one)

### Step 3: Click OK and Test
- Plug in your headphones to the front
- Play some music
- You should hear it from BOTH headphones AND speakers

---

## Alternative: Run the Fix Script

If you can't find Realtek Audio Manager:

1. **Download** this file: [fix-audio.bat](fix-audio.bat)
2. **Right-click** on the file
3. Select **"Run as administrator"**
4. Click **Yes** when Windows asks for permission
5. **Restart your computer**

---

## How Do I Know It Worked?

1. Plug headphones into the **front** of your PC
2. Plug speakers into the **green jack** on the **back**
3. Play a YouTube video or music
4. You should hear audio from **BOTH** at the same time

---

## Still Not Working?

### "I can't find Realtek Audio Manager"
- It might not be installed. Download it from your motherboard manufacturer's website (Gigabyte, ASUS, MSI, etc.)
- Go to Support → Downloads → Audio drivers

### "The script didn't work"
- Make sure you right-clicked and selected "Run as administrator"
- Restart your computer after running it

### "I only have one audio device showing"
- This is normal! After enabling dual output, a second device called "Realtek HD Audio 2nd output" may appear in your Sound settings

---

## Need More Help?

Open an issue on GitHub: https://github.com/johnzfitch/x870e-alc1220-audio-fix/issues
