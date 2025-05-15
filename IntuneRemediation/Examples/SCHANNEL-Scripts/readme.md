# SCHANNEL Security Scripts for Intune

## Overview

This collection of PowerShell scripts provides comprehensive management of Windows SCHANNEL security settings through Microsoft Intune. The scripts are designed to be deployed as Intune Proactive Remediation packages to detect and enforce secure SCHANNEL configurations across your Windows devices.

## Categories

The scripts are organized into five categories, each targeting a specific aspect of SCHANNEL security:

1. **Server Protocols** - Controls which SSL/TLS protocol versions are enabled on the server side
2. **Client Protocols** - Controls which SSL/TLS protocol versions are enabled on the client side
3. **Ciphers** - Manages the encryption ciphers available for secure communications
4. **Hashes** - Controls which hashing algorithms are allowed for signature verification
5. **Key Exchanges** - Manages the key exchange algorithms used during handshake

## Directory Structure

```
SCHANNEL-Scripts/
├── ServerProtocols/
│   ├── Detection/
│   │   └── [Protocol detection scripts]
│   └── Remediation/
│       └── [Protocol remediation scripts]
├── ClientProtocols/
│   ├── Detection/
│   │   └── [Protocol detection scripts]
│   └── Remediation/
│       └── [Protocol remediation scripts]
├── Ciphers/
│   ├── Detection/
│   │   └── [Cipher detection scripts]
│   └── Remediation/
│       └── [Cipher remediation scripts]
├── Hashes/
│   ├── Detection/
│   │   └── [Hash detection scripts]
│   └── Remediation/
│       └── [Hash remediation scripts]
└── KeyExchanges/
    ├── Detection/
    │   └── [Key exchange detection scripts]
    └── Remediation/
        └── [Key exchange remediation scripts]
```

## How It Works

Each script pair follows a consistent pattern:

- **Detection Script**: Checks if the specific SCHANNEL setting is properly configured
  - Returns exit code 0 if compliant (no remediation needed)
  - Returns exit code 1 if non-compliant (remediation needed)
  
- **Remediation Script**: Applies the correct configuration
  - Creates or modifies registry settings under `HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL`
  - Returns exit code 0 if remediation was successful
  - Returns exit code 1 if remediation failed

## Deployment

### Prerequisites

1. The IntuneRemediation PowerShell module (included in this repository)
2. A code signing certificate (recommended for secure deployment)
3. Appropriate permissions to create remediation scripts in Microsoft Intune

### Automated Deployment

The included deployment script automates the process of signing and uploading all script pairs to Intune:

```powershell
# Import the IntuneRemediation module
Import-Module IntuneRemediation

# Run the deployment script
./Deploy-SCHANNELScripts.ps1
```

The deployment script will:
1. Validate your Intune connection
2. Prompt for a code signing certificate (if not specified)
3. Sign all scripts with the selected certificate
4. Upload each script pair to Intune with appropriate naming and descriptions
5. Provide a summary of the deployment results

### Testing Before Deployment

You can validate all scripts before deploying them to Intune:

```powershell
./Test-SCHANNELScripts.ps1
```

This will check all scripts for proper formatting, syntax, and ensure that each detection script has a corresponding remediation script.

### Manual Deployment

If you prefer to upload scripts manually or selectively:

1. Sign the scripts with your code signing certificate:

```powershell
Import-Module IntuneRemediation
Protect-IntuneRemediationScript -ScriptPath ".\ServerProtocols\Detection" -CertificateThumbprint "YOUR_CERT_THUMBPRINT"
Protect-IntuneRemediationScript -ScriptPath ".\ServerProtocols\Remediation" -CertificateThumbprint "YOUR_CERT_THUMBPRINT"
```

2. Upload individual script pairs using the New-IntuneRemediationScript function:

```powershell
$detection = Get-Content -Path ".\ServerProtocols\Detection\Detect-TLS1.0-Server.ps1" -Raw
$remediation = Get-Content -Path ".\ServerProtocols\Remediation\Remediate-TLS1.0-Server.ps1" -Raw

New-IntuneRemediationScript -DisplayName "SCHANNEL-SrvProto-TLS1.0-Server" `
                           -Description "Configures TLS 1.0 Server settings for SCHANNEL security" `
                           -Publisher "Security Team" `
                           -DetectionScriptContent $detection `
                           -RemediationScriptContent $remediation `
                           -RunAsAccount "System"
```

## Naming Convention

When uploaded to Intune, the scripts follow this naming convention:

```
SCHANNEL-{CategoryPrefix}-{ProtocolName}
```

Category prefixes:
- ServerProtocols: SrvProto
- ClientProtocols: CliProto
- Ciphers: Cipher
- Hashes: Hash
- KeyExchanges: KeyEx

For example: `SCHANNEL-SrvProto-TLS1.0-Server` or `SCHANNEL-Cipher-AES128128`

## Customization

### Adding New Scripts

To add new scripts to an existing category:

1. Create detection and remediation scripts following the existing naming conventions
2. Place them in the appropriate category's Detection/Remediation folders
3. Run the deployment script to sign and upload the new scripts

### Modifying Security Settings

If you need to modify the security requirements:

1. Edit the detection script to check for your desired configuration
2. Edit the remediation script to apply your desired configuration
3. Re-sign and re-deploy the modified scripts

## Security Considerations

These scripts make significant changes to the Windows SCHANNEL security configuration, which can impact:

- Website accessibility
- Application compatibility
- Security compliance levels

Carefully test these settings in a controlled environment before deploying widely. Consider creating security rings to gradually roll out changes.

## References

- [Microsoft SCHANNEL Documentation](https://docs.microsoft.com/en-us/windows-server/security/tls/tls-registry-settings)
- [Microsoft Intune Proactive Remediation](https://docs.microsoft.com/en-us/mem/analytics/proactive-remediations)
- [Windows Cryptography Next Generation (CNG)](https://docs.microsoft.com/en-us/windows/win32/seccng/cng-portal)
