[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProfileName = "Default",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

<#
.SYNOPSIS
    Obtains and saves a Microsoft Intune authentication token for use with other IntuneRemediation scripts.
    
.DESCRIPTION
    This helper script obtains a Microsoft Intune authentication token and saves it for future use.
    It's the only script in the IntuneRemediation module that uses interactive authentication by default.
    All other scripts in the module will use the token obtained by this script.
    
.PARAMETER ProfileName
    The profile name to use when saving the token (default: "Default").
    
.PARAMETER Force
    Forces a new token to be obtained even if a valid one exists.
    
.EXAMPLE
    .\GetIntuneToken.ps1
    
    Obtains a new Intune token with browser authentication and saves it as the default profile.
    
.EXAMPLE
    .\GetIntuneToken.ps1 -ProfileName "AdminAccount"
    
    Obtains a new Intune token and saves it under the "AdminAccount" profile.
    
.NOTES
    Author: Intune Administrator
    Version: 1.0
    
    This is the ONLY script in the IntuneRemediation module that uses interactive authentication.
    All other scripts will use the token obtained and saved by this script.
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

try {
    # Check if we already have a valid token
    $tokenInfo = Get-IntuneTokenInfo -ProfileName $ProfileName
    
    if ($tokenInfo.TokenFound -and -not $tokenInfo.IsExpired -and -not $Force) {
        Write-Host "`nYou already have a valid token for profile '$ProfileName':" -ForegroundColor Green
        Write-Host "- User: $($tokenInfo.UserPrincipalName)" -ForegroundColor Cyan
        Write-Host "- Valid until: $($tokenInfo.ExpirationTime)" -ForegroundColor Cyan
        
        $useExisting = Read-Host "`nUse this existing token? (Y/N)"
        if ($useExisting -eq "Y" -or $useExisting -eq "y") {
            Write-Host "Using existing token. No changes made." -ForegroundColor Green
            exit 0
        }
        
        Write-Host "Obtaining a new token..." -ForegroundColor Yellow
    }
    
    # Use browser auth to get a new token
    Write-Host "`n=== ACQUIRING NEW INTUNE TOKEN ===" -ForegroundColor Cyan
    Write-Host "Starting browser authentication process..." -ForegroundColor Yellow
    Write-Host "IMPORTANT: You will be redirected to the Microsoft login page in your browser." -ForegroundColor Yellow
    
    # Explicitly enable interactive auth since that's what we want for this script
    $result = Initialize-IntuneConnection -ProfileName $ProfileName -ForceBrowser -DisableInteractiveAuth:$false -SaveTokenForReuse
    
    if ($result) {
        # Get information about the saved token
        $tokenInfo = Get-IntuneTokenInfo -ProfileName $ProfileName
        
        Write-Host "`n=== TOKEN OBTAINED SUCCESSFULLY ===" -ForegroundColor Green
        Write-Host "Token information:" -ForegroundColor Cyan
        Write-Host "- Profile: $ProfileName" -ForegroundColor White
        Write-Host "- User: $($tokenInfo.UserPrincipalName)" -ForegroundColor White
        Write-Host "- Valid until: $($tokenInfo.ExpirationTime)" -ForegroundColor White
        Write-Host "- Storage location: $($tokenInfo.TokenPath)" -ForegroundColor White
        
        Write-Host "`nThis token will be used automatically by other IntuneRemediation scripts." -ForegroundColor Green
        Write-Host "No need to manually paste the token in other scripts unless specifically requested." -ForegroundColor Green
    }
    else {
        Write-Error "Failed to obtain Intune token. Browser authentication may have been cancelled."
    }
}
catch {
    Write-Error "Error in token acquisition: $_"
} 