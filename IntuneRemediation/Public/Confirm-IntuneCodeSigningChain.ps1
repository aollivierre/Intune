function Confirm-IntuneCodeSigningChain {
    <#
    .SYNOPSIS
        Verifies and installs the certificate chain for a code signing certificate.
        
    .DESCRIPTION
        This function checks if a certificate's chain is complete and trusted. If issues are found,
        it offers to install missing certificates in the chain to the appropriate certificate stores.
        
    .PARAMETER Certificate
        The code signing certificate object to verify the chain for.
        
    .PARAMETER AutoInstall
        If specified, automatically installs missing certificates without prompting.
        
    .PARAMETER SkipPrompt
        If specified, doesn't prompt for installation of missing certificates. 
        Useful for automation scenarios.
        
    .PARAMETER SkipRevocationCheck
        If specified, skips online revocation checking which can fail when revocation servers are unavailable.
        
    .EXAMPLE
        $cert = Get-Item -Path "Cert:\CurrentUser\My\1234567890ABCDEF1234567890ABCDEF12345678"
        Confirm-IntuneCodeSigningChain -Certificate $cert
        
        Checks if the certificate chain is valid and prompts to install missing certificates if needed.
        
    .EXAMPLE
        $cert = Get-Item -Path "Cert:\CurrentUser\My\1234567890ABCDEF1234567890ABCDEF12345678"
        Confirm-IntuneCodeSigningChain -Certificate $cert -AutoInstall
        
        Checks if the certificate chain is valid and automatically installs missing certificates.

    .EXAMPLE
        $cert = Get-Item -Path "Cert:\CurrentUser\My\1234567890ABCDEF1234567890ABCDEF12345678"
        Confirm-IntuneCodeSigningChain -Certificate $cert -SkipRevocationCheck
        
        Checks if the certificate chain is valid without performing online revocation checks.
        
    .NOTES
        This function helps ensure that code signing operations don't fail due to certificate chain issues.
        
    .OUTPUTS
        [bool] True if the certificate chain is valid or was successfully installed, False otherwise.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoInstall,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipPrompt,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipRevocationCheck
    )
    
    try {
        Write-Verbose "Checking certificate chain for $($Certificate.Subject) (Thumbprint: $($Certificate.Thumbprint))"
        
        # Create a new chain object
        $chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
        
        # Configure chain building parameters
        if ($SkipRevocationCheck) {
            $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
            Write-Verbose "Skipping revocation checking as requested"
        } else {
            $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Online
        }
        $chain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509Certificates.X509RevocationFlag]::EntireChain
        $chain.ChainPolicy.VerificationFlags = [System.Security.Cryptography.X509Certificates.X509VerificationFlags]::NoFlag
        
        # Build the chain
        $chainBuilt = $chain.Build($Certificate)
        
        # If chain built successfully with no issues
        if ($chainBuilt -and $chain.ChainStatus.Length -eq 0) {
            Write-Verbose "Certificate chain is valid and trusted"
            return $true
        }
        
        # Chain has issues
        Write-Warning "Certificate chain has issues:"
        foreach ($status in $chain.ChainStatus) {
            Write-Warning "  - $($status.StatusInformation.Trim())"
        }
        
        # Check if we should proceed with installation
        $shouldInstall = $false
        
        if ($AutoInstall) {
            $shouldInstall = $true
        }
        elseif (-not $SkipPrompt) {
            $response = Read-Host "Do you want to install missing certificates in the chain? (Y/N)"
            $shouldInstall = ($response -eq 'Y')
        }
        
        # Install certificates if needed
        if ($shouldInstall) {
            Write-Host "Installing certificates in the chain..." -ForegroundColor Yellow
            
            $installedCount = 0
            
            # Skip the first certificate (that's the one we're checking)
            for ($i = 1; $i -lt $chain.ChainElements.Count; $i++) {
                $cert = $chain.ChainElements[$i].Certificate
                
                # Determine appropriate store based on certificate type
                $store = if ($cert.Subject -match "Root" -or
                          ([string]::IsNullOrEmpty($cert.Subject) -and [string]::IsNullOrEmpty($cert.Issuer)) -or
                          ($cert.Subject -eq $cert.Issuer)) {
                    # This is likely a root certificate
                    "Root"
                }
                else {
                    # This is likely an intermediate certificate
                    "CA"
                }
                
                Write-Verbose "Certificate $($cert.Subject) will be installed to $store store"
                
                # Open certificate store
                $certStore = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Store -ArgumentList $store, "CurrentUser"
                $certStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
                
                # Check if certificate is already in the store
                $existingCert = $certStore.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
                
                if ($existingCert) {
                    Write-Verbose "Certificate already exists in store: $($cert.Subject) (Thumbprint: $($cert.Thumbprint))"
                }
                else {
                    # Install certificate
                    $certStore.Add($cert)
                    $installedCount++
                    Write-Host "Installed certificate to CurrentUser\$store store: $($cert.Subject)" -ForegroundColor Green
                    Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
                }
                
                $certStore.Close()
            }
            
            if ($installedCount -gt 0) {
                Write-Host "Installed $installedCount certificates to complete the chain" -ForegroundColor Green
                
                # Verify the chain again
                $newChain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
                if ($SkipRevocationCheck) {
                    $newChain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
                }
                $newChainBuilt = $newChain.Build($Certificate)
                
                if ($newChainBuilt -and $newChain.ChainStatus.Length -eq 0) {
                    Write-Host "Certificate chain is now valid and trusted" -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Warning "Certificate chain still has issues after installing certificates:"
                    foreach ($status in $newChain.ChainStatus) {
                        Write-Warning "  - $($status.StatusInformation.Trim())"
                    }
                    return $false
                }
            }
            else {
                Write-Host "No new certificates were installed" -ForegroundColor Yellow
                return $false
            }
        }
        else {
            Write-Warning "Certificate chain validation failed and no certificates were installed"
            return $false
        }
    }
    catch {
        Write-Error "Error verifying certificate chain: $_"
        return $false
    }
}

# Export this function
Export-ModuleMember -Function Confirm-IntuneCodeSigningChain 