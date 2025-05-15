[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProfileName = "Default",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$DoNotSave,
    
    [Parameter(Mandatory = $false)]
    [string]$Token,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipAuthentication
)

# Check PowerShell version - code signing works better in Windows PowerShell 5.1
if ($PSVersionTable.PSEdition -eq "Core") {
    Write-Warning "You are running this script in PowerShell Core ($($PSVersionTable.PSVersion))."
    Write-Warning "Code signing operations work more reliably in Windows PowerShell 5.1."
    Write-Warning "For best results, run this script in Windows PowerShell instead using:"
    Write-Host "powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -ForegroundColor Cyan
    
    $continue = Read-Host "Do you want to continue anyway? (Y/N)"
    if ($continue -ne "Y") {
        Write-Host "Script execution cancelled. Please run this script in Windows PowerShell 5.1." -ForegroundColor Yellow
        exit 0
    }
}

# Ensure we are in the script's directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath -Parent
Set-Location -Path $scriptDir

# Import the IntuneRemediation module
# Assuming the module is already installed or available in a parent directory
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















<#
.SYNOPSIS
    Signs and deploys SCHANNEL security scripts to Microsoft Intune
.DESCRIPTION
    This script signs all SCHANNEL remediation scripts with a code signing certificate
    and uploads them to Microsoft Intune as remediation script packages
.PARAMETER ProfileName
    Name of the token profile to use (default: "Default")
.PARAMETER Force
    Forces new authentication even if a valid token exists
.PARAMETER DoNotSave
    Does not save the token for future use
.PARAMETER Token
    Uses the specified token for authentication instead of interactive login
.PARAMETER SkipAuthentication
    Skips authentication to Intune entirely. Scripts will be signed but not uploaded.
.NOTES
    Author: Intune Administrator
    Version: 1.1
#>



# First, navigate to the scripts directory
# Set-Location 'C:\code\Intune\IntuneRemediation\Examples\SCHANNEL-Scripts'

# Then import the module from the parent directory
# Import-Module ..\..\IntuneRemediation.psd1 -ErrorAction Stop



# Edit the Import-Module line in Deploy-SCHANNELScripts.ps1 to:
# $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "IntuneRemediation.psd1"
# Import-Module $modulePath -ErrorAction Stop

# Now run the deployment script
# .\Deploy-SCHANNELScripts.ps1

# Import the IntuneRemediation module
# Import-Module IntuneRemediation -ErrorAction Stop

# Configuration - Edit these values as needed
$CertificateThumbprint = "" # Leave empty to be prompted
$SignScripts = $true
$UploadToIntune = $true
$Publishers = "Abdullah Ollivierre"
# $Publishers = "Security Administration Team"
$SCHANNELPrefix = "SCHANNEL"

# Category descriptions
$CategoryDescriptions = @{
    "ServerProtocols" = "Server-side protocol configurations for SCHANNEL security"
    "ClientProtocols" = "Client-side protocol configurations for SCHANNEL security"
    "Ciphers"         = "Cipher suite configurations for SCHANNEL security"
    "Hashes"          = "Cryptographic hash algorithm configurations for SCHANNEL security"
    "KeyExchanges"    = "Key exchange algorithm configurations for SCHANNEL security"
}

# Category naming prefixes
$CategoryPrefixes = @{
    "ServerProtocols" = "SrvProto"
    "ClientProtocols" = "CliProto"
    "Ciphers"         = "Cipher"
    "Hashes"          = "Hash"
    "KeyExchanges"    = "KeyEx"
}

# Base script path
$scriptBasePath = Join-Path -Path $PSScriptRoot -ChildPath ""

