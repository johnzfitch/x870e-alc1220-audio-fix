@echo off
:: Restore default Realtek audio behavior
:: Run as Administrator

echo === Restore Default Audio Settings ===
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please run as Administrator
    pause
    exit /b 1
)

echo Restoring default settings...

reg delete "HKLM\SOFTWARE\Realtek\Audio\HDA\Settings" /v JackDetection /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Realtek\Audio\HDA\Settings" /v AutoMuteRear /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings" /v JackDetection /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings" /v AutoMuteRear /f >nul 2>&1

echo Done! Default auto-mute behavior restored.
echo Restart your computer for changes to take effect.
pause
