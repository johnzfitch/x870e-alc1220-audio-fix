@echo off
:: ALC1220 Audio Fix - Test Suite Launcher
:: Right-click and "Run as administrator"

echo Checking for admin privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Please run as Administrator
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo Starting test suite...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0run-full-test.ps1"

echo.
pause
