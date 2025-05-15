# IntuneRemediation PowerShell Module

## Overview

The IntuneRemediation module provides an easy way to create, test, and deploy remediation scripts to Microsoft Intune using PowerShell. It uses browser-acquired tokens for authentication, eliminating the need for app registrations.

## Features

- **Token-based Authentication**: Connect to Intune using tokens from your browser session
- **Token Storage & Management**: Securely save tokens for reuse to avoid re-entering tokens for each session
- **Script Testing**: Test your remediation scripts locally before deploying to Intune
- **Script Deployment**: Easily upload detection and remediation scripts to Intune
- **Code Signing**: Sign your remediation scripts with digital certificates to enhance security
- **Proper Structure**: Follows PowerShell best practices with Public/Private function separation
- **Integrated Authentication**: Self-contained implementation of browser token authentication

## Installation

### Manual Installation

1. Clone or download this repository
2. Copy the `IntuneRemediation` folder to one of your PowerShell module paths:
   - `$Home\Documents\WindowsPowerShell\Modules` (for current user)
   - `$env:ProgramFiles\WindowsPowerShell\Modules` (for all users)

### PowerShell Gallery (Recommended)

```powershell
Install-Module -Name IntuneRemediation -Scope CurrentUser
```

## Quick Start

### 1. Import the Module

```powershell
Import-Module IntuneRemediation
```

### 2. Connect to Intune

The module will automatically save your tokens for reuse:

```powershell
# First time: This will prompt you for a token with instructions and save it for future use
Initialize-IntuneConnection

# Future sessions: Will use your saved token automatically if it's still valid
Initialize-IntuneConnection 

# Use a different profile for multiple tenants
Initialize-IntuneConnection -ProfileName "TestTenant"

# Force a new token acquisition even if you have a saved token
Initialize-IntuneConnection -Force
```

### 3. Manage Saved Tokens

```powershell
# View information about all saved tokens
Get-IntuneTokenInfo

# Get a specific token
Get-IntuneToken -ProfileName "TestTenant"

# Remove expired tokens
Remove-IntuneToken -RemoveExpiredOnly

# Remove a specific token
Remove-IntuneToken -ProfileName "TestTenant"
```

### 4. Test a Remediation Script Locally

```powershell
Test-IntuneRemediationScript -DetectionScriptPath ".\Detect.ps1" -RemediationScriptPath ".\Remediate.ps1" -Cycles 1
```

### 5. Upload a Remediation Script to Intune

```powershell
$detection = Get-Content -Path ".\Detect.ps1" -Raw
$remediation = Get-Content -Path ".\Remediate.ps1" -Raw

New-IntuneRemediationScript -DisplayName "My Remediation Script" `
                           -Description "Fixes a common issue" `
                           -Publisher "IT Department" `
                           -DetectionScriptContent $detection `
                           -RemediationScriptContent $remediation `
                           -RunAsAccount "System"
```

## Token Storage and Security

The module securely stores tokens in your local AppData folder:
- Tokens are encrypted using PowerShell's secure string capabilities
- Each token is stored in its own file with metadata (expiration, user info)
- Token storage uses profile names to allow multiple tokens for different tenants
- The module automatically handles token validation and expiration

Default storage location:
```
%LOCALAPPDATA%\IntuneRemediation\
```

## Code Signing

The module includes functionality to digitally sign your remediation scripts:

### Why Sign Your Scripts?

- **Enhanced Security**: Signing ensures scripts haven't been tampered with
- **Intune Requirements**: You can configure Intune to only accept signed scripts
- **Compliance**: Many organizations require signed scripts for security policies

### Signing Certificates

The module supports finding certificates from several locations:
- Certificate store (CurrentUser or LocalMachine)
- PFX files from a specified path (default: C:\temp\certs)
- PFX files from a custom location

### Certificate Chain Requirements

For code signing to work properly, Windows needs the complete certificate chain installed:

1. **Code Signing Certificate**: Your certificate with private key (.pfx file)
2. **Intermediate CA Certificate**: The issuing authority's certificate
3. **Root CA Certificate**: The root certificate authority's certificate

If signing fails with "UnknownError" or "A certificate chain could not be built to a trusted root authority" error:

```powershell
# Install the root CA certificate to the Trusted Root Certification Authorities store
Import-Certificate -FilePath "C:\path\to\root-ca.cer" -CertStoreLocation Cert:\CurrentUser\Root

