<#
.SYNOPSIS
    Tests code signing capabilities and diagnoses issues.

.DESCRIPTION
    This script helps diagnose code signing issues by:
    1. Testing certificate access
    2. Validating certificate properties
    3. Testing signing with multiple methods
    4. Providing detailed error information
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$CertificateFolder = "C:\temp\certs",
    
    [Parameter(Mandatory = $false)]
    [string]$CertificateFileName = "ConfigMgrCodeSigning.pfx",
    
    [Parameter(Mandatory = $false)]
    [string]$TestScriptPath = "SigningTest.ps1"
)

# Ensure test script exists
if (-not (Test-Path $TestScriptPath)) {
    Write-Host "Creating test script at $TestScriptPath..." -ForegroundColor Yellow
    @"
# Test script for code signing
Write-Host "This is a test script for code signing."
Get-Date
"@ | Out-File -FilePath $TestScriptPath -Encoding utf8 -Force
}

function Test-CertificateAccess {
    Write-Host "`n===== TESTING CERTIFICATE ACCESS =====" -ForegroundColor Cyan
    
    $certPath = Join-Path -Path $CertificateFolder -ChildPath $CertificateFileName
    
    if (-not (Test-Path -Path $CertificateFolder)) {
        Write-Host "ERROR: Certificate folder not found: $CertificateFolder" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path -Path $certPath)) {
        Write-Host "ERROR: Certificate file not found: $certPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Certificate file exists: $certPath" -ForegroundColor Green
    
    try {
        # Get all certificate files in the folder
        $certFiles = Get-ChildItem -Path $CertificateFolder -Filter "*.pfx"
        Write-Host "Found $($certFiles.Count) PFX files in the certificate folder:" -ForegroundColor Yellow
        foreach ($file in $certFiles) {
            Write-Host "  - $($file.Name)" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "ERROR: Failed to access certificate folder: $_" -ForegroundColor Red
        return $false
    }
}

function Test-CertificateProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    
    Write-Host "`n===== CERTIFICATE DETAILS =====" -ForegroundColor Cyan
    
    # Basic certificate info
    Write-Host "Subject: $($Certificate.Subject)" -ForegroundColor Yellow
    Write-Host "Issuer: $($Certificate.Issuer)" -ForegroundColor Yellow
    Write-Host "Serial Number: $($Certificate.SerialNumber)" -ForegroundColor Yellow
    Write-Host "Thumbprint: $($Certificate.Thumbprint)" -ForegroundColor Yellow
    Write-Host "Not Before: $($Certificate.NotBefore)" -ForegroundColor Yellow
    Write-Host "Not After: $($Certificate.NotAfter)" -ForegroundColor Yellow
    Write-Host "Has Private Key: $($Certificate.HasPrivateKey)" -ForegroundColor $(if ($Certificate.HasPrivateKey) { "Green" } else { "Red" })
    
    # Check if it's a code signing certificate
    $codeSigningEKU = "1.3.6.1.5.5.7.3.3"
    $hasCodeSigningEKU = $false
    
    foreach ($extension in $Certificate.Extensions) {
        if ($extension -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
            foreach ($oid in $extension.EnhancedKeyUsages) {
                if ($oid.Value -eq $codeSigningEKU) {
                    $hasCodeSigningEKU = $true
                    break
                }
            }
        }
    }
    
    Write-Host "Has Code Signing EKU: $hasCodeSigningEKU" -ForegroundColor $(if ($hasCodeSigningEKU) { "Green" } else { "Red" })
    
    # Enhanced key usage
    Write-Host "`nEnhanced Key Usage:" -ForegroundColor Yellow
    foreach ($extension in $Certificate.Extensions) {
        if ($extension -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
            foreach ($oid in $extension.EnhancedKeyUsages) {
                Write-Host "  - $($oid.FriendlyName) [$($oid.Value)]" -ForegroundColor Yellow
            }
        }
    }
    
    # Additional checks
    if (-not $Certificate.HasPrivateKey) {
        Write-Host "`nERROR: Certificate does not have a private key!" -ForegroundColor Red
        Write-Host "This is required for code signing." -ForegroundColor Red
    }
    
    if (-not $hasCodeSigningEKU) {
        Write-Host "`nERROR: Certificate does not have Code Signing Enhanced Key Usage!" -ForegroundColor Red
        Write-Host "This is required for code signing." -ForegroundColor Red
    }
    
    if ($Certificate.NotBefore -gt (Get-Date) -or $Certificate.NotAfter -lt (Get-Date)) {
        Write-Host "`nERROR: Certificate is not valid for the current date!" -ForegroundColor Red
        Write-Host "Current date: $(Get-Date)" -ForegroundColor Red
        Write-Host "Certificate validity: $($Certificate.NotBefore) to $($Certificate.NotAfter)" -ForegroundColor Red
    }
    
    return ($Certificate.HasPrivateKey -and $hasCodeSigningEKU -and 
            $Certificate.NotBefore -le (Get-Date) -and $Certificate.NotAfter -ge (Get-Date))
}