# Function to sign scripts in a category
function Sign-CategoryScripts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category,
        [Parameter(Mandatory = $true)]
        [string]$CertThumbprint
    )

    Write-Host "Signing scripts in category: $Category" -ForegroundColor Cyan

    # Sign detection scripts
    $detectionPath = Join-Path -Path $scriptBasePath -ChildPath "$Category\Detection"
    if (Test-Path $detectionPath) {
        Write-Host "Signing detection scripts in $detectionPath" -ForegroundColor Yellow
        Protect-IntuneRemediationScript -ScriptPath $detectionPath -CertificateThumbprint $CertThumbprint -SkipRevocationCheck
    }

    # Sign remediation scripts
    $remediationPath = Join-Path -Path $scriptBasePath -ChildPath "$Category\Remediation"
    if (Test-Path $remediationPath) {
        Write-Host "Signing remediation scripts in $remediationPath" -ForegroundColor Yellow
        Protect-IntuneRemediationScript -ScriptPath $remediationPath -CertificateThumbprint $CertThumbprint -SkipRevocationCheck
    }
}

# Function to get matching detection and remediation scripts
function Get-ScriptPairs {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    $pairs = @()
    $detectionPath = Join-Path -Path $scriptBasePath -ChildPath "$Category\Detection"
    $remediationPath = Join-Path -Path $scriptBasePath -ChildPath "$Category\Remediation"
    
    # Get all detection scripts
    if (Test-Path $detectionPath) {
        $detectionScripts = Get-ChildItem -Path $detectionPath -Filter "*.ps1"
        
        foreach ($detectionScript in $detectionScripts) {
            $detectionName = $detectionScript.Name
            $detectionContent = Get-Content -Path $detectionScript.FullName -Raw
            
            # Extract the base name from the detection script (remove Detect- prefix and .ps1 extension)
            $baseName = $detectionName -replace "^Detect-", "" -replace "\.ps1$", ""
            
            # Find matching remediation script
            $remediationPattern = "Remediate-$baseName.ps1"
            $alternatePattern = "Remediate-$($baseName -replace '-.*', '').ps1" # For cases like TLS1.0-Server -> TLS1.0
            
            $remediationScript = Get-ChildItem -Path $remediationPath -Filter $remediationPattern -ErrorAction SilentlyContinue
            if (-not $remediationScript) {
                $remediationScript = Get-ChildItem -Path $remediationPath -Filter $alternatePattern -ErrorAction SilentlyContinue
            }
            
            if ($remediationScript) {
                $remediationContent = Get-Content -Path $remediationScript.FullName -Raw
                
                # Extract description using a simpler line by line approach
                $detectionDesc = ""
                $lines = Get-Content -Path $detectionScript.FullName
                $inDescription = $false
                
                foreach ($line in $lines) {
                    if ($inDescription) {
                        # Check if we've reached the end of description
                        if ($line -match '^\s*\.[A-Z]' -or $line -match '^\s*#>') {
                            $inDescription = $false
                        }
                        else {
                            # Add this line to our description
                            $detectionDesc += " " + $line.Trim()
                        }
                    }
                    elseif ($line -match '^\s*\.DESCRIPTION') {
                        $inDescription = $true
                        # Extract any text after .DESCRIPTION on the same line
                        $afterDesc = $line -replace '^\s*\.DESCRIPTION\s*', ''
                        if ($afterDesc) {
                            $detectionDesc = $afterDesc.Trim()
                        }
                    }
                }
                
                # Clean up description
                $detectionDesc = $detectionDesc.Trim()
                
                $pairs += [PSCustomObject]@{
                    Category           = $Category
                    BaseName           = $baseName
                    DetectionScript    = $detectionScript.FullName
                    RemediationScript  = $remediationScript.FullName
                    DetectionContent   = $detectionContent
                    RemediationContent = $remediationContent
                    Description        = $detectionDesc
                }
            }
            else {
                Write-Warning "No matching remediation script found for detection script: $detectionName"
            }
        }
    }
    
    return $pairs
}

