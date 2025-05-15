<#
.SYNOPSIS
    Simple PowerShell script signing utility.

.DESCRIPTION
    This script directly signs PowerShell scripts using a certificate.
    It provides a simpler alternative to the module's signing function.

.PARAMETER ScriptPath
    Path to the script to sign.

.PARAMETER CertificateFolder
    Folder containing the certificate file.

.PARAMETER CertificateFileName
    Name of the certificate file (PFX format).

.EXAMPLE
    .\DirectSignScript.ps1 -ScriptPath "C:\Scripts\MyScript.ps1" -CertificateFolder "C:\temp\certs" -CertificateFileName "MyCert.pfx"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [string]$CertificateFolder = "C:\temp\certs",
    
    [Parameter(Mandatory = $false)]
    [string]$CertificateFileName = "ConfigMgrCodeSigning.pfx"
)

# Check if script exists
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Script not found: $ScriptPath"
    exit 1
}

# Check if certificate folder exists
if (-not (Test-Path -Path $CertificateFolder)) {
    Write-Error "Certificate folder not found: $CertificateFolder"
    exit 1
}

# Check if certificate file exists
$certPath = Join-Path -Path $CertificateFolder -ChildPath $CertificateFileName
if (-not (Test-Path -Path $certPath)) {
    Write-Error "Certificate file not found: $certPath"
    exit 1
}

# Get password for certificate
$certPassword = Read-Host -Prompt "Enter password for certificate" -AsSecureString

try {
    # Load the certificate
    Write-Host "Loading certificate from $certPath..." -ForegroundColor Yellow
    
    # Use different flag combinations to maximize compatibility
    $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"Exportable,PersistKeySet,MachineKeySet"
    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $certPassword, $flags)
    
    if (-not $certificate) {
        Write-Error "Failed to load certificate."
        exit 1
    }
    
    # Display certificate information
    Write-Host "Certificate loaded successfully:" -ForegroundColor Green
    Write-Host "  Subject: $($certificate.Subject)" -ForegroundColor Yellow
    Write-Host "  Issuer: $($certificate.Issuer)" -ForegroundColor Yellow
    Write-Host "  Valid from: $($certificate.NotBefore) to $($certificate.NotAfter)" -ForegroundColor Yellow
    Write-Host "  Thumbprint: $($certificate.Thumbprint)" -ForegroundColor Yellow
    Write-Host "  Has private key: $($certificate.HasPrivateKey)" -ForegroundColor Yellow
    
    if (-not $certificate.HasPrivateKey) {
        Write-Error "Certificate does not have a private key. Cannot sign with this certificate."
        exit 1
    }
    
    # Sign the script
    Write-Host "Signing script: $ScriptPath" -ForegroundColor Yellow
    
    # Use multiple timestamp servers for redundancy
    $timestampServers = @(
        "http://timestamp.digicert.com",
        "http://timestamp.sectigo.com",
        "http://timestamp.globalsign.com/tsa/v3/sha256"
    )
    
    $success = $false
    
    foreach ($tsServer in $timestampServers) {
        try {
            Write-Host "Attempting to sign with timestamp server: $tsServer" -ForegroundColor Yellow
            
            $signature = Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $certificate -HashAlgorithm SHA256 -TimestampServer $tsServer -ErrorAction Stop
            
            if ($signature.Status -eq "Valid") {
                Write-Host "Script signed successfully with timestamp from $tsServer!" -ForegroundColor Green
                $success = $true
                break
            }
            else {
                Write-Host "Signing failed with timestamp server $tsServer. Status: $($signature.Status)" -ForegroundColor Red
                Write-Host "Message: $($signature.StatusMessage)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error when signing with timestamp server $tsServer : $_" -ForegroundColor Red
        }
    }
    
    if (-not $success) {
        # Try without timestamp as a last resort
        try {
            Write-Host "Attempting to sign without timestamp server..." -ForegroundColor Yellow
            
            $signature = Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $certificate -HashAlgorithm SHA256
            
            if ($signature.Status -eq "Valid") {
                Write-Host "Script signed successfully (without timestamp)!" -ForegroundColor Green
                Write-Host "Warning: Without a timestamp, the signature will expire when the certificate expires." -ForegroundColor Yellow
                $success = $true
            }
            else {
                Write-Host "Signing failed without timestamp. Status: $($signature.Status)" -ForegroundColor Red
                Write-Host "Message: $($signature.StatusMessage)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error when signing without timestamp: $_" -ForegroundColor Red
        }
    }
    
    # Verify the signature
    $verifySignature = Get-AuthenticodeSignature -FilePath $ScriptPath
    Write-Host "`nSignature Verification:" -ForegroundColor Cyan
    Write-Host "  Status: $($verifySignature.Status)" -ForegroundColor $(if ($verifySignature.Status -eq "Valid") { "Green" } else { "Red" })
    
    if ($verifySignature.Status -eq "Valid") {
        Write-Host "  Signed by: $($verifySignature.SignerCertificate.Subject)" -ForegroundColor Green
        
        if ($verifySignature.TimeStamperCertificate) {
            Write-Host "  Timestamp: $($verifySignature.TimestamperCertificate.Subject)" -ForegroundColor Green
        }
        else {
            Write-Host "  No timestamp found" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "Error: $_"
    exit 1
}
finally {
    # Clean up resources
    if ($certificate) {
        $certificate.Reset()
    }
    
    # Force garbage collection
    [System.GC]::Collect()
} 