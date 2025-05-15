<#
.SYNOPSIS
    Tests and deploys the Windows Time service monitor remediation scripts to Intune.

.DESCRIPTION
    This script demonstrates how to use the IntuneRemediation module to:
    1. Test the detection and remediation scripts locally
    2. Connect to Intune using saved tokens, new tokens, or a pre-acquired token
    3. Upload the scripts to Intune as a remediation script package
    
    The script supports secure token storage and reuse for future sessions.

.PARAMETER ProfileName
    Optional. The profile name to use for token storage. Default is 'Default'.
    
.PARAMETER Force
    Optional. If specified, ignores saved tokens and always prompts for a new token.
    
.PARAMETER DoNotSave
    Optional. If specified, does not save the token for future use.

.PARAMETER Token
    Optional. A pre-acquired token from a browser session. If provided, it will be
    validated and used for authentication. If -DoNotSave is not specified, the token
    will be securely saved for future use.

.EXAMPLE
    .\Deploy-ServiceMonitor-Enhanced.ps1
    
    Runs the script with default settings, using saved tokens if available or prompting
    for new authentication.
    
.EXAMPLE
    .\Deploy-ServiceMonitor-Enhanced.ps1 -Token "eyJ0eXAiOiJKV1QiLCJub..."
    
    Runs the script using a pre-acquired token and securely saves it for future use.
    
.EXAMPLE
    .\Deploy-ServiceMonitor-Enhanced.ps1 -Token "eyJ0eXAiOiJKV1QiLCJub..." -DoNotSave
    
    Runs the script using a pre-acquired token without saving it.

.NOTES
    File Name: Deploy-ServiceMonitor-Enhanced.ps1
    Author: Intune Administrator
    Created: 2023-11-09
    Version: 1.1
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProfileName = "Default",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$DoNotSave,
    
    [Parameter(Mandatory = $false)]
    [string]$Token
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

# Step 1: Test the remediation scripts locally
Write-Host "`n=== TESTING REMEDIATION SCRIPTS LOCALLY ===" -ForegroundColor Cyan
$detectionScriptPath = "$scriptDir\Detect-CriticalService.ps1"
$remediationScriptPath = "$scriptDir\Remediate-CriticalService.ps1"

$testResults = Test-IntuneRemediationScript -DetectionScriptPath $detectionScriptPath -RemediationScriptPath $remediationScriptPath -Cycles 1 -ShowScriptOutput

if ($testResults.FinalStatus -eq "Compliant") {
    Write-Host "The remediation test completed successfully and the service is in a compliant state." -ForegroundColor Green
}
else {
    Write-Host "The remediation test completed, but the service is still in a non-compliant state." -ForegroundColor Red
    Write-Host "Review the test output above for more information." -ForegroundColor Yellow
    
    $proceed = Read-Host "Do you want to proceed with deploying to Intune anyway? (Y/N)"
    if ($proceed -ne "Y") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

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
            } else {
                "expired"
            }
        } else {
            if ($tokenInfo.ExpirationTime) {
                "valid until $($tokenInfo.ExpirationTime.ToLocalTime())"
            } else {
                "valid"
            }
        }
        
        Write-Host "Found saved token for profile '$ProfileName'" -ForegroundColor Yellow
        if ($tokenInfo.UserInfo) {
            Write-Host "  Associated with: $($tokenInfo.UserInfo)" -ForegroundColor Yellow
        }
        Write-Host "  Token status: $expiryInfo" -ForegroundColor $(if ($isExpired) { "Red" } else { "Green" })
        
        if ($isExpired) {
            Write-Host "  The saved token has expired and a new one will be required." -ForegroundColor Yellow
            $Force = $true
        }
    }
    else {
        Write-Host "No saved tokens found for profile '$ProfileName'." -ForegroundColor Yellow
    }
}

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
            $connected = Connect-IntuneWithToken -Token $Token -ShowScopes -SuppressWarnings
            
            if (-not $connected) {
                throw "Failed to connect with saved token"
            }
        } else {
            throw "Token file not found"
        }
    } catch {
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
        } else {
            Write-Warning "Could not save token for future use."
        }
    }
    elseif ($connected -and $DoNotSave) {
        Write-Host "Token was not saved as -DoNotSave was specified." -ForegroundColor Yellow
    }
}
else {
    # Normal authentication flow
    Write-Host "Using interactive authentication..." -ForegroundColor Yellow
    
    # Connect to Intune with token management
    $connected = Initialize-IntuneConnection -ProfileName $ProfileName -ForceBrowser:$Force -SaveTokenForReuse:(-not $DoNotSave)
}

