<#
.SYNOPSIS
    Enhanced script signing function with better error handling.

.DESCRIPTION
    This function is an enhanced version of Protect-IntuneRemediationScript
    with improved error handling, diagnostic information, and flexible
    certificate handling options.

.PARAMETER ScriptPath
    Path to the script(s) to sign.

.PARAMETER CertificateFolder
    Folder containing the certificate file.

.PARAMETER CertificateFile
    Name of the certificate file to use (PFX format).

.PARAMETER CertificateThumbprint
    Thumbprint of a certificate in the certificate store. If specified,
    CertificateFolder and CertificateFile are ignored.

.PARAMETER UseUserStore
    Use the user's certificate store instead of the machine store.

.PARAMETER Verbose
    Show detailed progress and diagnostic information.

.EXAMPLE
    Protect-Script -ScriptPath "C:\Scripts\MyScript.ps1" -CertificateFolder "C:\temp\certs" -CertificateFile "MyCert.pfx"

.EXAMPLE
    Protect-Script -ScriptPath "C:\Scripts\MyScript.ps1" -CertificateThumbprint "1234567890ABCDEF1234567890ABCDEF12345678"
#>
function Protect-Script {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string]$CertificateFolder = "C:\temp\certs",
        
        [Parameter(Mandatory = $false)]
        [string]$CertificateFile = "",
        
        [Parameter(Mandatory = $false)]
        [string]$CertificateThumbprint = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseUserStore
    )
    
    # Banner
    Write-Host "`n====================================================="
    Write-Host "       Enhanced Intune Script Signing Utility"
    Write-Host "=====================================================`n"
    
    # Track results
    $results = @{
        TotalScripts = 0
        SuccessfullySigned = 0
        FailedToSign = 0
        StartTime = Get-Date
    }
    
    # Validate input
    $validScriptPaths = @()
    foreach ($path in $ScriptPath) {
        if (Test-Path -Path $path) {
            $validScriptPaths += $path
        }
        else {
            Write-Warning "Script not found: $path"
        }
    }
    
    if ($validScriptPaths.Count -eq 0) {
        Write-Error "No valid script paths provided."
        return $false
    }
    
    $results.TotalScripts = $validScriptPaths.Count
    
    # Get the certificate
    $certificate = $null
    
    if ($CertificateThumbprint) {
        Write-Host "Searching for certificate with thumbprint: $CertificateThumbprint" -ForegroundColor Yellow
        
        # Determine which store to use
        $storeLocation = if ($UseUserStore) { "CurrentUser" } else { "LocalMachine" }
        
        try {
            # Try to find certificate in personal store
            $certificate = Get-Item -Path "Cert:\$storeLocation\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
            
            if (-not $certificate) {
                # Try other stores if not found in personal
                $stores = @("My", "TrustedPublisher", "Root", "TrustedPeople")
                
                foreach ($store in $stores) {
                    $certificate = Get-Item -Path "Cert:\$storeLocation\$store\$CertificateThumbprint" -ErrorAction SilentlyContinue
                    if ($certificate) { 
                        Write-Host "Found certificate in $storeLocation\$store store." -ForegroundColor Green
                        break 
                    }
                }
            }
            else {
                Write-Host "Found certificate in $storeLocation\My store." -ForegroundColor Green
            }
            
            if (-not $certificate) {
                Write-Error "Certificate with thumbprint $CertificateThumbprint not found in $storeLocation stores."
                return $false
            }
        }
        catch {
            Write-Error "Error accessing certificate stores: $_"
            return $false
        }
    }
    else {
        # Look for certificate file
        if (-not (Test-Path -Path $CertificateFolder)) {
            Write-Error "Certificate folder not found: $CertificateFolder"
            return $false
        }
        
        # If no specific file is provided, look for PFX files
        if ([string]::IsNullOrEmpty($CertificateFile)) {
            $pfxFiles = Get-ChildItem -Path $CertificateFolder -Filter "*.pfx"
            
            if ($pfxFiles.Count -eq 0) {
                Write-Error "No .pfx files found in $CertificateFolder"
                return $false
            }
            
            Write-Host "Searching for certificates in: $CertificateFolder" -ForegroundColor Yellow
            Write-Host "Found $($pfxFiles.Count) certificate files:" -ForegroundColor Yellow
            $pfxFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Yellow }
            
            # Use the first PFX file found or prompt to select one
            if ($pfxFiles.Count -eq 1) {
                $CertificateFile = $pfxFiles[0].Name
                Write-Host "Using certificate: $CertificateFile" -ForegroundColor Yellow
            }
            else {
                # Display a menu for certificate selection
                Write-Host "`nMultiple certificates found. Please select one:" -ForegroundColor Cyan
                for ($i = 0; $i -lt $pfxFiles.Count; $i++) {
                    Write-Host "  $($i+1). $($pfxFiles[$i].Name)" -ForegroundColor Yellow
                }
                
                $selection = 0
                while ($selection -lt 1 -or $selection -gt $pfxFiles.Count) {
                    try {
                        $selection = [int](Read-Host "Enter selection (1-$($pfxFiles.Count))")
                    }
                    catch {
                        Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
                    }
                }
                
                $CertificateFile = $pfxFiles[$selection-1].Name
                Write-Host "Selected certificate: $CertificateFile" -ForegroundColor Yellow
            }
        }
        
        $certPath = Join-Path -Path $CertificateFolder -ChildPath $CertificateFile
        
        if (-not (Test-Path -Path $certPath)) {
            Write-Error "Certificate file not found: $certPath"
            return $false
        }
        
        # Prompt for password
        $certPassword = Read-Host -Prompt "Enter password for certificate $CertificateFile" -AsSecureString
        
        try {
            # Try different flag combinations for maximum compatibility
            $flags = @(
                [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"Exportable,PersistKeySet,MachineKeySet",
                [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"Exportable,PersistKeySet,UserKeySet",
                [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"Exportable,UserKeySet",
                [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"PersistKeySet,MachineKeySet"
            )
            
            $certificate = $null
            $errorMessage = ""
            
            foreach ($flag in $flags) {
                try {
                    Write-Verbose "Trying to load certificate with flags: $flag"
                    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $certPassword, $flag)
                    
                    if ($certificate -and $certificate.HasPrivateKey) {
                        Write-Verbose "Successfully loaded certificate with flags: $flag"
                        break
                    }
                    else {
                        if ($certificate) { $certificate.Reset() }
                        $certificate = $null
                    }
                }
                catch {
                    $errorMessage = $_
                    Write-Verbose "Failed with flags $flag`: $_"
                    if ($certificate) { $certificate.Reset() }
                    $certificate = $null
                }
            }
            
            if (-not $certificate) {
                Write-Error "Failed to load certificate: $errorMessage"
                return $false
            }
        }
        catch {
            Write-Error "Error loading certificate: $_"
            return $false
        }
    }
    
    # Display certificate information
    Write-Host "`nUsing certificate:" -ForegroundColor Cyan
    Write-Host "  Subject: $($certificate.Subject)" -ForegroundColor Yellow
    Write-Host "  Issuer: $($certificate.Issuer)" -ForegroundColor Yellow
    Write-Host "  Thumbprint: $($certificate.Thumbprint)" -ForegroundColor Yellow
    Write-Host "  Valid from: $($certificate.NotBefore) to $($certificate.NotAfter)" -ForegroundColor Yellow
    Write-Host "  Has private key: $($certificate.HasPrivateKey)" -ForegroundColor $(if ($certificate.HasPrivateKey) { "Green" } else { "Red" })
    
    # Check certificate validity
    $now = Get-Date
    if ($certificate.NotBefore -gt $now) {
        Write-Error "Certificate is not yet valid. Valid from: $($certificate.NotBefore)"
        return $false
    }
    
    if ($certificate.NotAfter -lt $now) {
        Write-Error "Certificate has expired. Valid until: $($certificate.NotAfter)"
        return $false
    }
    
    if (-not $certificate.HasPrivateKey) {
        Write-Error "Certificate does not have a private key. Cannot sign with this certificate."
        return $false
    }
    
    # Check for code signing capability
    $codeSigningEKU = "1.3.6.1.5.5.7.3.3"
    $hasCodeSigningEKU = $false
    
    foreach ($extension in $certificate.Extensions) {
        if ($extension -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
            foreach ($oid in $extension.EnhancedKeyUsages) {
                if ($oid.Value -eq $codeSigningEKU) {
                    $hasCodeSigningEKU = $true
                    break
                }
            }
        }
    }
    
    if (-not $hasCodeSigningEKU) {
        Write-Warning "Certificate does not have Code Signing Enhanced Key Usage. Signing may fail."
    }
    
    # Sign the scripts
    Write-Host "`nSigning $($validScriptPaths.Count) script(s)..." -ForegroundColor Cyan
    
    $timestampServers = @(
        "http://timestamp.digicert.com",
        "http://timestamp.sectigo.com",
        "http://timestamp.globalsign.com/tsa/v3/sha256"
    )
    
    foreach ($scriptPath in $validScriptPaths) {
        Write-Host "Processing $scriptPath..." -ForegroundColor Yellow
        
        $success = $false
        $lastError = ""
        
        # Try with each timestamp server
        foreach ($tsServer in $timestampServers) {
            try {
                Write-Verbose "Attempting to sign with timestamp server: $tsServer"
                
                $signature = Set-AuthenticodeSignature -FilePath $scriptPath -Certificate $certificate -HashAlgorithm SHA256 -TimestampServer $tsServer -ErrorAction Stop
                
                if ($signature.Status -eq "Valid") {
                    Write-Host "Successfully signed!" -ForegroundColor Green
                    Write-Host "  Timestamp server: $tsServer" -ForegroundColor Green
                    $success = $true
                    $results.SuccessfullySigned++
                    break
                }
                else {
                    $lastError = "Status: $($signature.Status), Message: $($signature.StatusMessage)"
                    Write-Verbose "Failed with timestamp server $tsServer. $lastError"
                }
            }
            catch {
                $lastError = $_
                Write-Verbose "Exception with timestamp server $tsServer : $_"
            }
        }
        
        # If all timestamp servers failed, try without timestamp
        if (-not $success) {
            try {
                Write-Verbose "Attempting to sign without timestamp server"
                
                $signature = Set-AuthenticodeSignature -FilePath $scriptPath -Certificate $certificate -HashAlgorithm SHA256
                
                if ($signature.Status -eq "Valid") {
                    Write-Host "Successfully signed (without timestamp)!" -ForegroundColor Yellow
                    Write-Host "  WARNING: Without a timestamp, signature will expire when the certificate expires." -ForegroundColor Yellow
                    $success = $true
                    $results.SuccessfullySigned++
                }
                else {
                    $lastError = "Status: $($signature.Status), Message: $($signature.StatusMessage)"
                    Write-Verbose "Failed without timestamp. $lastError"
                }
            }
            catch {
                $lastError = $_
                Write-Verbose "Exception when signing without timestamp: $_"
            }
        }
        
        if (-not $success) {
            Write-Host "WARNING: Failed to sign: $scriptPath (Error: $lastError)" -ForegroundColor Red
            $results.FailedToSign++
        }
    }
    
    # Display summary
    $endTime = Get-Date
    $timeElapsed = $endTime - $results.StartTime
    
    Write-Host "`n====================================================="
    Write-Host "                 Signing Summary"
    Write-Host "=====================================================`n"
    Write-Host "Scripts processed: $($results.TotalScripts)"
    Write-Host "Successfully signed: $($results.SuccessfullySigned)" -ForegroundColor $(if ($results.SuccessfullySigned -gt 0) { "Green" } else { "Red" })
    Write-Host "Failed to sign: $($results.FailedToSign)" -ForegroundColor $(if ($results.FailedToSign -eq 0) { "Green" } else { "Red" })
    Write-Host "Time elapsed: $($timeElapsed.TotalSeconds.ToString("0.00")) seconds"
    Write-Host "=====================================================`n"
    
    # Clean up
    if ($certificate) {
        $certificate.Reset()
    }
    
    # Force garbage collection
    [System.GC]::Collect()
    
    return ($results.SuccessfullySigned -gt 0 -and $results.FailedToSign -eq 0)
}

# Export the function if running as a module
Export-ModuleMember -Function Protect-Script 