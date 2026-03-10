#Requires -RunAsAdministrator
# Gigabyte X870E ALC1220 Audio Fix - Windows PowerShell Implementation

$ErrorActionPreference = "Stop"

function Get-RealtekSettingsPaths {
    $paths = New-Object System.Collections.Generic.List[string]

    foreach ($path in @(
        "HKLM:\SOFTWARE\Realtek\Audio\HDA\Settings",
        "HKLM:\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings"
    )) {
        if (Test-Path $path) {
            $paths.Add($path)
        }
    }

    $classRoot = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}"
    if (Test-Path $classRoot) {
        Get-ChildItem $classRoot -ErrorAction SilentlyContinue | ForEach-Object {
            $driver = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            $isRealtek = $driver.DriverDesc -like "*Realtek*" -or $driver.ProviderName -like "*Realtek*"
            if ($isRealtek) {
                $paths.Add(("$($_.PSPath)\Settings"))
            }
        }
    }

    $paths | Select-Object -Unique
}

function Set-RegistryDword {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [int]$Value
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

Write-Host "=== Gigabyte X870E ALC1220 Audio Fix ===" -ForegroundColor Cyan
Write-Host ""

$settingsPaths = @(Get-RealtekSettingsPaths)
if ($settingsPaths.Count -eq 0) {
    Write-Error "Could not find any Realtek settings paths. Use Realtek HD Audio Manager or Realtek Audio Console instead."
}

foreach ($path in $settingsPaths) {
    Write-Host "Applying settings to: $path" -ForegroundColor Green
    Set-RegistryDword -Path $path -Name "JackDetection" -Value 0
    Write-Host "  JackDetection: Disabled" -ForegroundColor Yellow
    Set-RegistryDword -Path $path -Name "AutoMuteRear" -Value 0
    Write-Host "  AutoMuteRear: Disabled" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host "Please restart Windows for the Realtek driver to reload these settings." -ForegroundColor White
Write-Host "After restart, both headphones and rear speakers should be available." -ForegroundColor Green
