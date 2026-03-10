#Requires -RunAsAdministrator
# Restore default Realtek audio behavior by removing custom override values.

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

function Remove-RegistryValueIfPresent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    }
}

Write-Host "=== Restore Default Audio Settings ===" -ForegroundColor Cyan
Write-Host ""

$settingsPaths = @(Get-RealtekSettingsPaths)
if ($settingsPaths.Count -eq 0) {
    Write-Error "Could not find any Realtek settings paths to restore."
}

foreach ($path in $settingsPaths) {
    Write-Host "Restoring defaults in: $path" -ForegroundColor Green
    Remove-RegistryValueIfPresent -Path $path -Name "JackDetection"
    Remove-RegistryValueIfPresent -Path $path -Name "AutoMuteRear"
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host "Restart Windows for the driver to reload its default behavior." -ForegroundColor White