# Install the issuing/intermediate CA certificate to the Intermediate CA store
Import-Certificate -FilePath "C:\path\to\issuing-ca.cer" -CertStoreLocation Cert:\CurrentUser\CA

# Now try signing again
Set-AuthenticodeSignature -FilePath "YourScript.ps1" -Certificate (Get-Item -Path "Cert:\CurrentUser\My\YOUR_THUMBPRINT_HERE")
```

The module now includes an automatic certificate chain verification and installation function:

```powershell
# Verify and fix certificate chain issues for a certificate
$cert = Get-Item -Path "Cert:\CurrentUser\My\YOUR_THUMBPRINT_HERE"
Confirm-IntuneCodeSigningChain -Certificate $cert

# Automatically install missing certificates without prompting
Confirm-IntuneCodeSigningChain -Certificate $cert -AutoInstall

# Check the chain but don't prompt for installation (useful in scripts)
Confirm-IntuneCodeSigningChain -Certificate $cert -SkipPrompt
```

The `Protect-IntuneRemediationScript` function automatically uses this chain verification when signing scripts.

### Using the Signing Functionality

```powershell
# Sign a single script
Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\Detect-Issue.ps1"

# Sign all scripts in a folder
Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\Remediation"

# Sign using a specific certificate by thumbprint
Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\Detect-Issue.ps1" -CertificateThumbprint "1234567890ABCDEF1234567890ABCDEF12345678"

# Sign using a specific certificate file
Protect-IntuneRemediationScript -ScriptPath "C:\Scripts\Detect-Issue.ps1" -CertificatePath "C:\temp\certs\CodeSigningCert.pfx"
```

### Example Script

The module includes an example script in the `Examples\CodeSigning` folder:
- **Sign-RemediationScripts.ps1**: Demonstrates how to sign remediation scripts and includes sample detection and remediation scripts

### Troubleshooting Signing Issues

If you encounter signing problems, try these steps:

1. **Verify Certificate Validity**: Ensure your certificate is valid for code signing
   ```powershell
   Get-Item -Path "Cert:\CurrentUser\My\YOUR_THUMBPRINT_HERE" | Format-List *
   ```

2. **Check Certificate Trust Chain**: Make sure the entire chain is installed
   ```powershell
   $cert = Get-Item -Path "Cert:\CurrentUser\My\YOUR_THUMBPRINT_HERE"
   $chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
   $chain.Build($cert)
   $chain.ChainElements | Format-List *
   ```

3. **Test Direct Signing**: Try signing directly with Set-AuthenticodeSignature
   ```powershell
   Set-AuthenticodeSignature -FilePath "YourScript.ps1" -Certificate (Get-Item -Path "Cert:\CurrentUser\My\YOUR_THUMBPRINT_HERE")
   ```

4. **Try Different Timestamp Servers**: Sometimes timestamp server connectivity can cause issues
   ```powershell
   Set-AuthenticodeSignature -FilePath "YourScript.ps1" -Certificate (Get-Item -Path "Cert:\CurrentUser\My\YOUR_THUMBPRINT_HERE") -TimestampServer "http://timestamp.digicert.com"
   ```

### Deploying Signed Scripts

When deploying signed scripts to Intune, signature checking is enforced by default:

```powershell
# Script signature verification is ENABLED by default with publisher set to "Abdullah Ollivierre"
New-IntuneRemediationScript -DisplayName "Signed Remediation Script" `
                           -Description "Security-enhanced remediation" `
                           -DetectionScriptContent $detection `
                           -RemediationScriptContent $remediation

# To disable signature checking (not recommended)
New-IntuneRemediationScript -DisplayName "Unsigned Remediation Script" `
                           -DetectionScriptContent $detection `
                           -RemediationScriptContent $remediation `
                           -EnforceSignatureCheck:$false
