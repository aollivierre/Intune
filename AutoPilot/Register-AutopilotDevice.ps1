# Windows Autopilot Registration Script using AutopilotModule
# This script is a simplified frontend to the AutopilotModule functionality
# This script is designed to be run from a USB drive or other portable media
# This module is a custom module that I created to simplify the registration process but there is another module that has the same exact name on the PS Gallery


[CmdletBinding()]
param(
    [Parameter()]
    [switch]$RebootAfterRegistration = $false,
    
    [Parameter()]
    [int]$RebootDelay = 10
)

# Copy script to temp directory for portability
$tempScriptPath = Join-Path $env:TEMP "Register-AutopilotDevice.ps1"
try {
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $tempScriptPath -Force
    Write-Host "Script copied to: $tempScriptPath" -ForegroundColor Green
    Write-Host "You can safely remove the USB drive and use the script from the temp location." -ForegroundColor Green
}
catch {
    Write-Warning "Failed to copy script to temp directory: $_"
}

# Display script header
$scriptName = $MyInvocation.MyCommand.Name
$border = "=" * 80
Write-Host $border -ForegroundColor Green
Write-Host "  WINDOWS AUTOPILOT DEVICE REGISTRATION" -ForegroundColor Green
Write-Host "  Script: $scriptName" -ForegroundColor Green
Write-Host $border -ForegroundColor Green

# Get the directory where this script is located
$scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$modulePath = Join-Path -Path $scriptDirectory -ChildPath "AutopilotModule"

# Check if module exists
if (Test-Path -Path $modulePath) {
    # Import the module
    try {
        # First, ensure module is not already loaded
        if (Get-Module -Name AutopilotModule) {
            Remove-Module -Name AutopilotModule -Force
        }
        
        # Import the module from the current directory
        Import-Module -Name $modulePath -Force
        Write-Host "AutopilotModule loaded successfully from: $modulePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to import AutopilotModule: $_"
        exit 1
    }
}
else {
    Write-Error "AutopilotModule not found at path: $modulePath"
    exit 1
}

# Check module is loaded
if (-not (Get-Module -Name AutopilotModule)) {
    Write-Error "AutopilotModule failed to load."
    exit 1
}

# Execute the main registration function
try {
    $secretsPath = Join-Path -Path $modulePath -ChildPath "secrets.psd1"
    Register-DeviceWithPromptedCredentials -SecretsFilePath $secretsPath -RebootAfterRegistration:$RebootAfterRegistration -RebootDelay $RebootDelay
}
catch {
    Write-Error "Error during device registration: $_"
    exit 1
}
