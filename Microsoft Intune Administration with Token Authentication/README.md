# Microsoft Intune Administration with Token Authentication

## Overview

This project provides a streamlined approach to manage Microsoft Intune using the Microsoft Graph PowerShell modules with browser-acquired tokens. This method offers several advantages over traditional authentication methods:

- **No App Registration Required**: No need to create and manage Azure AD applications
- **Immediate Access**: Use your existing browser session's credentials
- **Full PowerShell Capabilities**: Access to all Microsoft Graph PowerShell cmdlets
- **Cross-Platform Support**: Works on Windows, macOS, and Linux
- **Reduced Complexity**: Simplified authentication process

## Prerequisites

- PowerShell 5.1 or PowerShell Core 7.x
- Web browser with access to [Microsoft Endpoint Manager admin center](https://endpoint.microsoft.com)
- Administrative access to Microsoft Intune
- Microsoft Graph PowerShell modules (installed automatically by the script)

## Quick Start

1. Run the `ConnectToIntune.ps1` script
2. Follow the on-screen instructions to obtain a token from your browser
3. Paste the token when prompted
4. Start using Microsoft Graph PowerShell cmdlets to manage Intune

## Detailed Setup Instructions

### Step 1: Obtain the Authentication Token

1. Open a browser and go to: https://endpoint.microsoft.com/
2. Sign in with your admin account (if not already signed in)
3. Press F12 to open developer tools
4. Go to 'Network' tab
5. Refresh the page (F5)
6. Filter requests by typing 'graph.microsoft' in the filter box
7. Click on any request to graph.microsoft.com
8. In the Headers tab, scroll to find 'Authorization: Bearer eyJ...'
9. Copy the entire token (starts with 'eyJ' and is very long)

### Step 2: Connect to Microsoft Graph

1. Run the `ConnectToIntune.ps1` script
2. Paste your token when prompted
3. The script will:
   - Validate your token
   - Install required Microsoft Graph PowerShell modules (if needed)
   - Connect to Microsoft Graph with your token
   - Provide examples of available commands

## How It Works

The solution uses a two-pronged approach:

1. **Microsoft Graph PowerShell Modules**: The primary method, giving access to hundreds of built-in cmdlets
2. **REST API Fallback**: Direct REST API access as a backup method

The token is converted from plain text to a SecureString using:
```powershell
$secureToken = ConvertTo-SecureString -String $Token -AsPlainText -Force
```

And then used to connect to Microsoft Graph:
```powershell
Connect-MgGraph -AccessToken $secureToken -NoWelcome
```

## Key Features

- **Token Validation**: Ensures the token has appropriate permissions
- **Module Auto-Installation**: Automatically installs required modules
- **Dual-Mode Access**: Both PowerShell cmdlets and REST API approaches
- **Reconnection Function**: Easy token refresh when needed
- **Comprehensive Examples**: Ready-to-use command examples

## Common Usage Examples

### Device Management

```powershell
# Get all devices
Get-MgDeviceManagementManagedDevice | Select-Object DeviceName, OperatingSystem, OSVersion

# Get specific devices by filter
$filter = "startsWith(deviceName,'WIN')"
Get-MgDeviceManagementManagedDevice -Filter $filter

# Find non-compliant devices
Get-MgDeviceManagementManagedDevice -Filter "complianceState eq 'noncompliant'" | 
    Select-Object DeviceName, OperatingSystem, LastSyncDateTime

# Count devices by operating system
Get-MgDeviceManagementManagedDevice | 
    Group-Object -Property OperatingSystem | 
    Select-Object Name, Count
```

### Configuration Management

```powershell
# Get device configurations
Get-MgDeviceManagementDeviceConfiguration | Select-Object Id, DisplayName

# Get compliance policies
Get-MgDeviceManagementDeviceCompliancePolicy | Select-Object DisplayName

# Get app protection policies
Get-MgDeviceAppManagementAndroidManagedAppProtection | Select-Object DisplayName
Get-MgDeviceAppManagementIosManagedAppProtection | Select-Object DisplayName
```

### Remote Actions

```powershell
# Get a specific device
$device = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DEVICE-NAME'"
$deviceId = $device.Id

# Available actions
Invoke-MgRebootManagedDevice -ManagedDeviceId $deviceId
Invoke-MgRemoteLockManagedDevice -ManagedDeviceId $deviceId
Invoke-MgResetPasscodeManagedDevice -ManagedDeviceId $deviceId
```

## Troubleshooting

### Token Expiration

Tokens expire after approximately one hour. When this happens:

1. **Option 1**: Run the script again to get a fresh token
2. **Option 2**: Use the `Reconnect-IntuneGraph` function:

```powershell
function Reconnect-IntuneGraph {
    # Get a new token from browser using the same steps
    $newToken = Read-Host "Enter your new token"
    $global:IntuneToken = $newToken
    
    # Update REST API headers
    $global:IntuneHeaders = @{
        "Authorization" = "Bearer $global:IntuneToken"
        "Content-Type" = "application/json"
    }
    
    # Update Graph PowerShell connection
    $secureToken = ConvertTo-SecureString -String $global:IntuneToken -AsPlainText -Force
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    Connect-MgGraph -AccessToken $secureToken -NoWelcome
    Write-Host "Reconnected to Intune!" -ForegroundColor Green
}
```

### Module Installation Issues

If you encounter module installation errors:

```powershell
# Update Microsoft Graph modules
Update-Module Microsoft.Graph.Authentication -Force
Update-Module Microsoft.Graph.DeviceManagement -Force
Update-Module Microsoft.Graph.Users -Force

# If errors persist, try installing with AllowClobber
Install-Module Microsoft.Graph.Authentication -Force -AllowClobber
```

### Permission Issues

If you receive "Insufficient privileges" errors:

1. Ensure you're using an account with appropriate Intune admin roles
2. Check if your token includes the necessary permissions (scopes)
3. Try obtaining a new token after logging in with a global admin account

## Maintaining and Updating

### Keeping Modules Updated

Regularly update the Microsoft Graph PowerShell modules:

```powershell
Update-Module Microsoft.Graph -Force
```

### Script Updates

When Microsoft updates the Graph API:

1. Check for changes in endpoints or parameter requirements
2. Update REST API calls as needed
3. Microsoft Graph PowerShell modules are maintained by Microsoft and should be updated automatically

## Future Enhancements

- [ ] Token refresh automation without manual copying
- [ ] Enhanced error handling and logging
- [ ] Support for batch operations with Graph API
- [ ] Integration with other Microsoft 365 management tasks

## Resources

- [Microsoft Graph PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/microsoftgraph/overview)
- [Microsoft Graph API Reference](https://docs.microsoft.com/en-us/graph/api/overview)
- [Intune API Documentation](https://docs.microsoft.com/en-us/graph/api/resources/intune-graph-overview)
- [PowerShell Gallery - Microsoft.Graph](https://www.powershellgallery.com/packages/Microsoft.Graph)

## Conclusion

This approach provides a simplified yet powerful method for accessing and managing Microsoft Intune through PowerShell. By leveraging browser-acquired tokens, we eliminate the complexity of app registrations while maintaining full access to the Microsoft Graph API capabilities.

---

*Last updated: November 8, 2023*