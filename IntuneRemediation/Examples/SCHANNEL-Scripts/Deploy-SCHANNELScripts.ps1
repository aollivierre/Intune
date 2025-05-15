<#
.SYNOPSIS
    Signs and deploys SCHANNEL security scripts to Microsoft Intune
.DESCRIPTION
    This script signs all SCHANNEL remediation scripts with a code signing certificate
    and uploads them to Microsoft Intune as remediation script packages
.NOTES
    Author: Intune Administrator
    Version: 1.0
#>



# First, navigate to the scripts directory
# Set-Location 'C:\code\Intune\IntuneRemediation\Examples\SCHANNEL-Scripts'

# Then import the module from the parent directory
# Import-Module ..\..\IntuneRemediation.psd1 -ErrorAction Stop



# Edit the Import-Module line in Deploy-SCHANNELScripts.ps1 to:
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "IntuneRemediation.psd1"
Import-Module $modulePath -ErrorAction Stop

# Now run the deployment script
# .\Deploy-SCHANNELScripts.ps1

# Import the IntuneRemediation module
# Import-Module IntuneRemediation -ErrorAction Stop

# Configuration - Edit these values as needed
$CertificateThumbprint = "" # Leave empty to be prompted
$SignScripts = $true
$UploadToIntune = $true
$Publishers = "Security Administration Team"
$SCHANNELPrefix = "SCHANNEL"

# Category descriptions
$CategoryDescriptions = @{
    "ServerProtocols" = "Server-side protocol configurations for SCHANNEL security"
    "ClientProtocols" = "Client-side protocol configurations for SCHANNEL security"
    "Ciphers" = "Cipher suite configurations for SCHANNEL security"
    "Hashes" = "Cryptographic hash algorithm configurations for SCHANNEL security"
    "KeyExchanges" = "Key exchange algorithm configurations for SCHANNEL security"
}

# Category naming prefixes
$CategoryPrefixes = @{
    "ServerProtocols" = "SrvProto"
    "ClientProtocols" = "CliProto"
    "Ciphers" = "Cipher"
    "Hashes" = "Hash"
    "KeyExchanges" = "KeyEx"
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
        Protect-IntuneRemediationScript -ScriptPath $detectionPath -CertificateThumbprint $CertThumbprint
    }

    # Sign remediation scripts
    $remediationPath = Join-Path -Path $scriptBasePath -ChildPath "$Category\Remediation"
    if (Test-Path $remediationPath) {
        Write-Host "Signing remediation scripts in $remediationPath" -ForegroundColor Yellow
        Protect-IntuneRemediationScript -ScriptPath $remediationPath -CertificateThumbprint $CertThumbprint
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
                        } else {
                            # Add this line to our description
                            $detectionDesc += " " + $line.Trim()
                        }
                    } elseif ($line -match '^\s*\.DESCRIPTION') {
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
                    Category = $Category
                    BaseName = $baseName
                    DetectionScript = $detectionScript.FullName
                    RemediationScript = $remediationScript.FullName
                    DetectionContent = $detectionContent
                    RemediationContent = $remediationContent
                    Description = $detectionDesc
                }
            } else {
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
    } else {
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
        } else {
            Write-Warning "  - Failed to upload to Intune"
            return $false
        }
    } catch {
        Write-Error "  - Error uploading to Intune: $_"
        return $false
    }
}

# Main process
try {
    # Check Intune connection
    $tokenInfo = Get-IntuneTokenInfo -ShowScopes
    if (-not $tokenInfo -or $tokenInfo.IsExpired) {
        Write-Host "Connecting to Intune..." -ForegroundColor Yellow
        Initialize-IntuneConnection
    } else {
        Write-Host "Using existing Intune connection for $($tokenInfo.UserPrincipalName)" -ForegroundColor Green
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
        } else {
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
        
        foreach ($category in $categories) {
            Write-Host "`nProcessing category: $category" -ForegroundColor Cyan
            
            # Get script pairs for this category
            $scriptPairs = Get-ScriptPairs -Category $category
            $totalScripts += $scriptPairs.Count
            
            # Upload each script pair
            foreach ($scriptPair in $scriptPairs) {
                $result = Upload-ScriptPair -ScriptPair $scriptPair
                if ($result) { $uploadedScripts++ }
            }
        }
        
        Write-Host "`nSummary:" -ForegroundColor Cyan
        Write-Host "- Total script pairs processed: $totalScripts" -ForegroundColor White
        Write-Host "- Successfully uploaded to Intune: $uploadedScripts" -ForegroundColor $(if ($uploadedScripts -eq $totalScripts) { "Green" } else { "Yellow" })
        if ($uploadedScripts -ne $totalScripts) {
            Write-Host "- Failed to upload: $($totalScripts - $uploadedScripts)" -ForegroundColor Red
        }
    }
    
    Write-Host "`nSCHANNEL script deployment completed!" -ForegroundColor Green
} catch {
    Write-Error "Error in script execution: $_"
} 