```

## Sample Scripts

The module includes sample remediation scripts in the `Examples` folder:

- **ServiceMonitor**: Monitors and fixes the Windows Time service if it's not running
- **Deploy-ServiceMonitor.ps1**: Demonstrates how to test and deploy the scripts to Intune
- **Deploy-ServiceMonitor-Enhanced.ps1**: Demonstrates using stored tokens and token management

## SCHANNEL Script Management

The module includes a comprehensive set of SCHANNEL-related scripts designed to harden TLS security settings. These scripts are located in the `Examples\SCHANNEL-Scripts` folder and provide a complete solution for managing SCHANNEL settings through Intune.

### SCHANNEL Scripts and Intune

When deploying SCHANNEL scripts through Intune, it's important to understand Intune's capabilities and limitations:

- **Intune's Primary Focus**: Intune primarily manages endpoints (desktops, laptops, mobile devices) and has limited server management capabilities.
- **Server Management Limitations**: For comprehensive Windows Server management, tools like Microsoft Endpoint Configuration Manager (MECM) or Azure Arc are recommended.
- **Security Settings**: Intune can manage security-related settings on endpoints, which makes it appropriate for deploying client-side SCHANNEL configurations.

### Recommended SCHANNEL Scripts for Intune Deployment

Based on Intune's focus on endpoint management, the following SCHANNEL scripts are most appropriate for Intune deployment:

- **Client-Side Protocol Scripts** (`SCHANNEL-CliProto-*`): Configure how client devices communicate securely with servers
- **Cipher Suite Scripts** (`SCHANNEL-Cipher-*`): Determine which encryption algorithms are available on endpoints
- **Hash Algorithm Scripts** (`SCHANNEL-Hash-*`): Control which hashing algorithms are used for secure communications
- **Key Exchange Scripts** (`SCHANNEL-KeyEx-*`): Configure the key exchange algorithms available on endpoints

Server-side protocol scripts (`SCHANNEL-SrvProto-*`) are less appropriate for Intune deployment due to Intune's limited server management capabilities.

### SCHANNEL Script Deployment Tools

The module provides several specialized tools for managing SCHANNEL scripts in Intune:

#### 1. Deploy-SCHANNELScripts.ps1

This script automates the creation and deployment of SCHANNEL remediation scripts to Intune:

```powershell
# Basic usage - deploy all SCHANNEL scripts to Intune
.\Deploy-SCHANNELScripts.ps1

# Skip authentication (for signing scripts locally without deploying)
.\Deploy-SCHANNELScripts.ps1 -SkipAuthentication

# Force new authentication
.\Deploy-SCHANNELScripts.ps1 -Force
```

#### 2. Assign-SCHANNELScripts.ps1

This script helps assign SCHANNEL remediation scripts to specific Microsoft Entra groups:

```powershell
# Basic usage - interactive selection of scripts and groups
.\Assign-SCHANNELScripts.ps1

# Preview assignments without making changes
.\Assign-SCHANNELScripts.ps1 -WhatIf

# Pre-fill group ID
.\Assign-SCHANNELScripts.ps1 -GroupId "5b90aa-1234-5678-abcd-1234567890ab"
```

Key features:
- Interactive menu for selecting specific scripts or all scripts
- Validation of Entra group ID with detailed group information display
- Shows membership type, user count, device count, and nested group membership
- Requires confirmation before making assignments
- WhatIf mode for previewing changes

#### 3. Remove-SCHANNELScripts.ps1

This script safely removes SCHANNEL remediation scripts from Intune:

```powershell
# Basic usage - find and remove SCHANNEL scripts
.\Remove-SCHANNELScripts.ps1

# Preview removal without making changes
.\Remove-SCHANNELScripts.ps1 -WhatIf

