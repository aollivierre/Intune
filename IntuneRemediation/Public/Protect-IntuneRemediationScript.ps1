function Protect-IntuneRemediationScript {
    <#
    .SYNOPSIS
        Signs PowerShell remediation scripts for use with Microsoft Intune.
        
    .DESCRIPTION
        This function signs PowerShell remediation scripts using a code signing certificate.
        It can sign individual scripts or all scripts in a specified folder. The function
        supports using certificates from a certificate store or from a PFX file.
        
        Note: Code signing works more reliably in Windows PowerShell 5.1 than in PowerShell Core.
        This function will automatically use Windows PowerShell 5.1 when run from PowerShell Core.
        
    .PARAMETER ScriptPath
        The path to a single script or a folder containing scripts to sign.
        If a folder is specified, all .ps1 files in that folder will be signed.
        
    .PARAMETER CertificateThumbprint
        The thumbprint of the code signing certificate to use from the certificate store.
        
    .PARAMETER CertificatePath
        The path to a PFX certificate file to use for signing.
        
    .PARAMETER CertificatePassword
        The password for the PFX certificate file.
        
    .PARAMETER CertificateFolder
        The folder containing certificate files to search for code signing certificates.
        Default is "C:\temp\certs".
        
    .PARAMETER ScriptFilter
        A filter to apply when signing scripts in a folder. Default is "*.ps1".
        
    .PARAMETER TimestampServer
        The URL of the timestamp server to use. Default is "http://timestamp.digicert.com".
        
    .PARAMETER SkipRevocationCheck
        If specified, skips online revocation checking which can fail when revocation servers are unavailable.
        
    .EXAMPLE
        Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\Detect-ServiceState.ps1" -CertificateThumbprint "1234567890ABCDEF1234567890ABCDEF12345678"
        
        Signs a single script using a certificate from the certificate store.
        
    .EXAMPLE
        Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\Detect-ServiceState.ps1" -CertificateThumbprint "1234567890ABCDEF1234567890ABCDEF12345678" -SkipRevocationCheck
        
        Signs a single script using a certificate from the certificate store, skipping revocation checks that might fail due to unreachable servers.
        
    .EXAMPLE
        Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\RemediationScripts" -CertificatePath "C:\temp\certs\CodeSigningCert.pfx" -CertificatePassword "SecurePassword"
        
        Signs all PowerShell scripts in the specified folder using a PFX certificate file.
        
    .EXAMPLE
        Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\RemediationScripts" -CertificateFolder "C:\temp\certs"
        
        Signs all PowerShell scripts in the specified folder using the first valid code signing certificate found in the certificate folder.
        
    .NOTES
        Requires administrator privileges to access the certificate store.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string]$CertificateThumbprint = "",
        
        [Parameter(Mandatory = $false)]
        [string]$CertificatePath = "",
        
        [Parameter(Mandatory = $false)]
        [SecureString]$CertificatePassword = $null,
        
        [Parameter(Mandatory = $false)]
        [string]$CertificateFolder = "C:\temp\certs",
        
        [Parameter(Mandatory = $false)]
        [string]$ScriptFilter = "*.ps1",
        
        [Parameter(Mandatory = $false)]
        [string]$TimestampServer = "http://timestamp.digicert.com",
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipRevocationCheck
    )
    
    begin {
        # Check PowerShell version for compatibility
        $isPSCore = $PSVersionTable.PSEdition -eq "Core"
        $usePSFallback = $false
        
        # Store these values for access within the nested function
        $_certPath = $CertificatePath
        $_certPassword = $CertificatePassword
        $_timestampServer = $TimestampServer
        
        if ($isPSCore) {
            Write-Host "Detected PowerShell Core ($($PSVersionTable.PSVersion)). Code signing works better in Windows PowerShell 5.1." -ForegroundColor Yellow
            
            # Check if Windows PowerShell is available for fallback
            $winPSPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
            if (Test-Path $winPSPath) {
                Write-Host "Windows PowerShell found. Will use it for code signing operations." -ForegroundColor Yellow
                $usePSFallback = $true
            } else {
                Write-Warning "Windows PowerShell not found. Will attempt to sign using PowerShell Core, but this may fail."
            }
        }
        
        # Function to sign scripts with a certificate
        function SignScript {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Script,
                
                [Parameter(Mandatory = $true)]
                [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
            )
            
            # Check if script already signed by the current certificate
            $existingSig = Get-AuthenticodeSignature -FilePath $Script
            if ($existingSig.Status -eq "Valid" -and $existingSig.SignerCertificate.Thumbprint -eq $Certificate.Thumbprint) {
                Write-Host "[INFO] Script already signed with the current certificate: $(Split-Path -Leaf $Script)" -ForegroundColor Yellow
                return $true
            }
            
            Write-Host "Signing script: $(Split-Path -Leaf $Script)" -ForegroundColor Cyan
            
            try {
                # Check if we should use direct signing or Windows PowerShell fallback
                if ($usePSFallback) {
                    # Create a temporary script file to do the signing
                    $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
@'
param (
    [string]$ScriptPath,
    [string]$CertPath,
    [string]$CertPass,
    [string]$CertThumbprint,
    [string]$TimestampServer
)

# Load certificate from file or store based on parameters
$cert = $null
if ($CertPath -and $CertPass) {
    $securePass = ConvertTo-SecureString -String $CertPass -AsPlainText -Force
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath, $securePass, "Exportable,PersistKeySet")
}
elseif ($CertThumbprint) {
    $cert = Get-Item -Path "Cert:\CurrentUser\My\$CertThumbprint" -ErrorAction SilentlyContinue
    if (-not $cert) {
        $cert = Get-Item -Path "Cert:\LocalMachine\My\$CertThumbprint" -ErrorAction SilentlyContinue
    }
}

if (-not $cert) {
    Write-Error "Failed to load certificate"
    exit 1
}

# Sign the script
$result = $null
if ([string]::IsNullOrEmpty($TimestampServer)) {
    $result = Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $cert
}
else {
    $result = Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $cert -TimestampServer $TimestampServer
}

# Return result as JSON
$resultObj = @{
    Status = $result.Status
    StatusMessage = $result.StatusMessage
    Path = $result.Path
    SignerCertificate = @{
        Thumbprint = $result.SignerCertificate.Thumbprint
        Subject = $result.SignerCertificate.Subject
    }
}

ConvertTo-Json -InputObject $resultObj
'@ | Out-File -FilePath $tempScript -Encoding UTF8
                    
                    # Prepare parameters based on what we have
                    $scriptParams = @("-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`"", 
                                      "-ScriptPath", "`"$Script`"", "-TimestampServer", "`"$_timestampServer`"")
                    
                    if ($_certPath -and $_certPassword) {
                        $scriptParams += "-CertPath"
                        $scriptParams += "`"$_certPath`""
                        $scriptParams += "-CertPass"
                        $scriptParams += "`"$_certPassword`""
                    }
                    elseif ($Certificate.Thumbprint) {
                        $scriptParams += "-CertThumbprint"
                        $scriptParams += "`"$($Certificate.Thumbprint)`""
                    }
                    
                    # Execute script using Windows PowerShell
                    $winPSPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
                    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $processInfo.FileName = $winPSPath
                    $processInfo.Arguments = $scriptParams -join " "
                    $processInfo.UseShellExecute = $false
                    $processInfo.RedirectStandardOutput = $true
                    $processInfo.CreateNoWindow = $true
                    
                    $process = New-Object System.Diagnostics.Process
                    $process.StartInfo = $processInfo
                    $process.Start() | Out-Null
                    $output = $process.StandardOutput.ReadToEnd()
                    $process.WaitForExit()
                    
                    # Clean up
                    if (Test-Path $tempScript) {
                        Remove-Item -Path $tempScript -Force
                    }
                    
                    # Parse result
                    try {
                        $resultObj = $output | ConvertFrom-Json
                        if ($resultObj.Status -eq "Valid") {
                            Write-Host "Successfully signed script: $(Split-Path -Leaf $Script)" -ForegroundColor Green
                            return $true
                        }
                        else {
                            Write-Host "Failed to sign script: $(Split-Path -Leaf $Script)" -ForegroundColor Red
                            Write-Host "Status: $($resultObj.Status)" -ForegroundColor Red
                            Write-Host "Message: $($resultObj.StatusMessage)" -ForegroundColor Red
                            return $false
                        }
                    }
                    catch {
                        Write-Error "Failed to parse signing result: $_"
                        Write-Error "Output: $output"
                        return $false
                    }
                }
                else {
                    # Direct PowerShell signing
                    
                    # Verify and ensure the certificate chain is valid
                    $chainValid = Confirm-IntuneCodeSigningChain -Certificate $Certificate -SkipRevocationCheck:$SkipRevocationCheck
                    if (-not $chainValid) {
                        Write-Warning "Certificate chain issues may cause signing to fail. You may need to install the issuing CA and root CA certificates."
                    }
                    
                    $signature = Set-AuthenticodeSignature -FilePath $Script -Certificate $Certificate -TimestampServer $_timestampServer
                    
                    if ($signature.Status -eq "Valid") {
                        Write-Host "Successfully signed script: $(Split-Path -Leaf $Script)" -ForegroundColor Green
                        return $true
                    }
                    else {
                        Write-Host "Failed to sign script: $(Split-Path -Leaf $Script)" -ForegroundColor Red
                        Write-Host "Status: $($signature.Status)" -ForegroundColor Red
                        Write-Host "Message: $($signature.StatusMessage)" -ForegroundColor Red
                        return $false
                    }
                }
            }
            catch {
                Write-Error "Error signing script $Script`: $_"
                return $false
            }
        }
        
        # Display banner
        Write-Host "`n=====================================================" -ForegroundColor Cyan
        Write-Host "       Intune Remediation Script Signing Utility" -ForegroundColor Cyan
        Write-Host "=====================================================" -ForegroundColor Cyan
        
        # Initialize counters
        $successCount = 0
        $failureCount = 0
        $timestampStart = Get-Date
        
        # Find the code signing certificate
        $cert = $null
        
        # Check if running as administrator
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            Write-Warning "This function works best when run as Administrator. Some certificate operations may fail."
        }
    }
    
    process {
        try {
            # Find and validate the certificate
            if ($CertificatePath) {
                # Load certificate from file
                if (-not (Test-Path $CertificatePath)) {
                    Write-Error "Certificate file not found: $CertificatePath"
                    return $false
                }
                
                try {
                    if ($CertificatePassword) {
                        $securePassword = ConvertTo-SecureString -String $CertificatePassword -Force -AsPlainText
                        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $CertificatePath, $securePassword
                    } else {
                        # Prompt for password if not provided
                        $securePassword = Read-Host "Enter certificate password" -AsSecureString
                        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $CertificatePath, $securePassword
                    }
                    Write-Host "Certificate loaded from file: $CertificatePath" -ForegroundColor Yellow
                } catch {
                    Write-Error "Failed to load certificate: $_"
                    return $false
                }
            } elseif ($CertificateThumbprint) {
                Write-Host "Looking for certificate with thumbprint: $CertificateThumbprint" -ForegroundColor Yellow
                $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
                
                if (-not $cert) {
                    # Try LocalMachine store if admin
                    if ($isAdmin) {
                        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
                    }
                }
            } elseif (Test-Path $CertificateFolder) {
                # Search for certificates in the specified folder
                Write-Host "Searching for certificates in: $CertificateFolder" -ForegroundColor Yellow
                $certFiles = Get-ChildItem -Path $CertificateFolder -Filter "*.pfx"
                
                if ($certFiles.Count -eq 0) {
                    Write-Error "No certificate files (.pfx) found in $CertificateFolder"
                    return $false
                }
                
                # Try to load first certificate found
                foreach ($certFile in $certFiles) {
                    try {
                        $securePassword = Read-Host "Enter password for certificate $($certFile.Name)" -AsSecureString
                        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $certFile.FullName, $securePassword
                        # Update stored values for the nested function
                        $_certPath = $certFile.FullName
                        $_certPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
                        
                        if ($cert.HasPrivateKey) { break }
                    } catch {
                        Write-Warning "Could not load certificate $($certFile.Name): $_"
                    }
                }
            } else {
                Write-Host "No specific certificate provided, looking for code signing certificates in certificate store..." -ForegroundColor Yellow
                $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1
                
                if (-not $cert -and $isAdmin) {
                    # Try LocalMachine store if admin
                    $cert = Get-ChildItem -Path Cert:\LocalMachine\My -CodeSigningCert | Where-Object { $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1
                }
            }
            
            if (-not $cert) {
                Write-Error "No valid code signing certificate found. Please provide a valid certificate."
                return $false
            }
            
            # Display certificate information
            Write-Host "`nUsing certificate:" -ForegroundColor Cyan
            Write-Host "  Subject: $($cert.Subject)" -ForegroundColor White
            Write-Host "  Issuer: $($cert.Issuer)" -ForegroundColor White
            Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor White
            Write-Host "  Valid from: $($cert.NotBefore) to $($cert.NotAfter)" -ForegroundColor White
            Write-Host "  Has private key: $($cert.HasPrivateKey)`n" -ForegroundColor White
            
            # Confirm certificate is suitable for code signing
            $hasCodeSigningEKU = $false
            $cert.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Enhanced Key Usage' } | 
                ForEach-Object {
                    if ($_.Format(1) -match "Code Signing") {
                        $hasCodeSigningEKU = $true
                    }
                }
            
            if (-not $hasCodeSigningEKU) {
                Write-Error "The selected certificate is not suitable for code signing. Certificate must have the 'Code Signing' Enhanced Key Usage."
                return $false
            }
            
            # Get scripts to sign
            $scripts = @()
            
            if (Test-Path -Path $ScriptPath -PathType Leaf) {
                # Single script
                if ($ScriptPath -like "*.ps1") {
                    $scripts = @(Get-Item -Path $ScriptPath)
                } else {
                    Write-Error "The specified file is not a PowerShell script (.ps1): $ScriptPath"
                    return $false
                }
            } elseif (Test-Path -Path $ScriptPath -PathType Container) {
                # Folder of scripts
                $scripts = @(Get-ChildItem -Path $ScriptPath -Filter $ScriptFilter)
                
                if ($scripts.Count -eq 0) {
                    Write-Error "No PowerShell scripts found in $ScriptPath matching filter $ScriptFilter"
                    return $false
                }
            } else {
                Write-Error "The specified path does not exist: $ScriptPath"
                return $false
            }
            
            # Sign each script
            Write-Host "`nSigning $($scripts.Count) script(s)..." -ForegroundColor Cyan
            
            foreach ($script in $scripts) {
                Write-Host "Processing $($script.Name)..." -ForegroundColor Yellow
                
                # Sign the script
                $result = SignScript -Script $script.FullName -Certificate $cert
                
                if ($result) {
                    $successCount++
                } else {
                    $failureCount++
                }
            }
            
            # Return success
            return $true
        }
        catch {
            Write-Error "Error in Protect-IntuneRemediationScript: $_"
            return $false
        }
    }
    
    end {
        # Completion summary
        $timeElapsed = (Get-Date) - $timestampStart
        Write-Host "`n=====================================================" -ForegroundColor Cyan
        Write-Host "                 Signing Summary" -ForegroundColor Cyan
        Write-Host "=====================================================" -ForegroundColor Cyan
        Write-Host "Scripts processed: $($scripts.Count)" -ForegroundColor White
        Write-Host "Successfully signed: $successCount" -ForegroundColor Green
        Write-Host "Failed to sign: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "White" })
        Write-Host "Time elapsed: $($timeElapsed.TotalSeconds.ToString("0.00")) seconds" -ForegroundColor White
        Write-Host "=====================================================" -ForegroundColor Cyan
    }
} 