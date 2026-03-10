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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-defaults.ps1"
if %errorLevel% neq 0 (
    echo.
    echo ERROR: The PowerShell restore failed.
    pause
    exit /b 1
)

pause
