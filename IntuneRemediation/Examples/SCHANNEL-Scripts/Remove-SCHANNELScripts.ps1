[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProfileName = "Default",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [string]$Token,
    
    [Parameter(Mandatory = $false)]
    [string]$SCHANNELPrefix = "SCHANNEL",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

<#
.SYNOPSIS
    Safely removes SCHANNEL remediation scripts from Microsoft Intune
.DESCRIPTION
    This script connects to Microsoft Intune, finds all remediation scripts with
    the specified prefix (default: "SCHANNEL"), displays them for confirmation,
    and then removes them only after explicit user approval.
.PARAMETER ProfileName
    Name of the token profile to use (default: "Default")
.PARAMETER Force
    Forces new authentication even if a valid token exists
.PARAMETER Token
    Uses the specified token for authentication instead of interactive login
.PARAMETER SCHANNELPrefix
    The prefix used to identify SCHANNEL scripts (default: "SCHANNEL")
.PARAMETER WhatIf
    Shows what would happen if the script runs without actually making changes
.EXAMPLE
    .\Remove-SCHANNELScripts.ps1
    
    Connects to Intune, finds all SCHANNEL remediation scripts, and asks for confirmation before removal.
.EXAMPLE
    .\Remove-SCHANNELScripts.ps1 -WhatIf
    
    Shows which scripts would be removed without actually removing them.
.EXAMPLE
    .\Remove-SCHANNELScripts.ps1 -SCHANNELPrefix "CUSTOM-SCHANNEL"
    
    Finds and removes scripts with a custom prefix.
.NOTES
    Author: Intune Administrator
    Version: 1.0
    Safety Features:
    - Only targets scripts with the exact SCHANNEL prefix (or custom prefix)
    - Shows scripts to be removed and requires explicit confirmation
    - Offers a -WhatIf parameter to see what would be removed without making changes
    - Double confirmation for large numbers of scripts
    - Script count verification before proceeding
#>

# Ensure we are in the script's directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath -Parent
Set-Location -Path $scriptDir

# Import the IntuneRemediation module
try {
    $modulePath = (Get-Item -Path $scriptDir).Parent.Parent.FullName
    Import-Module -Name "$modulePath\IntuneRemediation.psd1" -Force -ErrorAction Stop
    Write-Host "IntuneRemediation module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to import IntuneRemediation module: $_"
    Write-Host "Please ensure the module is installed or adjust the path accordingly." -ForegroundColor Yellow
    exit 1
}

# Script removal function with safety checks
function Remove-IntuneRemediationScripts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Scripts,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    $totalScripts = $Scripts.Count
    $removedScripts = 0
    $failedScripts = 0
    
    Write-Host "`nRemoving $totalScripts SCHANNEL remediation scripts from Intune..." -ForegroundColor Cyan
    
    foreach ($script in $Scripts) {
        $displayName = $script.displayName
        $id = $script.id
        
        if ($WhatIf) {
            Write-Host "  [WhatIf] Would remove: $displayName (ID: $id)" -ForegroundColor Yellow
            $removedScripts++
            continue
        }
        
        Write-Host "  Removing: $displayName..." -ForegroundColor Yellow -NoNewline
        
        try {
            # Make the removal call to the Microsoft Graph API
            $url = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$id"
            Invoke-MgGraphRequest -Method DELETE -Uri $url | Out-Null
            
            Write-Host " Success!" -ForegroundColor Green
            $removedScripts++
        }
        catch {
            Write-Host " Failed!" -ForegroundColor Red
            Write-Warning "    Error: $($_.Exception.Message)"
            $failedScripts++
        }
    }
    
    # Show summary
    Write-Host "`nSummary:" -ForegroundColor Cyan
    if ($WhatIf) {
        Write-Host "- [WhatIf] Scripts that would be removed: $removedScripts" -ForegroundColor Yellow
    }
    else {
        Write-Host "- Successfully removed: $removedScripts" -ForegroundColor $(if ($removedScripts -eq $totalScripts) { "Green" } else { "Yellow" })
        if ($failedScripts -gt 0) {
            Write-Host "- Failed to remove: $failedScripts" -ForegroundColor Red
        }
    }
}