function Test-DirectSigningMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    
    Write-Host "`n===== TESTING DIRECT SIGNING METHOD =====" -ForegroundColor Cyan
    
    try {
        $scriptContent = Get-Content -Path $TestScriptPath -Raw
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        Copy-Item -Path $TestScriptPath -Destination $tempFile -Force
        
        Write-Host "Testing direct signing on temporary copy: $tempFile" -ForegroundColor Yellow
        
        # Create a signature
        $signature = Set-AuthenticodeSignature -FilePath $tempFile -Certificate $Certificate -HashAlgorithm SHA256 -TimestampServer "http://timestamp.digicert.com"
        
        if ($signature.Status -eq "Valid") {
            Write-Host "SUCCESS: Script signed successfully with direct method!" -ForegroundColor Green
            Write-Host "Signature details: $($signature.StatusMessage)" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "ERROR: Failed to sign script with direct method." -ForegroundColor Red
            Write-Host "Status: $($signature.Status)" -ForegroundColor Red
            Write-Host "Status Message: $($signature.StatusMessage)" -ForegroundColor Red
            
            # Display more details if available
            if ($signature.SignerCertificate) {
                Write-Host "Signer Certificate Thumbprint: $($signature.SignerCertificate.Thumbprint)" -ForegroundColor Yellow
            }
            
            return $false
        }
    }
    catch {
        Write-Host "EXCEPTION in direct signing: $_" -ForegroundColor Red
        return $false
    }
    finally {
        # Clean up
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Test-Protect-IntuneRemediationScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CertificateFolder
    )
    
    Write-Host "`n===== TESTING PROTECT-INTUNEREMEDIATIONSCRIPT FUNCTION =====" -ForegroundColor Cyan
    
    try {
        # Ensure we can find the module function
        if (-not (Get-Command -Name Protect-IntuneRemediationScript -ErrorAction SilentlyContinue)) {
            Write-Host "ERROR: Protect-IntuneRemediationScript function not found." -ForegroundColor Red
            Write-Host "Ensure the IntuneRemediation module is imported." -ForegroundColor Red
            return $false
        }
        
        Write-Host "Function Protect-IntuneRemediationScript found." -ForegroundColor Green
        
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        Copy-Item -Path $TestScriptPath -Destination $tempFile -Force
        
        Write-Host "Testing on temporary copy: $tempFile" -ForegroundColor Yellow
        
        # Enable verbose output
        $VerbosePreference = "Continue"
        
        # Try to sign with module function
        $result = Protect-IntuneRemediationScript -ScriptPath $tempFile -CertificateFolder $CertificateFolder -Verbose
        
        $VerbosePreference = "SilentlyContinue"
        
        if ($result) {
            Write-Host "SUCCESS: Module function returned success!" -ForegroundColor Green
            
            # Verify signature
            $signature = Get-AuthenticodeSignature -FilePath $tempFile
            if ($signature.Status -eq "Valid") {
                Write-Host "Signature verification: Valid" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "WARNING: Module function returned success but signature is invalid." -ForegroundColor Yellow
                Write-Host "Signature Status: $($signature.Status)" -ForegroundColor Yellow
                Write-Host "Status Message: $($signature.StatusMessage)" -ForegroundColor Yellow
                return $false
            }
        }
        else {
            Write-Host "ERROR: Module function returned failure." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "EXCEPTION in module function test: $_" -ForegroundColor Red
        return $false
    }
    finally {
        # Clean up
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        
        $VerbosePreference = "SilentlyContinue"
    }
}