# Function to upload a script pair to Intune
function Upload-ScriptPair {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ScriptPair
    )
    
    $category = $ScriptPair.Category
    $baseName = $ScriptPair.BaseName
    
    # Generate Intune remediation script name with category prefix
    $categoryPrefix = $CategoryPrefixes[$category]
    $displayName = "$SCHANNELPrefix-$categoryPrefix-$baseName"
    
    # Generate description
    $description = if ($ScriptPair.Description) {
        $ScriptPair.Description
    }
    else {
        "Configures $baseName settings for $($CategoryDescriptions[$category])"
    }
    
    Write-Host "Uploading to Intune: $displayName" -ForegroundColor Cyan
    Write-Host "  - Description: $description" -ForegroundColor Gray
    
    try {
        # Upload to Intune
        $result = New-IntuneRemediationScript -DisplayName $displayName `
            -Description $description `
            -Publisher $Publishers `
            -DetectionScriptContent $ScriptPair.DetectionContent `
            -RemediationScriptContent $ScriptPair.RemediationContent `
            -RunAsAccount "System" `
            -RunAs32Bit:$false `
            -EnforceSignatureCheck:$true
        
        if ($result) {
            Write-Host "  - Successfully uploaded to Intune" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "  - Failed to upload to Intune"
            return $false
        }
    }
    catch {
        Write-Error "  - Error uploading to Intune: $_"
        return $false
    }
}

# Main process
try {

    # Check if authentication is being skipped
    if ($SkipAuthentication) {
        Write-Host "`n=== SKIPPING AUTHENTICATION ===" -ForegroundColor Cyan
        Write-Host "Authentication has been skipped as requested with -SkipAuthentication parameter." -ForegroundColor Yellow
        Write-Host "You will be able to sign scripts but not upload them to Intune." -ForegroundColor Yellow
        $connected = $false
        $UploadToIntune = $false
    }
    else {
        # Step 2: Check for saved tokens
        if (-not $Force) {
            Write-Host "`n=== CHECKING SAVED TOKENS ===" -ForegroundColor Cyan
        
            # Check for saved token
            $tokenInfo = Get-IntuneTokenInfo -ProfileName $ProfileName -ShowScopes
        
            if ($tokenInfo.TokenFound) {
                $isExpired = $tokenInfo.IsExpired
                $expiryInfo = if ($isExpired) {
                    if ($tokenInfo.ExpirationTime) {
                        "expired on $($tokenInfo.ExpirationTime.ToLocalTime())"
                    }
                    else {
                        "expired"
                    }
                }
                else {
                    if ($tokenInfo.ExpirationTime) {
                        "valid until $($tokenInfo.ExpirationTime.ToLocalTime())"
                    }
                    else {
                        "valid"
                    }
                }
            
                Write-Host "Found saved token for profile '$ProfileName'" -ForegroundColor Yellow
                if ($tokenInfo.UserInfo) {
                    Write-Host "  Associated with: $($tokenInfo.UserInfo)" -ForegroundColor Yellow
                }
                Write-Host "  Token status: $expiryInfo" -ForegroundColor $(if ($isExpired) { "Red" } else { "Green" })
                
                # Additional validation - load and check the actual token
                if (-not $isExpired) {
                    try {
                        $appDataPath = [Environment]::GetFolderPath('ApplicationData')
                        $tokenStoragePath = Join-Path -Path $appDataPath -ChildPath "IntuneRemediation\TokenStorage\$ProfileName"
                        $tokenPath = Join-Path -Path $tokenStoragePath -ChildPath "token.xml"
                        
                        if (Test-Path -Path $tokenPath) {
                            $secureToken = Import-Clixml -Path $tokenPath
                            $rawToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                            )
                            
                            # Try to decode token and verify expiration
                            $tokenParts = $rawToken.Split('.')
                            if ($tokenParts.Count -ge 2) {
                                $payload = $tokenParts[1].Replace('-', '+').Replace('_', '/')
                                while ($payload.Length % 4) { $payload += "=" }
                                
                                try {
                                    $decodedToken = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
                                    
                                    if ($decodedToken.exp) {
                                        $tokenExpTime = [DateTimeOffset]::FromUnixTimeSeconds($decodedToken.exp).DateTime.ToLocalTime()
                                        $now = Get-Date
                                        
                                        if ($tokenExpTime -lt $now) {
                                            Write-Warning "Token validation found the token has actually expired!"
                                            Write-Host "  Actual expiration: $tokenExpTime (decoded from token)" -ForegroundColor Red
                                            Write-Host "  Current time: $now" -ForegroundColor Yellow
                                            $isExpired = $true
                                            $Force = $true
                                        }
                                    }
                                }
                                catch {
                                    Write-Warning "Could not decode token for additional validation: $_"
                                    # Be cautious and consider it potentially expired
                                    $Force = $true
                                }
                            }
                        }
                    }
                    catch {
                        Write-Warning "Error during additional token validation: $_"
                    }
                }
            
                if ($isExpired) {
                    Write-Host "  The saved token has expired and a new one will be required." -ForegroundColor Yellow
                    $Force = $true
                }
            }
            else {
                Write-Host "No saved tokens found for profile '$ProfileName'." -ForegroundColor Yellow
            }
        }

        # Add note about role resolution
        Write-Host "`nNote: To view your actual assigned roles from Microsoft Entra ID (which may differ from token claims)," -ForegroundColor Yellow
        Write-Host "      use the Show-IntuneAssignedRoles function after connecting to Microsoft Graph." -ForegroundColor Yellow
        Write-Host "      Example: Show-IntuneAssignedRoles" -ForegroundColor Yellow

        # Step 3: Connect to Intune
        Write-Host "`n=== CONNECTING TO INTUNE ===" -ForegroundColor Cyan

        # Determine if we need to authenticate or can use a saved token
        $needAuthentication = $true
        $useFoundToken = $false

        # If we have a valid saved token and we're not forced to get a new one, use it
        if (-not $Force -and $tokenInfo.TokenFound -and -not $tokenInfo.IsExpired) {
            $needAuthentication = $false
            $useFoundToken = $true
            Write-Host "Using saved valid token for authentication..." -ForegroundColor Green
        }

        # Handle token authentication when needed
        if ($needAuthentication) {
            # If token is provided as parameter, use it
            if ($Token) {
                Write-Host "Using provided token parameter for authentication..." -ForegroundColor Yellow
            }
            # Otherwise, ask if user wants to provide a token manually
            else {
                # Check if user wants to provide a token instead of interactive authentication
                $useToken = Read-Host "Do you want to use a pre-acquired token instead of interactive authentication? (Y/N)"
            
                if ($useToken -eq 'Y') {
                    Write-Host "Please paste your token below and press Enter:" -ForegroundColor Yellow
                    $Token = Read-Host
                }
            }
        }

        # Connect to Intune based on our determined approach
        if ($useFoundToken) {
            # Get the saved token and use it
            try {
                $appDataPath = [Environment]::GetFolderPath('ApplicationData')
                $tokenStoragePath = Join-Path -Path $appDataPath -ChildPath "IntuneRemediation\TokenStorage\$ProfileName"
                $tokenPath = Join-Path -Path $tokenStoragePath -ChildPath "token.xml"
            
                if (Test-Path -Path $tokenPath) {
                    $secureToken = Import-Clixml -Path $tokenPath
                    $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                    )
                
                    # Connect with the saved token
                    $connected = $false
                    try {
                        # First try connecting with the saved token
                        $connected = Connect-IntuneWithToken -Token $Token -ShowScopes -SuppressWarnings -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "Error connecting with saved token: $($_.Exception.Message)"
                        Write-Host "The token may have expired despite the metadata showing it as valid." -ForegroundColor Yellow
                        Write-Host "Will try interactive authentication instead..." -ForegroundColor Yellow
                        $Token = $null
                        $needAuthentication = $true
                        $connected = $false
                    }
                
                    if (-not $connected) {
                        # Force a new token acquisition since this one failed even if it reports as valid
                        Write-Warning "Failed to connect with saved token. Starting interactive authentication..."
                        $Token = $null
                        $needAuthentication = $true
                    }
                }
                else {
                    throw "Token file not found"
                }
            }
            catch {
                Write-Warning "Error using saved token: $_"
                Write-Host "Will try interactive authentication instead..." -ForegroundColor Yellow
                $Token = $null
                $needAuthentication = $true
            }
        }
        # If we have a token (either provided or entered), use it
        elseif ($Token) {
            Write-Host "Using provided token for authentication..." -ForegroundColor Yellow
        
            # Connect with the token showing available scopes and suppressing redundant warnings
            $connected = Connect-IntuneWithToken -Token $Token -ShowScopes -SuppressWarnings
        
            # Save the token if connection was successful and user didn't specify DoNotSave
            if ($connected -and -not $DoNotSave) {
                Write-Host "Saving token for future use..." -ForegroundColor Yellow
                $saved = Save-IntuneToken -Token $Token -ProfileName $ProfileName
            
                if ($saved) {
                    Write-Host "Token saved successfully for profile '$ProfileName'!" -ForegroundColor Green
                }
                else {
                    Write-Warning "Could not save token for future use."
                }
            }
            elseif ($connected -and $DoNotSave) {
                Write-Host "Token was not saved as -DoNotSave was specified." -ForegroundColor Yellow
            }
        }
        else {
            # Normal authentication flow
            if ($SkipAuthentication) {
                Write-Host "Authentication skipped as requested with -SkipAuthentication parameter." -ForegroundColor Yellow
                Write-Host "You will be able to sign scripts but not upload them to Intune." -ForegroundColor Yellow
                $connected = $false
                $UploadToIntune = $false
            }
            else {
                Write-Host "Using interactive authentication..." -ForegroundColor Yellow
                
                # Try interactive authentication with better error handling
                $authAttempts = 0
                $maxAttempts = 3
                $connected = $false
                
                while (-not $connected -and $authAttempts -lt $maxAttempts) {
                    $authAttempts++
                    
                    try {
                        # Connect to Intune with token management
                        $connected = Initialize-IntuneConnection -ProfileName $ProfileName -ForceBrowser:$true -SaveTokenForReuse:(-not $DoNotSave) -ErrorAction Stop
                        
                        if ($connected) {
                            Write-Host "Successfully connected to Intune on attempt $authAttempts." -ForegroundColor Green
                            break
                        }
                    }
                    catch {
                        Write-Warning "Authentication attempt $authAttempts failed: $($_.Exception.Message)"
                        
                        if ($authAttempts -lt $maxAttempts) {
                            Write-Host "Retrying in 3 seconds..." -ForegroundColor Yellow
                            Start-Sleep -Seconds 3
                        }
                        else {
                            Write-Warning "All authentication attempts failed."
                        }
                    }
                }
                
                # If all attempts failed, ask if user wants to continue without authentication
                if (-not $connected) {
                    Write-Warning "Unable to authenticate to Microsoft Intune after $maxAttempts attempts."
                    $skipAuth = Read-Host "Would you like to continue without authentication? You will be able to sign scripts but not upload them to Intune. (Y/N)"
                    
                    if ($skipAuth -eq 'Y') {
                        Write-Host "Continuing without authentication. Script signing only." -ForegroundColor Yellow
                        $UploadToIntune = $false
                    }
                    else {
                        Write-Error "Authentication required but failed. Exiting script."
                        exit 1
                    }
                }
            }
        }
    }

    # Skip connection verification and role display if authentication was skipped
    if (-not $SkipAuthentication) {
        if (-not $connected) {
            Write-Error "Failed to connect to Intune. Please check your token and try again."
            exit 1
        }

        # Verify Graph connection is still active before showing roles
        $graphConnected = $false
        try {
            $mgContext = Get-MgContext -ErrorAction Stop
            if ($mgContext) {
                $graphConnected = $true
            }
        }
        catch {
            Write-Warning "Lost connection to Microsoft Graph. The token may have expired."
            $graphConnected = $false
        }

        # If Graph connection was lost, try interactive auth
        if (-not $graphConnected) {
            Write-Host "Attempting to reconnect to Microsoft Graph..." -ForegroundColor Yellow
            try {
                # Try interactive auth to reconnect
                $connected = Initialize-IntuneConnection -ProfileName $ProfileName -ForceBrowser:$true -SaveTokenForReuse:(-not $DoNotSave)
                if (-not $connected) {
                    Write-Error "Could not reconnect to Microsoft Graph. Continuing with certificate selection only."
                }
            }
            catch {
                Write-Warning "Error reconnecting to Microsoft Graph: $_"
            }
        }

        # Show actual assigned roles from Microsoft Entra ID
        Write-Host "`n=== YOUR ACTUAL ASSIGNED ROLES ===" -ForegroundColor Cyan
        Write-Host "Querying Microsoft Graph for your actual role assignments..." -ForegroundColor Yellow
        
        # Temporarily suppress verbose output for role display
        $oldVerbosePreference = $VerbosePreference
        $VerbosePreference = 'SilentlyContinue'
        
        # Only show assigned roles, without re-displaying token information
        # Skip if we know Graph connection is not active
        if ($graphConnected -or $connected) {
            Show-IntuneAssignedRoles -FallbackToToken
        }
        else {
            Write-Warning "Skipping role display as no active Graph connection is available."
            Write-Host "Continuing with certificate selection..." -ForegroundColor Yellow
        }
        
        # Restore verbose preference
        $VerbosePreference = $oldVerbosePreference
    }
    else {
        Write-Host "`n=== SKIPPING ROLE DISPLAY ===" -ForegroundColor Cyan
        Write-Host "Role display has been skipped as authentication was not performed." -ForegroundColor Yellow
    }

    # Get certificate thumbprint if not provided
    if (-not $CertificateThumbprint -and $SignScripts) {
        # Find available certificates
        $certificates = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.NotAfter -gt (Get-Date) }
        
        if ($certificates.Count -eq 0) {
            Write-Error "No valid code signing certificates found in your certificate store."
            exit 1
        }
        
        # List available certificates
        Write-Host "Available code signing certificates:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $certificates.Count; $i++) {
            Write-Host "[$i] $($certificates[$i].Subject) - Expires: $($certificates[$i].NotAfter) - Thumbprint: $($certificates[$i].Thumbprint)" -ForegroundColor White
        }
        
        # Ask user to select a certificate
        $selection = Read-Host "Enter the number of the certificate to use [0-$($certificates.Count - 1)]"
        if ($selection -match "^\d+$" -and [int]$selection -ge 0 -and [int]$selection -lt $certificates.Count) {
            $CertificateThumbprint = $certificates[[int]$selection].Thumbprint
            Write-Host "Using certificate with thumbprint: $CertificateThumbprint" -ForegroundColor Green
        }
        else {
            Write-Error "Invalid selection."
            exit 1
        }
    }
    
    # Get all categories
    $categories = @("ServerProtocols", "ClientProtocols", "Ciphers", "Hashes", "KeyExchanges")
    
    # Sign scripts if requested
    if ($SignScripts) {
        foreach ($category in $categories) {
            Sign-CategoryScripts -Category $category -CertThumbprint $CertificateThumbprint
        }
    }
    
    # Upload scripts if requested
    if ($UploadToIntune) {
        $totalScripts = 0
        $uploadedScripts = 0
        $failedScripts = 0
        
        foreach ($category in $categories) {
            Write-Host "`nProcessing category: $category" -ForegroundColor Cyan
            
            # Get script pairs for this category
            $scriptPairs = Get-ScriptPairs -Category $category
            
            # Count script pairs found in this category
            if ($scriptPairs -and $scriptPairs.Count -gt 0) {
                $totalScripts += $scriptPairs.Count
                
                # Upload each script pair
                foreach ($scriptPair in $scriptPairs) {
                    $result = Upload-ScriptPair -ScriptPair $scriptPair
                    if ($result) { 
                        $uploadedScripts++ 
                    } else {
                        $failedScripts++
                    }
                }
            }
        }
        
        Write-Host "`nSummary:" -ForegroundColor Cyan
        Write-Host "- Total script pairs processed: $totalScripts" -ForegroundColor White
        Write-Host "- Successfully uploaded to Intune: $uploadedScripts" -ForegroundColor $(if ($uploadedScripts -eq $totalScripts) { "Green" } else { "Yellow" })
        if ($failedScripts -gt 0) {
            Write-Host "- Failed to upload: $failedScripts" -ForegroundColor Red
        }
    }
    
    Write-Host "`nSCHANNEL script deployment completed!" -ForegroundColor Green
}
catch {
    Write-Error "Error in script execution: $_"
} 