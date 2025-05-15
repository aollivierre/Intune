# Sign-RemediationScripts.ps1
# Example script to demonstrate code signing of Intune remediation scripts
# Version: 1.0.0

# Parameters
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptsPath = ".\Scripts",
    
    [Parameter(Mandatory = $false)]
    [string]$CertificatePath = "C:\temp\certs\CodeSigningCert.pfx",
    
    [Parameter(Mandatory = $false)]
    [string]$CertificatePassword,
    
    [Parameter(Mandatory = $false)]
    [switch]$SignAllScripts
)

# Import the IntuneRemediation module
# If not installed, you can install it from the PowerShell Gallery:
# Install-Module -Name IntuneRemediation -Scope CurrentUser
if (-not (Get-Module -Name IntuneRemediation -ErrorAction SilentlyContinue)) {
    Import-Module -Name IntuneRemediation -ErrorAction Stop
}

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Intune Remediation Script Signing" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host

# Ensure scripts path exists
if (-not (Test-Path -Path $ScriptsPath -PathType Container)) {
    Write-Host "Creating scripts directory: $ScriptsPath" -ForegroundColor Yellow
    New-Item -Path $ScriptsPath -ItemType Directory -Force | Out-Null
}

# Check for default scripts in the folder
if (-not (Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" | Where-Object { $_.Name -match "Detect|Remediate" })) {
    Write-Host "No detection or remediation scripts found. Creating sample scripts..." -ForegroundColor Yellow
    
    # Create a sample detection script
    $detectScriptPath = Join-Path -Path $ScriptsPath -ChildPath "Detect-ServiceState.ps1"
    @'
# Detect-ServiceState.ps1
# This script checks if a specific Windows service is running
# Exit code 0 indicates detection success (no issue found)
# Exit code 1 indicates detection failure (issue found, remediation needed)

param (
    [string]$ServiceName = "Spooler"
)

# Check if the service exists
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "Service '$ServiceName' not found."
    exit 1
}

# Check if the service is running
if ($service.Status -ne 'Running') {
    Write-Host "Service '$ServiceName' is not running (Status: $($service.Status))."
    exit 1
}

Write-Host "Service '$ServiceName' is running as expected."
exit 0
'@ | Out-File -FilePath $detectScriptPath -Encoding utf8 -Force
    
    # Create a sample remediation script
    $remediateScriptPath = Join-Path -Path $ScriptsPath -ChildPath "Remediate-ServiceState.ps1"
    @'
# Remediate-ServiceState.ps1
# This script attempts to start a Windows service that isn't running
# Exit code 0 indicates remediation success
# Exit code 1 indicates remediation failure

param (
    [string]$ServiceName = "Spooler"
)

# Check if the service exists
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "Service '$ServiceName' not found. Cannot remediate."
    exit 1
}

try {
    # Try to start the service
    Start-Service -Name $ServiceName -ErrorAction Stop
    
    # Verify service started
    $service = Get-Service -Name $ServiceName
    if ($service.Status -eq 'Running') {
        Write-Host "Successfully started service '$ServiceName'."
        exit 0
    } else {
        Write-Host "Failed to start service '$ServiceName'. Status: $($service.Status)"
        exit 1
    }
} catch {
    Write-Host "Error starting service '$ServiceName': $_"
    exit 1
}
'@ | Out-File -FilePath $remediateScriptPath -Encoding utf8 -Force
    
    Write-Host "Created sample scripts:" -ForegroundColor Green
    Write-Host "- $detectScriptPath" -ForegroundColor Green
    Write-Host "- $remediateScriptPath" -ForegroundColor Green
}

# Define which scripts to sign
$scriptsToSign = if ($SignAllScripts) {
    $ScriptsPath  # Sign all scripts in the folder
} else {
    # Only sign detection and remediation scripts
    Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" | 
        Where-Object { $_.Name -match "Detect|Remediate" } | 
        Select-Object -ExpandProperty FullName
}

# Sign the scripts
if ($CertificatePassword) {
    # Sign with provided password
    Protect-IntuneRemediationScript -ScriptPath $scriptsToSign -CertificatePath $CertificatePath -CertificatePassword $CertificatePassword
} elseif (Test-Path -Path $CertificatePath) {
    # Sign with certificate path (will prompt for password)
    Protect-IntuneRemediationScript -ScriptPath $scriptsToSign -CertificatePath $CertificatePath
} else {
    # Auto-discover certificates in the default location (C:\temp\certs)
    Protect-IntuneRemediationScript -ScriptPath $scriptsToSign
}

# Verify signatures
Write-Host "`nVerifying signatures:" -ForegroundColor Cyan
$scripts = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" | Where-Object { $_.Name -match "Detect|Remediate" }
foreach ($script in $scripts) {
    $sig = Get-AuthenticodeSignature -FilePath $script.FullName
    $status = switch ($sig.Status) {
        "Valid" { "[OK] Valid" }
        "NotSigned" { "[X] Not signed" }
        default { "? $($sig.Status)" }
    }
    $statusColor = switch ($sig.Status) {
        "Valid" { "Green" }
        "NotSigned" { "Red" }
        default { "Yellow" }
    }
    
    Write-Host "$($script.Name): " -NoNewline
    Write-Host $status -ForegroundColor $statusColor
    
    if ($sig.Status -eq "Valid") {
        Write-Host "   Signed by: $($sig.SignerCertificate.Subject)" -ForegroundColor Gray
        Write-Host "   Valid until: $($sig.SignerCertificate.NotAfter)" -ForegroundColor Gray
    }
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Upload your signed scripts to Intune using New-IntuneRemediationScript" -ForegroundColor White
Write-Host "2. Script signature verification will be ENABLED by default" -ForegroundColor Green
Write-Host "   Example: New-IntuneRemediationScript -DisplayName 'Service Monitor'" -ForegroundColor White
Write-Host "   To disable signature checking (not recommended): New-IntuneRemediationScript -DisplayName 'Service Monitor' -EnforceSignatureCheck:`$false" -ForegroundColor Yellow 