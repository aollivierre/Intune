<#
.SYNOPSIS
    Installs a code signing certificate to the certificate store.

.DESCRIPTION
    This script installs a code signing certificate to the Windows certificate store
    to make it available for code signing operations. It properly configures the private
    key settings and can install to either the current user or local machine store.

.PARAMETER CertificatePath
    Path to the certificate file (PFX format).

.PARAMETER StoreLocation
    Certificate store location - CurrentUser or LocalMachine. Default is CurrentUser.

.PARAMETER StoreName
    Certificate store name. Default is My (Personal).

.EXAMPLE
    .\InstallCertificate.ps1 -CertificatePath "C:\temp\certs\CodeSigning.pfx" -StoreLocation LocalMachine
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CertificatePath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("CurrentUser", "LocalMachine")]
    [string]$StoreLocation = "CurrentUser",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("My", "Root", "TrustedPublisher", "TrustedPeople")]
    [string]$StoreName = "My"
)

# Check if running as administrator (required for LocalMachine store)
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# If trying to use LocalMachine store without admin rights, warn and exit
if ($StoreLocation -eq "LocalMachine" -and -not (Test-Administrator)) {
    Write-Error "Administrator privileges are required to install certificates to the LocalMachine store."
    Write-Host "Please run this script as Administrator or use -StoreLocation CurrentUser instead." -ForegroundColor Yellow
    exit 1
}

# Check if certificate file exists
if (-not (Test-Path -Path $CertificatePath)) {
    Write-Error "Certificate file not found: $CertificatePath"
    exit 1
}

# Get certificate password
$certPassword = Read-Host -Prompt "Enter password for certificate" -AsSecureString

try {
    # Load certificate
    Write-Host "Loading certificate from $CertificatePath..." -ForegroundColor Yellow
    
    # Use the most robust flags for private key persistence
    $flags = if ($StoreLocation -eq "LocalMachine") {
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"Exportable,PersistKeySet,MachineKeySet"
    } else {
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]"Exportable,PersistKeySet,UserKeySet"
    }
    
    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath, $certPassword, $flags)
    
    if (-not $certificate) {
        Write-Error "Failed to load certificate."
        exit 1
    }
    
    # Display certificate information
    Write-Host "`nCertificate loaded successfully:" -ForegroundColor Green
    Write-Host "  Subject: $($certificate.Subject)" -ForegroundColor Yellow
    Write-Host "  Issuer: $($certificate.Issuer)" -ForegroundColor Yellow
    Write-Host "  Valid from: $($certificate.NotBefore) to $($certificate.NotAfter)" -ForegroundColor Yellow
    Write-Host "  Thumbprint: $($certificate.Thumbprint)" -ForegroundColor Yellow
    Write-Host "  Has private key: $($certificate.HasPrivateKey)" -ForegroundColor Yellow
    
    # Check if it's a code signing certificate
    $codeSigningEKU = "1.3.6.1.5.5.7.3.3"
    $hasCodeSigningEKU = $false
    
    foreach ($extension in $certificate.Extensions) {
        if ($extension -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
            foreach ($oid in $extension.EnhancedKeyUsages) {
                if ($oid.Value -eq $codeSigningEKU) {
                    $hasCodeSigningEKU = $true
                    break
                }
                Write-Host "  EKU: $($oid.FriendlyName) [$($oid.Value)]" -ForegroundColor Gray
            }
        }
    }
    
    if (-not $hasCodeSigningEKU) {
        Write-Warning "This certificate does not have the Code Signing Enhanced Key Usage extension."
        Write-Warning "It may not be suitable for code signing operations."
        
        $continue = Read-Host "Do you want to continue anyway? (Y/N)"
        if ($continue -ne "Y") {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Check for existing certificate with same thumbprint
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName, $StoreLocation)
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    
    $existingCert = $store.Certificates | Where-Object { $_.Thumbprint -eq $certificate.Thumbprint }
    
    if ($existingCert) {
        Write-Warning "A certificate with thumbprint $($certificate.Thumbprint) is already installed in the $StoreLocation\$StoreName store."
        
        $replace = Read-Host "Do you want to replace it? (Y/N)"
        if ($replace -eq "Y") {
            $store.Remove($existingCert)
            Write-Host "Existing certificate removed." -ForegroundColor Yellow
        }
        else {
            Write-Host "Using existing certificate. No changes made." -ForegroundColor Yellow
            $store.Close()
            exit 0
        }
    }
    
    # Install certificate
    Write-Host "`nInstalling certificate to $StoreLocation\$StoreName store..." -ForegroundColor Yellow
    $store.Add($certificate)
    $store.Close()
    
    # Verify installation
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName, $StoreLocation)
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
    
    $installedCert = $store.Certificates | Where-Object { $_.Thumbprint -eq $certificate.Thumbprint }
    
    if ($installedCert) {
        Write-Host "`nCertificate successfully installed!" -ForegroundColor Green
        Write-Host "  Store: $StoreLocation\$StoreName" -ForegroundColor Green
        Write-Host "  Thumbprint: $($installedCert.Thumbprint)" -ForegroundColor Green
        Write-Host "  Has private key: $($installedCert.HasPrivateKey)" -ForegroundColor Green
        
        # Test if private key is accessible
        if ($installedCert.HasPrivateKey) {
            try {
                $privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($installedCert)
                
                if ($privateKey) {
                    Write-Host "  Private key is accessible: Yes" -ForegroundColor Green
                }
                else {
                    Write-Warning "Private key is accessible: No (null response)"
                }
            }
            catch {
                Write-Warning "Private key is accessible: No (exception: $_)"
            }
        }
        
        Write-Host "`nTo use this certificate for code signing, use the thumbprint:" -ForegroundColor Cyan
        Write-Host "$($installedCert.Thumbprint)" -ForegroundColor White -BackgroundColor DarkBlue
        
        # Give signing command example
        $samplePath = "C:\Scripts\MyScript.ps1"
        
        Write-Host "`nExample signing command:" -ForegroundColor Cyan
        Write-Host "Set-AuthenticodeSignature -FilePath '$samplePath' -Certificate (Get-Item -Path 'Cert:\$StoreLocation\$StoreName\$($installedCert.Thumbprint)')" -ForegroundColor Yellow
    }
    else {
        Write-Error "Failed to install certificate. It was not found in the store after installation."
    }
    
    $store.Close()
}
catch {
    Write-Error "Error installing certificate: $_"
    
    if ($_.Exception.Message -like "*password*") {
        Write-Host "This appears to be a password issue. Double-check your certificate password." -ForegroundColor Yellow
    }
}
finally {
    # Clean up
    if ($certificate) {
        $certificate.Reset()
    }
    
    # Force garbage collection
    [System.GC]::Collect()
} 