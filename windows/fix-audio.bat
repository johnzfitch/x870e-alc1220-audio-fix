@echo off
:: Gigabyte X870E ALC1220 Audio Fix - Batch Script
:: Run as Administrator

echo === Gigabyte X870E ALC1220 Audio Fix ===
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please run as Administrator
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

echo Applying registry fixes...
echo.

:: Disable jack detection
reg add "HKLM\SOFTWARE\Realtek\Audio\HDA\Settings" /v JackDetection /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings" /v JackDetection /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable auto-mute rear
reg add "HKLM\SOFTWARE\Realtek\Audio\HDA\Settings" /v AutoMuteRear /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings" /v AutoMuteRear /t REG_DWORD /d 0 /f >nul 2>&1

echo Done!
echo.
echo Please restart your computer for changes to take effect.
echo After restart, both headphones and speakers should work.
echo.
pause