# Remove scripts with a custom prefix
.\Remove-SCHANNELScripts.ps1 -SCHANNELPrefix "CUSTOM-SCHANNEL"
```

Safety features:
- Only targets scripts with the specified prefix
- Displays scripts to be removed and requires explicit confirmation
- Double confirmation for large numbers of scripts
- WhatIf mode for previewing removals

### Testing SCHANNEL Scripts

The module includes a test script to validate SCHANNEL scripts before deployment:

```powershell
# Validate all SCHANNEL scripts
.\Test-SCHANNELScripts.ps1
```

This ensures that all SCHANNEL scripts are properly formatted and function correctly before deploying them to Intune.

## How to Create a Remediation Script

### 1. Detection Script

The detection script should:
- Return exit code 0 (or $true) if the system is compliant
- Return exit code 1 (or $false) if the system is non-compliant and requires remediation

Example:
```powershell
# Check if a service is running
$service = Get-Service -Name "ServiceName"
if ($service.Status -eq "Running") {
    # Compliant
    exit 0
} else {
    # Non-compliant
    exit 1
}
```

### 2. Remediation Script

The remediation script should:
- Fix the issue identified by the detection script
- Return exit code 0 if remediation was successful
- Return exit code 1 if remediation failed

Example:
```powershell
# Start the service
try {
    Start-Service -Name "ServiceName" -ErrorAction Stop
    exit 0  # Success
} catch {
    exit 1  # Failed
}
```

## Getting Browser Tokens

The `Initialize-IntuneConnection` function will guide you through the token acquisition process, but here's how to do it manually:

1. Open a browser and go to https://endpoint.microsoft.com/
2. Sign in with your admin account
3. Press F12 to open developer tools
4. Go to the Network tab
5. Refresh the page (F5)
6. Filter requests by typing "graph.microsoft" in the filter box
7. Click on any request to graph.microsoft.com
8. In the Headers tab, find "Authorization: Bearer eyJ..."
9. Copy the entire token (starting with "eyJ")

## Functions

### Public Functions

#### Authentication & Token Management
- **Initialize-IntuneConnection**: Connect to Intune using browser token authentication
- **Connect-IntuneWithToken**: Legacy method to connect to Intune using a token
- **Save-IntuneToken**: Save a token for future use
- **Get-IntuneToken**: Retrieve a saved token
- **Get-IntuneTokenInfo**: View information about saved tokens
- **Remove-IntuneToken**: Delete saved tokens

#### Remediation Script Management
- **New-IntuneRemediationScript**: Create a new remediation script in Intune
- **Test-IntuneRemediationScript**: Test a remediation script locally before deployment

#### Code Signing
- **Protect-IntuneRemediationScript**: Sign PowerShell remediation scripts with code signing certificates
- **Confirm-IntuneCodeSigningChain**: Verify and install certificate chains for code signing certificates

## Requirements

- PowerShell 5.1 or later
- Microsoft.Graph.Authentication module (installed automatically if needed)
- Microsoft.Graph.DeviceManagement module (installed automatically if needed)
- Administrative access to Microsoft Intune

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Token-Based Authentication

### Authentication Approach

The IntuneRemediation module uses a token-based authentication approach by default:

- **Token-Only By Default**: All scripts in the module default to using token-based authentication only, with no interactive browser prompts.
- **No Interactive Auth**: By default, interactive browser authentication is disabled to prevent unexpected browser windows.
- **Token Acquisition**: To obtain tokens, use the provided `GetIntuneToken.ps1` script in the Examples folder.

### Getting Started with Token Authentication

1. **First-time setup**: Run the `GetIntuneToken.ps1` script to obtain your initial token:

```powershell
# Run the helper script to obtain a token with browser authentication
.\Examples\GetIntuneToken.ps1

# For a specific profile
.\Examples\GetIntuneToken.ps1 -ProfileName "ProductionTenant"
```

2. **Using your token**: Once you have a token, all other scripts will use it automatically:

```powershell
# All other scripts will use the saved token without prompting
.\Examples\SCHANNEL-Scripts\Remove-SCHANNELScripts.ps1

# You can also provide a token directly if needed
.\Examples\SCHANNEL-Scripts\Remove-SCHANNELScripts.ps1 -Token "eyJ0eXAiOiJKV1QiLCJhbGc..."
```

### Manually Getting a Token (Advanced)

If you need to manually obtain a token:

1. Open Microsoft Edge or Chrome
2. Navigate to `https://developer.microsoft.com/en-us/graph/graph-explorer`
3. Sign in with your Intune admin account
4. Open Developer Tools (F12)
5. Go to the Network tab
6. Refresh the page
7. Click on any request to `graph.microsoft.com`
8. In the Headers tab, find the "Authorization" header
9. Copy the token value (starts with "Bearer eyJ...")
10. Remove "Bearer " from the beginning

Pass this token to your scripts using the `-Token` parameter or save it using `Save-IntuneToken`.

### Enabling Interactive Authentication (Not Recommended)

If you need to enable interactive authentication for a specific scenario:

```powershell
# Only use this when you specifically need interactive auth
Initialize-IntuneConnection -DisableInteractiveAuth:$false
``` 