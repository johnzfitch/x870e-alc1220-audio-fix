# Gigabyte X870E ALC1220 Audio Fix - Registry Method
# Run as Administrator
# Disables front panel jack detection to enable both outputs

#Requires -RunAsAdministrator

Write-Host "=== Gigabyte X870E ALC1220 Audio Fix ===" -ForegroundColor Cyan
Write-Host ""

# Registry paths for Realtek audio settings
$realtekPaths = @(
    "HKLM:\SOFTWARE\Realtek\Audio\HDA\Settings",
    "HKLM:\SOFTWARE\WOW6432Node\Realtek\Audio\HDA\Settings"
)

foreach ($path in $realtekPaths) {
    if (Test-Path $path) {
        Write-Host "Found Realtek settings at: $path" -ForegroundColor Green

        # Disable jack detection
        try {
            Set-ItemProperty -Path $path -Name "JackDetection" -Value 0 -Type DWord -ErrorAction Stop
            Write-Host "  JackDetection: Disabled" -ForegroundColor Yellow
        } catch {
            New-ItemProperty -Path $path -Name "JackDetection" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Host "  JackDetection: Created and Disabled" -ForegroundColor Yellow
        }

        # Disable auto-mute
        try {
            Set-ItemProperty -Path $path -Name "AutoMuteRear" -Value 0 -Type DWord -ErrorAction Stop
            Write-Host "  AutoMuteRear: Disabled" -ForegroundColor Yellow
        } catch {
            New-ItemProperty -Path $path -Name "AutoMuteRear" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Host "  AutoMuteRear: Created and Disabled" -ForegroundColor Yellow
        }
    }
}

# Alternative registry location
$altPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}"
if (Test-Path $altPath) {
    Get-ChildItem $altPath -ErrorAction SilentlyContinue | ForEach-Object {
        $subPath = $_.PSPath
        $driverDesc = Get-ItemProperty -Path $subPath -Name "DriverDesc" -ErrorAction SilentlyContinue
        if ($driverDesc.DriverDesc -like "*Realtek*") {
            Write-Host "Found Realtek driver at: $subPath" -ForegroundColor Green

            $settingsPath = "$subPath\Settings"
            if (-not (Test-Path $settingsPath)) {
                New-Item -Path $settingsPath -Force | Out-Null
            }

            Set-ItemProperty -Path $settingsPath -Name "JackDetection" -Value 0 -Type DWord -Force
            Write-Host "  JackDetection: Disabled" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host "Please restart your computer for changes to take effect." -ForegroundColor White
Write-Host ""
Write-Host "After restart, both headphones and speakers should work simultaneously." -ForegroundColor Green
