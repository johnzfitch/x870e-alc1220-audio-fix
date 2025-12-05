#Requires -RunAsAdministrator
# ALC1220 Audio Fix - Full Test Suite
# Run this in Windows on your X870E to test the fix

$ErrorActionPreference = "Continue"
$TestResults = @()
$ReportPath = "$PSScriptRoot\test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

function Write-Test {
    param($Name, $Result, $Details = "")
    $status = if ($Result) { "PASS" } else { "FAIL" }
    $line = "[$status] $Name"
    if ($Details) { $line += " - $Details" }
    Write-Host $line -ForegroundColor $(if ($Result) { "Green" } else { "Red" })
    $script:TestResults += [PSCustomObject]@{
        Test = $Name
        Status = $status
        Details = $Details
    }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ALC1220 Audio Fix - Test Suite" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# System Info
Write-Host "[INFO] Collecting system information..." -ForegroundColor Yellow
$os = Get-CimInstance Win32_OperatingSystem
$mb = Get-CimInstance Win32_BaseBoard
Write-Host "  OS: $($os.Caption) $($os.Version)"
Write-Host "  Motherboard: $($mb.Manufacturer) $($mb.Product)"

# Test 1: Check for Realtek Audio Device
Write-Host ""
Write-Host "[TEST 1] Realtek Audio Device" -ForegroundColor Yellow
$audioDevices = Get-CimInstance Win32_SoundDevice | Where-Object { $_.Name -like "*Realtek*" }
if ($audioDevices) {
    Write-Test "Realtek device found" $true $audioDevices[0].Name
} else {
    Write-Test "Realtek device found" $false "No Realtek audio device detected"
}

# Test 2: Check Realtek Driver Version
Write-Host ""
Write-Host "[TEST 2] Realtek Driver Version" -ForegroundColor Yellow
$driver = Get-CimInstance Win32_PnPSignedDriver | Where-Object {
    $_.DeviceName -like "*Realtek*" -and $_.DeviceClass -eq "MEDIA"
} | Select-Object -First 1
if ($driver) {
    Write-Test "Driver version" $true $driver.DriverVersion
} else {
    Write-Test "Driver version" $false "Could not detect driver version"
}

# Test 3: Check Registry Paths Exist
Write-Host ""
Write-Host "[TEST 3] Registry Paths" -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Realtek\Audio\HDA\Settings",
    "HKLM:\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings"
)
foreach ($path in $regPaths) {
    $exists = Test-Path $path
    Write-Test "Registry path exists" $exists $path
}

# Test 4: Check Current Registry Values
Write-Host ""
Write-Host "[TEST 4] Current Registry Values (BEFORE fix)" -ForegroundColor Yellow
$beforeValues = @{}
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        $jack = (Get-ItemProperty -Path $path -Name "JackDetection" -ErrorAction SilentlyContinue).JackDetection
        $mute = (Get-ItemProperty -Path $path -Name "AutoMuteRear" -ErrorAction SilentlyContinue).AutoMuteRear
        Write-Host "  $path"
        Write-Host "    JackDetection: $(if ($null -eq $jack) { 'NOT SET' } else { $jack })"
        Write-Host "    AutoMuteRear: $(if ($null -eq $mute) { 'NOT SET' } else { $mute })"
        $beforeValues[$path] = @{ Jack = $jack; Mute = $mute }
    }
}

# Test 5: Apply Fix
Write-Host ""
Write-Host "[TEST 5] Applying Registry Fix" -ForegroundColor Yellow
$fixScript = Join-Path $PSScriptRoot "..\fix-audio.bat"
if (Test-Path $fixScript) {
    & cmd /c $fixScript
    Write-Test "Fix script executed" $true
} else {
    # Apply fix directly
    foreach ($path in $regPaths) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name "JackDetection" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $path -Name "AutoMuteRear" -Value 0 -Type DWord -Force
    }
    Write-Test "Fix applied directly" $true
}

# Test 6: Verify Registry Changes
Write-Host ""
Write-Host "[TEST 6] Registry Values (AFTER fix)" -ForegroundColor Yellow
$allPassed = $true
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        $jack = (Get-ItemProperty -Path $path -Name "JackDetection" -ErrorAction SilentlyContinue).JackDetection
        $mute = (Get-ItemProperty -Path $path -Name "AutoMuteRear" -ErrorAction SilentlyContinue).AutoMuteRear

        $jackOk = $jack -eq 0
        $muteOk = $mute -eq 0

        Write-Test "JackDetection = 0" $jackOk "$path"
        Write-Test "AutoMuteRear = 0" $muteOk "$path"

        if (-not $jackOk -or -not $muteOk) { $allPassed = $false }
    }
}

# Test 7: Audio Endpoint Check
Write-Host ""
Write-Host "[TEST 7] Audio Endpoints" -ForegroundColor Yellow
Add-Type -AssemblyName System.Speech
$endpoints = Get-CimInstance Win32_SoundDevice | Where-Object { $_.Status -eq "OK" }
Write-Host "  Active audio devices: $($endpoints.Count)"
foreach ($ep in $endpoints) {
    Write-Host "    - $($ep.Name)"
}

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
$passed = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

# Manual Tests Required
Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "  MANUAL TESTS REQUIRED" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Please perform these tests manually:"
Write-Host ""
Write-Host "  1. [ ] Plug headphones into FRONT jack"
Write-Host "  2. [ ] Plug speakers into REAR green jack"
Write-Host "  3. [ ] Play audio (YouTube, music, etc.)"
Write-Host "  4. [ ] Can you hear audio from HEADPHONES? (Y/N)"
Write-Host "  5. [ ] Can you hear audio from SPEAKERS? (Y/N)"
Write-Host "  6. [ ] Do BOTH play simultaneously? (Y/N)"
Write-Host ""
Write-Host "  If step 6 is YES, the fix works!"
Write-Host ""
Write-Host "  NOTE: You may need to REBOOT for changes to take effect."
Write-Host ""

# Save Report
$TestResults | Format-Table -AutoSize | Out-String | Out-File $ReportPath -Encoding UTF8
Write-Host "Report saved to: $ReportPath" -ForegroundColor Gray