function Test-ProcessArchitecture {
    Write-Host "`n===== TESTING SYSTEM AND PROCESS ARCHITECTURE =====" -ForegroundColor Cyan
    
    $is64BitOS = [Environment]::Is64BitOperatingSystem
    $is64BitProcess = [Environment]::Is64BitProcess
    
    Write-Host "64-bit Operating System: $is64BitOS" -ForegroundColor Yellow
    Write-Host "64-bit Process: $is64BitProcess" -ForegroundColor Yellow
    
    if ($is64BitOS -and -not $is64BitProcess) {
        Write-Host "WARNING: Running in 32-bit PowerShell on 64-bit OS." -ForegroundColor Yellow
        Write-Host "This might cause issues with certificate access." -ForegroundColor Yellow
        Write-Host "Try running in a 64-bit PowerShell session instead." -ForegroundColor Yellow
    }
}

# Main execution
Clear-Host
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "       CODE SIGNING DIAGNOSTIC TOOL" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
Write-Host "PowerShell Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Yellow
Write-Host "Operating System: $([Environment]::OSVersion.VersionString)" -ForegroundColor Yellow
Write-Host "Current User: $([Environment]::UserName)" -ForegroundColor Yellow
Write-Host "$(Get-Date)" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan

# Test process architecture
Test-ProcessArchitecture

# Test certificate access
$certificateAccessOK = Test-CertificateAccess
if (-not $certificateAccessOK) {
    Write-Host "`nCannot proceed with signing tests due to certificate access issues." -ForegroundColor Red
    exit 1
}

# Load certificate
$certPath = Join-Path -Path $CertificateFolder -ChildPath $CertificateFileName
$certPassword = Read-Host -Prompt "Enter password for certificate" -AsSecureString

try {
    Write-Host "`nLoading certificate..." -ForegroundColor Yellow
    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $certPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"Exportable,PersistKeySet,MachineKeySet")
    
    if ($certificate) {
        Write-Host "Successfully loaded certificate!" -ForegroundColor Green
        
        # Test certificate properties
        $certificateValid = Test-CertificateProperties -Certificate $certificate
        
        if ($certificateValid) {
            Write-Host "`nCertificate appears valid for code signing." -ForegroundColor Green
            
            # Test direct signing method
            $directSigningWorked = Test-DirectSigningMethod -Certificate $certificate
            
            # Test module function
            $moduleSigningWorked = Test-Protect-IntuneRemediationScript -CertificateFolder $CertificateFolder
            
            # Summary
            Write-Host "`n===== SUMMARY =====" -ForegroundColor Cyan
            Write-Host "Certificate Valid: $certificateValid" -ForegroundColor $(if ($certificateValid) { "Green" } else { "Red" })
            Write-Host "Direct Signing Method: $directSigningWorked" -ForegroundColor $(if ($directSigningWorked) { "Green" } else { "Red" })
            Write-Host "Module Signing Method: $moduleSigningWorked" -ForegroundColor $(if ($moduleSigningWorked) { "Green" } else { "Red" })
            
            if ($directSigningWorked -and -not $moduleSigningWorked) {
                Write-Host "`nDIAGNOSIS: The certificate works for direct signing but not with the module function." -ForegroundColor Yellow
                Write-Host "This suggests an issue with the Protect-IntuneRemediationScript function." -ForegroundColor Yellow
                Write-Host "Try examining the module code or using Set-AuthenticodeSignature directly." -ForegroundColor Yellow
            }
            elseif (-not $directSigningWorked -and -not $moduleSigningWorked) {
                Write-Host "`nDIAGNOSIS: Neither signing method worked." -ForegroundColor Red
                Write-Host "This suggests an issue with the certificate itself or PowerShell's signing capabilities." -ForegroundColor Red
                Write-Host "Try using a different certificate or running in a different PowerShell session." -ForegroundColor Red
            }
        }
        else {
            Write-Host "`nCertificate is not valid for code signing. Please check the issues above." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Failed to load certificate." -ForegroundColor Red
    }
}
catch {
    Write-Host "ERROR loading certificate: $_" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*password*") {
        Write-Host "This appears to be a password issue. Double-check your certificate password." -ForegroundColor Yellow
    }
}
finally {
    # Clean up
    if ($certificate) {
        $certificate.Reset()
    }
    
    # Force garbage collection to clean up any certificate objects
    [System.GC]::Collect()
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "       DIAGNOSTIC COMPLETE" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan 