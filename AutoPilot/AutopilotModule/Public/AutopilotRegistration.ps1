# Autopilot registration related functions

function Install-AutopilotPrerequisites {
    [CmdletBinding()]
    param()
    
    # Set TLS 1.2 for compatibility
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Install NuGet silently if not already installed
    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-Host "Installing NuGet provider..." -ForegroundColor Yellow
        Install-PackageProvider -Name NuGet -ForceBootstrap -Force -Confirm:$false | Out-Null
        Write-Host "NuGet provider installed successfully." -ForegroundColor Green
    } else {
        Write-Host "NuGet provider is already installed." -ForegroundColor Green
    }
    
    # Install required script if not already installed
    if (-not (Get-InstalledScript -Name Get-WindowsAutoPilotInfo -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Get-WindowsAutoPilotInfo script..." -ForegroundColor Yellow
        Install-Script -Name Get-WindowsAutoPilotInfo -Force -Scope CurrentUser -Confirm:$false
        Write-Host "Get-WindowsAutoPilotInfo script installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Get-WindowsAutoPilotInfo script is already installed." -ForegroundColor Green
    }
}

function Register-DeviceToAutopilot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantID,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientID,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientSecret,
        
        [Parameter()]
        [switch]$RebootAfterRegistration = $false,
        
        [Parameter()]
        [int]$RebootDelay = 10
    )
    
    # Get the path to the installed script
    $installedScript = Get-InstalledScript -Name Get-WindowsAutoPilotInfo
    if (-not $installedScript) {
        Write-Error "Get-WindowsAutoPilotInfo script not found. Please run Install-AutopilotPrerequisites first."
        return $false
    }
    
    Write-Host "Using Get-WindowsAutoPilotInfo from: $($installedScript.InstalledLocation)" -ForegroundColor Green
    
    # Create parameter hashtable for splatting
    $params = @{
        Online = $true
        TenantId = $TenantID
        AppId = $ClientID
        AppSecret = $ClientSecret
    }
    
    # Execute the script with splatted parameters
    try {
        & "$($installedScript.InstalledLocation)\Get-WindowsAutoPilotInfo.ps1" @params
        $registrationSuccess = $?
        
        if ($registrationSuccess) {
            Write-Host "`nDevice registration successful!" -ForegroundColor Green
            
            if ($RebootAfterRegistration) {
                Write-Host "System will reboot in $RebootDelay seconds to apply changes..." -ForegroundColor Yellow
                
                # Countdown display
                $RebootDelay..1 | ForEach-Object {
                    Write-Host "Rebooting in $_ seconds..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                }
                
                # Initiate reboot
                Restart-Computer -Force
            } else {
                Write-Host "System will not be rebooted automatically. Please reboot manually when convenient." -ForegroundColor Yellow
            }
            
            Show-AutopilotNextSteps
        } else {
            Write-Error "Failed to register device with Autopilot."
        }
        
        return $registrationSuccess
    } catch {
        Write-Error "Failed to execute Get-WindowsAutoPilotInfo: $_"
        return $false
    }
}

