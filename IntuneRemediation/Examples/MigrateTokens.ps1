[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProfileName
)

<#
.SYNOPSIS
    Migrates Intune tokens from legacy format to the new format.
    
.DESCRIPTION
    The token storage format was updated to be more consistent and secure.
    This helper script finds and converts any tokens stored in the old format.
    
.PARAMETER ProfileName
    Optional. If specified, only migrates the token for this profile.
    If not specified, all profiles will be migrated.
    
.EXAMPLE
    .\MigrateTokens.ps1
    
    Migrates all tokens found in the legacy format.
    
.EXAMPLE
    .\MigrateTokens.ps1 -ProfileName "Default"
    
    Migrates only the "Default" profile token.
    
.NOTES
    This is a one-time operation needed after updating to the new version
    of the IntuneRemediation module.
#>

# Ensure we are in the script's directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath -Parent
Set-Location -Path $scriptDir

# Import the IntuneRemediation module
try {
    $modulePath = (Get-Item -Path $scriptDir).Parent.FullName
    Import-Module -Name "$modulePath\IntuneRemediation.psd1" -Force -ErrorAction Stop
    Write-Host "IntuneRemediation module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to import IntuneRemediation module: $_"
    Write-Host "Please ensure the module is installed or adjust the path accordingly." -ForegroundColor Yellow
    exit 1
}

# Display header
Write-Host "`n=== INTUNE TOKEN MIGRATION TOOL ===" -ForegroundColor Cyan
Write-Host "This script will migrate tokens from the legacy format to the new format." -ForegroundColor Yellow
Write-Host "Legacy tokens will be backed up with a .old extension." -ForegroundColor Yellow

# Run the token migration
if ($ProfileName) {
    Write-Host "`nMigrating tokens for profile: $ProfileName" -ForegroundColor Cyan
    Convert-LegacyIntuneTokens -ProfileName $ProfileName
} else {
    Write-Host "`nMigrating all tokens..." -ForegroundColor Cyan
    Convert-LegacyIntuneTokens
}

Write-Host "`nMigration complete. You can now use your tokens with the updated IntuneRemediation module." -ForegroundColor Green
Write-Host "If you encounter any issues, run the GetIntuneToken.ps1 script to obtain a fresh token." -ForegroundColor Yellow 