if (-not $connected) {
    Write-Error "Failed to connect to Intune. Please check your token and try again."
    exit 1
}

# Step 4: Upload the scripts to Intune
Write-Host "`n=== UPLOADING REMEDIATION SCRIPTS TO INTUNE ===" -ForegroundColor Cyan

# Read the script contents
$detectionScriptContent = Get-Content -Path $detectionScriptPath -Raw
$remediationScriptContent = Get-Content -Path $remediationScriptPath -Raw

# Sign the scripts before uploading them
Write-Host "`n=== SIGNING REMEDIATION SCRIPTS ===" -ForegroundColor Cyan
Write-Host "Looking for code signing certificates in C:\temp\certs..." -ForegroundColor Yellow

# Sign the detection script
Write-Host "Signing detection script..." -ForegroundColor Yellow
$detectionSigned = Protect-IntuneRemediationScript -ScriptPath $detectionScriptPath -CertificateFolder "C:\temp\certs"

# Sign the remediation script
Write-Host "Signing remediation script..." -ForegroundColor Yellow
$remediationSigned = Protect-IntuneRemediationScript -ScriptPath $remediationScriptPath -CertificateFolder "C:\temp\certs"

if (-not ($detectionSigned -and $remediationSigned)) {
    Write-Warning "One or both scripts could not be signed. Intune may reject them if signature verification is enforced."
    $proceed = Read-Host "Do you want to proceed with uploading unsigned scripts? (Y/N)"
    if ($proceed -ne "Y") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Re-read the scripts to get the signed content
$detectionScriptContent = Get-Content -Path $detectionScriptPath -Raw
$remediationScriptContent = Get-Content -Path $remediationScriptPath -Raw

# Verify the signatures
$detectionSig = Get-AuthenticodeSignature -FilePath $detectionScriptPath
$remediationSig = Get-AuthenticodeSignature -FilePath $remediationScriptPath

if ($detectionSig.Status -eq "Valid" -and $remediationSig.Status -eq "Valid") {
    Write-Host "Both scripts are successfully signed and ready for upload." -ForegroundColor Green
} else {
    Write-Warning "One or both scripts are not properly signed. Status: Detection=$($detectionSig.Status), Remediation=$($remediationSig.Status)"
}

# Create the remediation script package in Intune
$remediationScriptParams = @{
    DisplayName = "Windows Time Service Monitor"
    Description = "Monitors the Windows Time service and starts it if it's not running."
    DetectionScriptContent = $detectionScriptContent
    RemediationScriptContent = $remediationScriptContent
    RunAsAccount = "System"  # Run as system account
    RunAs32Bit = $false      # Run as 64-bit
    # Using module defaults for Publisher (Abdullah Ollivierre) and EnforceSignatureCheck (true)
}

$result = New-IntuneRemediationScript @remediationScriptParams

if ($result) {
    Write-Host "`nSuccessfully created remediation script package in Intune!" -ForegroundColor Green
    Write-Host "You can now assign this script to device groups through the Intune portal." -ForegroundColor Green
    Write-Host "Script ID: $($result.id)" -ForegroundColor Green
}
else {
    Write-Host "`nFailed to create remediation script package in Intune." -ForegroundColor Red
    Write-Host "Please check the error messages above for more information." -ForegroundColor Yellow
} 