function Show-AutopilotNextSteps {
    [CmdletBinding()]
    param()
    
    $nextStepsMessage = @"

[Next Steps]
1. Go to Endpoint Manager Portal > Devices > Windows > Windows enrollment > Devices (https://intune.microsoft.com/#view/Microsoft_Intune_Enrollment/AutopilotDevices.ReactView/filterOnManualRemediationRequired~/false)
2. Look for this device in the Windows Autopilot devices list (can take 15-30 minutes to appear)
3. Ensure an Autopilot deployment profile is assigned to the device
4. Restart the computer - you should see your company branding on the login screen

For User-Driven deployment:
- The user can now sign in and the device will be automatically configured
- To generate a Temp Access Pass, use Entra ID > Users > Authentication methods > Temp Access Pass

For Pre-Provisioning:
- Boot to Windows PE or use Autopilot Pre-provisioning (formally known as White Glove)
- Follow the OOBE process with the provided administrative credentials

Note: This script uses Autopilot v1 enrollment. For Autopilot Device Prep (v2.0), different steps are required.
"@
    
    Write-Host $nextStepsMessage -ForegroundColor Cyan
}

function Register-DeviceWithPromptedCredentials {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SecretsFilePath,
        
        [Parameter()]
        [switch]$RebootAfterRegistration = $false,
        
        [Parameter()]
        [int]$RebootDelay = 10
    )
    
    if (-not $SecretsFilePath) {
        $moduleRoot = Split-Path -Parent -Path (Get-Module AutopilotModule).Path
        $SecretsFilePath = Join-Path $moduleRoot "secrets.psd1"
    }
    
    $warningMessage = @"
[WARNING] Before proceeding, ensure your Entra ID App Registration has the following Microsoft Graph API permissions:

Required Application Permissions (NOT Delegated):
1. DeviceManagementServiceConfig.ReadWrite.All
   - Purpose: Read and write Windows Autopilot deployment configurations
   - Type: Application
   - Required: Yes

2. Device.ReadWrite.All
   - Purpose: Create and manage device objects
   - Type: Application
   - Required: Yes

3. DeviceManagementManagedDevices.ReadWrite.All
   - Purpose: Read and write Microsoft Intune managed devices
   - Type: Application
   - Required: Yes

4. Organization.Read.All
   - Purpose: Read organization information (tenant details)
   - Type: Application
   - Required: Yes

5. Application.Read.All
   - Purpose: Read application information (app registration details)
   - Type: Application
   - Required: Yes

Optional Application Permissions (NOT Delegated):
6. Group.ReadWrite.All
   - Purpose: Manage group assignments for devices
   - Type: Application
   - Required: Only if using group assignments

7. Domain.ReadWrite.All
   - Purpose: Manage domain settings for hybrid join
   - Type: Application
   - Required: Only if using hybrid Azure AD join

Important Notes:
- ALL permissions must be configured as Application permissions (NOT Delegated)
- Admin consent MUST be granted for all permissions
- A valid client secret with sufficient expiry time is required
- Global Administrator rights needed for granting admin consent

Press Ctrl+C to cancel if these permissions are not configured.
"@

    Write-Host $warningMessage -ForegroundColor Yellow
    
    Start-Sleep -Seconds 5
    
    # Ensure we're running with the right execution policy
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    
    # Install the necessary prerequisites
    Install-AutopilotPrerequisites
    
    # Initialize variables for the loop
    $secretsResult = $null
    $secretsValid = $false
    
    # Try to get existing secrets or create new ones
    do {
        $secretsResult = Get-ValidSecrets -FilePath $SecretsFilePath
        $secretsValid = $secretsResult.SecretsValid
        
        if (-not $secretsValid) {
            Write-Warning "Credentials validation failed. Please try again."
        }
    } while (-not $secretsValid)
    
    # After getting valid credentials, get app details and test secret
    if ($secretsValid) {
        $config = $secretsResult.Config
        $validationResults = $secretsResult.ValidationResults
        $tenantName = $secretsResult.TenantName
        
        $appDetails = Get-AppRegistrationDetails -ClientID $config.ClientID -AccessToken $validationResults.AccessToken
        $secretValidation = Test-ClientSecretValidity -ClientID $config.ClientID -ClientSecret $config.ClientSecret
        
        # Show initialization report
        Show-InitializationReport -TenantName $tenantName -TenantID $config.TenantID -ClientID $config.ClientID `
            -ValidationResults $validationResults -AppDetails $appDetails -SecretValidation $secretValidation
            
        # Register the device with Autopilot
        Register-DeviceToAutopilot -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret `
            -RebootAfterRegistration:$RebootAfterRegistration -RebootDelay $RebootDelay
    }
}

# Export functions to make them available within the module
Export-ModuleMember -Function Install-AutopilotPrerequisites, Register-DeviceToAutopilot, 
                     Show-AutopilotNextSteps, Register-DeviceWithPromptedCredentials
