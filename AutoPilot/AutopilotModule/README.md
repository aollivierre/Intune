# Windows Autopilot Registration Module

This PowerShell module provides a structured and secure approach to Windows Autopilot device registration, with proper credential management and error handling.

## Features

- **Secure Credential Management**: Credentials are encrypted and stored locally
- **Automatic Prerequisite Installation**: Ensures required dependencies are installed
- **Permission Validation**: Verifies all required Microsoft Graph API permissions
- **Detailed Reporting**: Provides comprehensive reports on initialization status
- **Modular Design**: Well-organized code in separate functional components
- **Error Handling**: Robust error handling throughout the registration process

## Module Structure

```
AutopilotModule/
│
├── Private/                   # Internal module functions
│   ├── Authentication.ps1     # Authentication functions
│   ├── Encryption.ps1         # Encryption/decryption utilities
│   └── GraphAPI.ps1           # Microsoft Graph API interaction
│
├── Public/                    # Exported module functions
│   ├── AutopilotRegistration.ps1  # Registration functions
│   └── SecretsManagement.ps1      # Secrets handling functions
│
├── AutopilotModule.psd1       # Module manifest
├── AutopilotModule.psm1       # Module loader
├── README.md                  # This file
└── secrets.psd1              # Encrypted secrets (created at runtime)
```

## Main Functions

| Function | Description |
|----------|-------------|
| `Register-DeviceWithPromptedCredentials` | Main function to register a device with Autopilot |
| `Install-AutopilotPrerequisites` | Installs required prerequisites |
| `New-SecretsFile` | Creates a new encrypted secrets file |
| `Import-SecretsFile` | Imports and decrypts secrets file |
| `Register-DeviceToAutopilot` | Performs the actual device registration |

## Requirements

- PowerShell 5.1 or higher
- Internet connectivity
- Entra ID App Registration with the following permissions:
  - DeviceManagementServiceConfig.ReadWrite.All
  - Device.ReadWrite.All
  - DeviceManagementManagedDevices.ReadWrite.All
  - Organization.Read.All
  - Application.Read.All

## Usage Example

```powershell
# Import the module
Import-Module -Name ".\AutopilotModule"

# Register a device and reboot after registration
Register-DeviceWithPromptedCredentials -RebootAfterRegistration -RebootDelay 10

# or use the simplified frontend script
.\Register-AutopilotDevice.ps1 -RebootAfterRegistration
```

## Version History

- **1.1.0**: Initial modular release with improved error handling and secure credential management

## License

Copyright © 2025 Canada Computing. All rights reserved.