# Main process
try {
    # Step 1: Connect to Intune and Microsoft Graph
    Write-Host "`n=== CONNECTING TO MICROSOFT INTUNE ===" -ForegroundColor Cyan
    
    # Determine if we need to authenticate or can use a saved token
    $connected = $false
    
    if ($Token) {
        # Use provided token
        Write-Host "Using provided token for authentication..." -ForegroundColor Yellow
        $connected = Connect-IntuneWithToken -Token $Token -ShowScopes
    }
    else {
        # Check for saved token if not forcing authentication
        $useFoundToken = $false
        
        if (-not $Force) {
            # Use Get-IntuneTokenInfo to check for tokens (which should now use the correct path)
            $tokenInfo = Get-IntuneTokenInfo -ProfileName $ProfileName -Verbose
            
            Write-Host "Token status check results:" -ForegroundColor Yellow
            Write-Host "- Token file path: $($tokenInfo.TokenPath)" -ForegroundColor Gray
            
            # Also check the file directly to verify it exists
            $exists = Test-Path -Path $tokenInfo.TokenPath
            Write-Host "- Token file exists check: $exists" -ForegroundColor $(if ($exists) { "Green" } else { "Red" })
            
            Write-Host "- Token found: $($tokenInfo.TokenFound)" -ForegroundColor $(if ($tokenInfo.TokenFound) { "Green" } else { "Red" })
            Write-Host "- Token expired: $($tokenInfo.IsExpired)" -ForegroundColor $(if ($tokenInfo.IsExpired) { "Red" } else { "Green" })
            if ($tokenInfo.ExpirationTime) {
                Write-Host "- Expiration time: $($tokenInfo.ExpirationTime)" -ForegroundColor Gray
            }
            
            # Provide more diagnostic information using the path from tokenInfo
            if ($tokenInfo.TokenPath) {
                $tokenParentPath = Split-Path -Parent $tokenInfo.TokenPath
                Write-Host "Looking for tokens in: $tokenParentPath" -ForegroundColor Yellow
                if (Test-Path $tokenParentPath) {
                    $tokenFiles = Get-ChildItem -Path $tokenParentPath -Filter "*.xml" | Select-Object -ExpandProperty Name
                    Write-Host "Found token files: $($tokenFiles -join ', ')" -ForegroundColor Gray
                }
            }
            
            if ($tokenInfo.TokenFound -and -not $tokenInfo.IsExpired) {
                $useFoundToken = $true
                Write-Host "Using saved token for profile '$ProfileName'..." -ForegroundColor Green
                
                # Use the Get-IntuneToken function to retrieve the token
                try {
                    $tokenValue = Get-IntuneToken -ProfileName $ProfileName -Verbose
                    Write-Host "Token retrieval attempt result: " -NoNewline
                    
                    if ($tokenValue) {
                        Write-Host "SUCCESS - Token retrieved" -ForegroundColor Green
                        
                        # Connect with the token
                        Write-Host "Attempting to connect with token..." -ForegroundColor Yellow
                        $connected = Connect-IntuneWithToken -Token $tokenValue -SuppressWarnings
                        
                        if ($connected) {
                            Write-Host "Successfully connected with token!" -ForegroundColor Green
                        } else {
                            Write-Warning "Token retrieved but connection failed. Token may be invalid."
                            $useFoundToken = $false
                        }
                    } else {
                        Write-Host "FAILED - No token retrieved" -ForegroundColor Red
                        Write-Warning "Token was found but could not be retrieved or validated."
                        $useFoundToken = $false
                    }
                }
                catch {
                    Write-Warning "Error using saved token: $_"
                    $useFoundToken = $false
                }
            }
        }
        
        # If no token found or forced auth, prompt for token
        if (-not $useFoundToken -or -not $connected) {
            $promptToken = Read-Host "No valid token found. Please paste your Intune authentication token"
            
            if (-not [string]::IsNullOrWhiteSpace($promptToken)) {
                Write-Host "Using provided token..." -ForegroundColor Yellow
                $connected = Connect-IntuneWithToken -Token $promptToken -ShowScopes
                
                # Automatically save the token without prompting
                if ($connected) {
                    Write-Host "Token validation successful, saving token..." -ForegroundColor Yellow
                    $tokenInfo = Save-IntuneToken -Token $promptToken -ProfileName $ProfileName -Verbose
                    Write-Host "Token automatically saved for profile '$ProfileName'" -ForegroundColor Green
                    Write-Host "- Token expires: $($tokenInfo.ExpirationTime)" -ForegroundColor Cyan
                    Write-Host "- Associated with: $($tokenInfo.UserPrincipalName)" -ForegroundColor Cyan
                } else {
                    Write-Warning "Token connection failed. Token was not saved."
                }
            }
            else {
                Write-Error "No token provided. Cannot continue."
                exit 1
            }
        }
    }
    
    if (-not $connected) {
        throw "Failed to connect to Microsoft Intune. Please try again or provide a valid token."
    }
    
    # Step 2: Fetch all remediation scripts from Intune
    Write-Host "`n=== SEARCHING FOR SCHANNEL REMEDIATION SCRIPTS ===" -ForegroundColor Cyan
    Write-Host "Looking for scripts with prefix: $SCHANNELPrefix" -ForegroundColor Yellow
    
    # Use Microsoft Graph to get all deviceHealthScripts (remediation scripts)
    $url = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
    $response = Invoke-MgGraphRequest -Method GET -Uri $url
    $allScripts = $response.value
    
    # Filter scripts to only those with the SCHANNEL prefix
    $schannel_scripts = $allScripts | Where-Object { $_.displayName -like "$SCHANNELPrefix*" }
    $total_schannel_scripts = $schannel_scripts.Count
    
    if ($total_schannel_scripts -eq 0) {
        Write-Host "`nNo remediation scripts found with prefix '$SCHANNELPrefix'." -ForegroundColor Yellow
        Write-Host "Nothing to remove. Exiting script." -ForegroundColor Green
        exit 0
    }
    
    # Step 3: Display the scripts and confirm removal
    Write-Host "`nFound $total_schannel_scripts remediation scripts with prefix '$SCHANNELPrefix':" -ForegroundColor Green
    
    # Display script information
    $i = 1
    foreach ($script in $schannel_scripts) {
        Write-Host "  $i. $($script.displayName)"
        Write-Host "     ID: $($script.id)"
        Write-Host "     Description: $($script.description)"
        Write-Host "     Publisher: $($script.publisher)"
        Write-Host "     Created: $($script.createdDateTime)"
        $i++
    }
    
    # Safety confirmation process
    if ($WhatIf) {
        Write-Host "`n[WhatIf Mode] The above $total_schannel_scripts scripts would be removed from Intune." -ForegroundColor Yellow
        $confirmDelete = "Y"  # Auto-confirm in WhatIf mode since no actual changes will be made
    }
    else {
        Write-Host "`n" -NoNewline
        Write-Host "!!! WARNING: You are about to PERMANENTLY DELETE $total_schannel_scripts remediation scripts from Intune !!!" -ForegroundColor Red
        Write-Host "All scripts with the prefix '$SCHANNELPrefix' will be removed." -ForegroundColor Yellow
        
        # First confirmation
        $confirmDelete = Read-Host "Are you sure you want to proceed with removal? Type 'Y' to confirm or any other key to cancel"
        
        # Extra confirmation for large numbers of scripts
        if ($confirmDelete -eq "Y" -and $total_schannel_scripts -gt 5) {
            Write-Host "`nYou are about to remove $total_schannel_scripts scripts. This is a significant number." -ForegroundColor Red
            $confirmCount = Read-Host "Please type the number of scripts to be removed to confirm ($total_schannel_scripts)"
            
            if ($confirmCount -ne $total_schannel_scripts.ToString()) {
                Write-Host "Confirmation failed. The number entered does not match the number of scripts to be removed." -ForegroundColor Red
                throw "Removal canceled due to confirmation mismatch."
            }
        }
    }
    
    # Step 4: Perform the removal if confirmed
    if ($confirmDelete -eq "Y") {
        Remove-IntuneRemediationScripts -Scripts $schannel_scripts -WhatIf:$WhatIf
        
        if (-not $WhatIf) {
            Write-Host "`nSCHANNEL remediation scripts have been successfully removed from Intune!" -ForegroundColor Green
        }
        else {
            Write-Host "`n[WhatIf Mode] No changes were made. Run without -WhatIf to actually remove the scripts." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`nScript removal canceled. No changes were made." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Error in script execution: $_"
}