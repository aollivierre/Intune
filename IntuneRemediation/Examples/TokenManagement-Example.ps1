[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProfileName = "Default",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

<#
.SYNOPSIS
    Example script demonstrating proper token management with the IntuneRemediation module.
.DESCRIPTION
    This script shows how to properly use the token management functions in the IntuneRemediation module,
    including the public Get-IntuneTokenStoragePath function. Use this as a template for creating new
    management scripts.
.PARAMETER ProfileName
    Name of the token profile to use (default: "Default")
.PARAMETER Force
    Forces new authentication even if a valid token exists
.EXAMPLE
    .\TokenManagement-Example.ps1
    
    Shows token information for the default profile.
.EXAMPLE
    .\TokenManagement-Example.ps1 -ProfileName "WorkAccount" -Force
    
    Forces re-authentication for the "WorkAccount" profile and displays token information.
.NOTES
    Author: Intune Administrator
    Version: 1.0
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

# Main process
try {
    # Step 1: Display token storage location information
    Write-Host "`n=== TOKEN STORAGE INFORMATION ===" -ForegroundColor Cyan
    
    # Use the public Get-IntuneTokenStoragePath function to get the token directory
    $tokenDirectory = Get-IntuneTokenStoragePath -ProfileName $ProfileName
    Write-Host "Token storage directory: $tokenDirectory" -ForegroundColor Yellow
    
    # List token files in the directory
    if (Test-Path $tokenDirectory) {
        $tokenFiles = Get-ChildItem -Path $tokenDirectory -Filter "*.xml" | Select-Object -ExpandProperty Name
        Write-Host "Found token files: $($tokenFiles -join ', ')" -ForegroundColor Gray
    }
    
    # Step 2: Get and display token information
    Write-Host "`n=== TOKEN STATUS INFORMATION ===" -ForegroundColor Cyan
    $tokenInfo = Get-IntuneTokenInfo -ProfileName $ProfileName
    
    Write-Host "Token status check results:" -ForegroundColor Yellow
    Write-Host "- Token file path: $($tokenInfo.TokenPath)" -ForegroundColor Gray
    Write-Host "- Token found: $($tokenInfo.TokenFound)" -ForegroundColor $(if ($tokenInfo.TokenFound) { "Green" } else { "Red" })
    Write-Host "- Token expired: $($tokenInfo.IsExpired)" -ForegroundColor $(if ($tokenInfo.IsExpired) { "Red" } else { "Green" })
    
    if ($tokenInfo.ExpirationTime) {
        Write-Host "- Expiration time: $($tokenInfo.ExpirationTime)" -ForegroundColor Gray
    }
    
    if ($tokenInfo.UserPrincipalName) {
        Write-Host "- Associated with: $($tokenInfo.UserPrincipalName)" -ForegroundColor Cyan
    }
    
    # Step 3: Connect to Intune if needed
    if ($Force -or -not $tokenInfo.TokenFound -or $tokenInfo.IsExpired) {
        Write-Host "`n=== CONNECTING TO MICROSOFT INTUNE ===" -ForegroundColor Cyan
        Write-Host "Requesting new authentication token..." -ForegroundColor Yellow
        
        $promptToken = Read-Host "Please paste your Intune authentication token"
        
        if (-not [string]::IsNullOrWhiteSpace($promptToken)) {
            $connected = Connect-IntuneWithToken -Token $promptToken -ShowScopes
            
            if ($connected) {
                $savedToken = Save-IntuneToken -Token $promptToken -ProfileName $ProfileName
                Write-Host "Token saved successfully for profile '$ProfileName'" -ForegroundColor Green
                Write-Host "- Token expires: $($savedToken.ExpirationTime)" -ForegroundColor Cyan
            }
            else {
                Write-Warning "Failed to connect with provided token. Please check the token and try again."
            }
        }
        else {
            Write-Error "No token provided. Cannot continue."
            exit 1
        }
    }
    else {
        Write-Host "`nExisting token is valid. Use -Force to override and request a new token." -ForegroundColor Green
    }
}
catch {
    Write-Error "Error in script execution: $_"
} 