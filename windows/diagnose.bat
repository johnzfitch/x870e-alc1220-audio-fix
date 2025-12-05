@echo off
:: Diagnostic script - checks your Realtek audio configuration
:: Does NOT make any changes - safe to run

echo === Realtek ALC1220 Audio Diagnostic ===
echo.
echo This script checks your system and does NOT make any changes.
echo.

echo [1/4] Checking for Realtek registry keys...
echo.

echo Checking: HKLM\SOFTWARE\Realtek\Audio\HDA\Settings
reg query "HKLM\SOFTWARE\Realtek\Audio\HDA\Settings" 2>nul
if %errorLevel% neq 0 (
    echo   NOT FOUND
) else (
    echo   FOUND
)
echo.

echo Checking: HKLM\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings
reg query "HKLM\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings" 2>nul
if %errorLevel% neq 0 (
    echo   NOT FOUND
) else (
    echo   FOUND
)
echo.

echo [2/4] Checking for audio devices...
echo.
wmic sounddev get name,status 2>nul
echo.

echo [3/4] Checking Realtek driver version...
echo.
wmic datafile where name="C:\\Windows\\System32\\drivers\\RTKVHD64.sys" get version 2>nul
if %errorLevel% neq 0 (
    echo   Realtek driver not found at standard location
)
echo.

echo [4/4] Current JackDetection and AutoMute settings...
echo.
echo JackDetection:
reg query "HKLM\SOFTWARE\Realtek\Audio\HDA\Settings" /v JackDetection 2>nul
if %errorLevel% neq 0 (
    echo   Not set (using default)
)
echo.
echo AutoMuteRear:
reg query "HKLM\SOFTWARE\Realtek\Audio\HDA\Settings" /v AutoMuteRear 2>nul
if %errorLevel% neq 0 (
    echo   Not set (using default)
)
echo.

echo === Diagnostic Complete ===
echo.
echo Please copy the output above and include it when reporting issues:
echo https://github.com/johnzfitch/x870e-alc1220-audio-fix/issues
echo.
pause
