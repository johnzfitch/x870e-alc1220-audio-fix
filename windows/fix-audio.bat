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

echo Launching PowerShell fix...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-audio.ps1"
if %errorLevel% neq 0 (
    echo.
    echo ERROR: The PowerShell fix failed.
    echo Open PowerShell as Administrator and run:
    echo   powershell -ExecutionPolicy Bypass -File "%~dp0fix-audio.ps1"
    echo.
    pause
    exit /b 1
)

pause
