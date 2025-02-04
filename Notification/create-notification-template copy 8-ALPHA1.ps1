#############################################################################################################
#
#   Tool:           Intune Win32 Deployer
#   Author:         Abdullah Ollivierre
#   Website:        https://github.com/aollivierre
#   Twitter:        https://x.com/ollivierre
#   LinkedIn:       https://www.linkedin.com/in/aollivierre
#
#   Description:    https://github.com/aollivierre
#
#############################################################################################################

<#
    .SYNOPSIS
    Packages any custom app for MEM (Intune) deployment.
    Uploads the packaged into the target Intune tenant.

    .NOTES
    For details on IntuneWin32App go here: https://github.com/aollivierre

#>


#region RE-LAUNCH SCRIPT IN POWERSHELL 5 FUNCTION
#################################################################################################
#                                                                                               #
#                           RE-LAUNCH SCRIPT IN POWERSHELL 5 FUNCTION                           #
#                                                                                               #
#################################################################################################

function Relaunch-InPowerShell5 {
    # Check the current version of PowerShell
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Host "Hello from PowerShell 7"

        # Get the script path (works inside a function as well)
        $scriptPath = $PSCommandPath

        # $scriptPath = $MyInvocation.MyCommand.Definition
        $ps5Path = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"

        # Build the argument to relaunch this script in PowerShell 5 with -NoExit
        $ps5Args = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

        Write-Host "Relaunching in PowerShell 5..."
        Start-Process -FilePath $ps5Path -ArgumentList $ps5Args

        # Exit the current PowerShell 7 session to allow PowerShell 5 to take over
        exit
    }

    # If relaunching in PowerShell 5
    Write-Host "Hello from PowerShell 5"
}

Relaunch-InPowerShell5


#endregion RE-LAUNCH SCRIPT IN POWERSHELL 5 FUNCTION
#################################################################################################
#                                                                                               #
#                           END OF RE-LAUNCH SCRIPT IN POWERSHELL 5 FUNCTION                    #
#                                                                                               #
#################################################################################################


# Set environment variable globally for all users
[System.Environment]::SetEnvironmentVariable('EnvironmentMode', 'dev', 'Machine')

# Retrieve the environment mode (default to 'prod' if not set)
$mode = $env:EnvironmentMode

#region FIRING UP MODULE STARTER
#################################################################################################
#                                                                                               #
#                                 FIRING UP MODULE STARTER                                      #
#                                                                                               #
#################################################################################################

# Invoke-Expression (Invoke-RestMethod "https://raw.githubusercontent.com/aollivierre/module-starter/main/Install-EnhancedModuleStarterAO.ps1")

# Wait-Debugger

# Define a hashtable for splatting
# $moduleStarterParams = @{
#     Mode                   = 'dev'
#     SkipPSGalleryModules   = $true
#     SkipCheckandElevate    = $true
#     SkipPowerShell7Install = $true
#     SkipEnhancedModules    = $true
#     SkipGitRepos           = $true
# }

# Call the function using the splat
# Invoke-ModuleStarter @moduleStarterParams





# Define a hashtable for splatting
# $moduleStarterParams = @{
#     Mode                   = 'PROD'
#     SkipPSGalleryModules   = $FALSE
#     SkipCheckandElevate    = $FALSE
#     SkipPowerShell7Install = $FALSE
#     SkipEnhancedModules    = $FALSE
#     SkipGitRepos           = $true
# }

# # Call the function using the splat
# Invoke-ModuleStarter @moduleStarterParams


# Wait-Debugger

#endregion FIRING UP MODULE STARTER

# Toggle based on the environment mode
switch ($mode) {
    'dev' {
        Write-EnhancedLog -Message "Running in development mode" -Level 'WARNING'
        # Your development logic here
    }
    'prod' {
        Write-EnhancedLog -Message "Running in production mode" -ForegroundColor Green
        # Your production logic here
    }
    default {
        Write-EnhancedLog -Message "Unknown mode. Defaulting to production." -ForegroundColor Red
        # Default to production
    }
}



#region HANDLE PSF MODERN LOGGING
#################################################################################################
#                                                                                               #
#                            HANDLE PSF MODERN LOGGING                                          #
#                                                                                               #
#################################################################################################
Set-PSFConfig -Fullname 'PSFramework.Logging.FileSystem.ModernLog' -Value $true -PassThru | Register-PSFConfig -Scope SystemDefault

# Define the base logs path and job name
$JobName = "IntuneNotifications"
$parentScriptName = Get-ParentScriptName
Write-EnhancedLog -Message "Parent Script Name: $parentScriptName"

# Call the Get-PSFCSVLogFilePath function to generate the dynamic log file path
$paramGetPSFCSVLogFilePath = @{
    LogsPath         = 'C:\Logs\PSF'
    JobName          = $jobName
    parentScriptName = $parentScriptName
}

$csvLogFilePath = Get-PSFCSVLogFilePath @paramGetPSFCSVLogFilePath

$instanceName = "$parentScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Configure the PSFramework logging provider to use CSV format
$paramSetPSFLoggingProvider = @{
    Name            = 'logfile'
    InstanceName    = $instanceName  # Use a unique instance name
    FilePath        = $csvLogFilePath  # Use the dynamically generated file path
    Enabled         = $true
    FileType        = 'CSV'
    EnableException = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider
#endregion HANDLE PSF MODERN LOGGING


#region HANDLE Transript LOGGING
#################################################################################################
#                                                                                               #
#                            HANDLE Transript LOGGING                                           #
#                                                                                               #
#################################################################################################
# Start the script with error handling
try {
    # Generate the transcript file path
    $GetTranscriptFilePathParams = @{
        TranscriptsPath  = "C:\Logs\Transcript"
        JobName          = $jobName
        parentScriptName = $parentScriptName
    }
    $transcriptPath = Get-TranscriptFilePath @GetTranscriptFilePathParams
    
    # Start the transcript
    Write-EnhancedLog -Message "Starting transcript at: $transcriptPath"
    Start-Transcript -Path $transcriptPath
}
catch {
    Write-EnhancedLog -Message "An error occurred during script execution: $_" -Level 'ERROR'
    if ($transcriptPath) {
        Stop-Transcript
        Write-EnhancedLog -Message "Transcript stopped." -ForegroundColor Cyan
        # Stop logging in the finally block

    }
    else {
        Write-EnhancedLog -Message "Transcript was not started due to an earlier error." -ForegroundColor Red
    }

    # Stop PSF Logging

    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in the finally block by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false

    Handle-Error -ErrorRecord $_
    throw $_  # Re-throw the error after logging it
}
#endregion HANDLE Transript LOGGING

try {
    #region Script Logic
    #################################################################################################
    #                                                                                               #
    #                                    Script Logic                                               #
    #                                                                                               #
    #################################################################################################


    #region LOADING SECRETS FOR GRAPH
    #################################################################################################
    #                                                                                               #
    #                                 LOADING SECRETS FOR GRAPH                                     #
    #                                                                                               #
    #################################################################################################


    #     Start
    #   |
    #   v
    # Check if secrets directory exists
    #   |
    #   +-- [Yes] --> Check if tenant folders exist
    #   |                |
    #   |                +-- [Yes] --> List tenant folders
    #   |                |                |
    #   |                |                v
    #   |                |       Display list and prompt user for tenant selection
    #   |                |                |
    #   |                |                v
    #   |                |       Validate user's selected tenant folder
    #   |                |                |
    #   |                |                +-- [Valid] --> Check if secrets.json exists
    #   |                |                |                 |
    #   |                |                |                 +-- [Yes] --> Load secrets from JSON file
    #   |                |                |                 |                |
    #   |                |                |                 |                v
    #   |                |                |                 |        Check for PFX file
    #   |                |                |                 |                |
    #   |                |                |                 |                +-- [Yes] --> Validate single PFX file
    #   |                |                |                 |                |                 |
    #   |                |                |                 |                |                 v
    #   |                |                |                 |                |        Assign values from secrets to variables
    #   |                |                |                 |                |                 |
    #   |                |                |                 |                |                 v
    #   |                |                |                 |                +--> Write log "PFX file found"
    #   |                |                |                 |
    #   |                |                |                 +-- [No] --> Error: secrets.json not found
    #   |                |                |                
    #   |                |                +-- [Invalid] --> Error: Invalid tenant folder
    #   |                |                
    #   |                +-- [No] --> Error: No tenant folders found
    #   |
    #   +-- [No] --> Error: Secrets directory not found
    #   |
    #   v
    # End


    # Define the path to the secrets directory
    $secretsDirPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets"

    # Check if the secrets directory exists
    if (-Not (Test-Path -Path $secretsDirPath)) {
        Write-Error "Secrets directory not found at '$secretsDirPath'."
        throw "Secrets directory not found"
    }

    # List all folders (tenants) in the secrets directory
    $tenantFolders = Get-ChildItem -Path $secretsDirPath -Directory

    if ($tenantFolders.Count -eq 0) {
        Write-Error "No tenant folders found in the secrets directory."
        throw "No tenant folders found"
    }

    # Display the list of tenant folders and ask the user to confirm
    Write-Host "Available tenant folders:"
    $tenantFolders | ForEach-Object { Write-Host "- $($_.Name)" }

    $selectedTenant = Read-Host "Enter the name of the tenant folder you want to use"

    # Validate the user's selection
    $selectedTenantPath = Join-Path -Path $secretsDirPath -ChildPath $selectedTenant

    if (-Not (Test-Path -Path $selectedTenantPath)) {
        Write-Error "The specified tenant folder '$selectedTenant' does not exist."
        throw "Invalid tenant folder"
    }

    # Define paths for the secrets.json and PFX files
    $secretsJsonPath = Join-Path -Path $selectedTenantPath -ChildPath "secrets.json"
    $pfxFiles = Get-ChildItem -Path $selectedTenantPath -Filter *.pfx

    # Check if secrets.json exists
    if (-Not (Test-Path -Path $secretsJsonPath)) {
        Write-Error "secrets.json file not found in '$selectedTenantPath'."
        throw "secrets.json file not found"
    }

    # Load the secrets from the JSON file
    $secrets = Get-Content -Path $secretsJsonPath -Raw | ConvertFrom-Json

    # Check if a PFX file exists
    if ($pfxFiles.Count -eq 0) {
        Write-Error "No PFX file found in the '$selectedTenantPath' directory."
        throw "No PFX file found"
    }
    elseif ($pfxFiles.Count -gt 1) {
        Write-Error "Multiple PFX files found in the '$selectedTenantPath' directory. Please ensure there is only one PFX file."
        throw "Multiple PFX files found"
    }

    # Use the first (and presumably only) PFX file found
    $certPath = $pfxFiles[0].FullName

    Write-EnhancedLog -Message "PFX file found: $certPath" -Level 'INFO'

    # Assign values from JSON to variables
    $tenantId = $secrets.TenantId
    $clientId = $secrets.ClientId
    $CertPassword = $secrets.CertPassword


    #endregion LOADING SECRETS FOR GRAPH



    ################################################################################################################################
    ################################################ START GRAPH CONNECTING ########################################################
    ################################################################################################################################
    # Define the splat for Connect-GraphWithCert
    $graphParams = @{
        tenantId        = $tenantId
        clientId        = $clientId
        certPath        = $certPath
        certPassword    = $certPassword
        ConnectToIntune = $true
        ConnectToTeams  = $false
    }

    # Connect to Microsoft Graph, Intune, and Teams
    $accessToken = Connect-GraphWithCert @graphParams

    Log-Params -Params @{accessToken = $accessToken }

    Get-TenantDetails
    #################################################################################################################################
    ################################################# END Connecting to Graph #######################################################
    #################################################################################################################################
 
    ####################################################################################
    #   GO!
    ####################################################################################

    <#
.SYNOPSIS
Creates multiple notification message templates and sends a series of notification messages.

.DESCRIPTION
This function creates a series of notification message templates on Microsoft Graph and then sends localized notification messages based on those templates. It generates notifications for immediate alert and additional alerts set at 7, 14, 21, and 28 days intervals.

.PARAMETER Subject
The subject of the notification message.

.PARAMETER MessageBase
The base message to be customized for each notification.

.EXAMPLE
Send-NotificationMessages -Subject "Compliance Warning" -MessageBase "Your device is showing as non-compliant."
#>

    function Validate-Parameters {
        param (
            [string]$SubjectBase,
            [string]$DisplayNameBase
        )
        if ($SubjectBase.Length -gt 76) {
            Write-Host "Error: The subject base exceeds the maximum length of 76 characters." -ForegroundColor Red
            return $false
        }
        if ($DisplayNameBase.Length -gt 50) {
            Write-Host "Error: The display name base exceeds the maximum length of 50 characters." -ForegroundColor Red
            return $false
        }
        return $true
    }


    function Construct-DisplayName {
        param (
            [int]$Index,
            [string]$ScheduleKey,
            [string]$DisplayNameBase
        )
        $displayIndex = "{0:D3}" -f ($Index + 1) # Formatting index to 3 digits
        return "$displayIndex - $ScheduleKey - $DisplayNameBase"
    }


    function Create-Notification {
        param (
            [string]$DisplayName,
            [string]$Uri
        )
        $createNotificationJson = @"
{
    "brandingOptions": "includeCompanyLogo,includeCompanyName,includeContactInformation,includeCompanyPortalLink",
    "displayName": "$DisplayName",
    "roleScopeTagIds": ["0"]
}
"@
        Write-Host "Creating Notification for $DisplayName"
        $createNotification = Invoke-MgGraphRequest -Uri $Uri -Body $createNotificationJson -Method Post -ContentType "application/json" -OutputType PSObject
        Write-Host "Notification Created for $DisplayName"
        return $createNotification.id
    }



    function Create-NotificationMessage {
        param (
            [string]$Message,
            [string]$Subject,
            [string]$NotificationId,
            [string]$Uri,
            [string]$NotificationDisplayName
        )
        $createNotificationMessageJson = @"
{
    "isDefault": true,
    "locale": "en-us",
    "messageTemplate": "$Message",
    "subject": "$Subject"
}
"@
        Write-Host "Creating child Notification Message for parent notification $NotificationDisplayName with notification ID $NotificationId"
        Invoke-MgGraphRequest -Uri "$Uri/$NotificationId/localizedNotificationMessages" -Body $createNotificationMessageJson -Method Post -ContentType "application/json" -OutputType PSObject
        Write-Host "Child Notification Message Created for $NotificationDisplayName with notification ID $NotificationId"
    }





    function Send-NotificationMessages {
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory = $true)]
            [string]$SubjectBase,
            [Parameter(Mandatory = $true)]
            [string]$MessageBase,
            [Parameter(Mandatory = $true)]
            [string]$DisplayNameBase
        )

        # Define schedules using an ordered dictionary to maintain order
        $schedules = [ordered]@{
            "Immediately" = 0
            "7 days"      = 7
            "14 days"     = 14
            "21 days"     = 21
            "28 days"     = 28
        }

        $createNotificationUrl = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates"

        $index = 0
        foreach ($scheduleName in $schedules.Keys) {
            $days = $schedules[$scheduleName]
            $daysUntilBlocked = 30 - $days

            $displayName = Construct-DisplayName -Index $index -ScheduleKey $scheduleName -DisplayNameBase $DisplayNameBase

            if ($displayName.Length -gt 50) {
                Write-Host "Error: The display name '$displayName' exceeds the maximum length of 50 characters." -ForegroundColor Red
                continue
            }

            $dynamicMessageIntro = "Please note, this is Alert Number $(($index + 1)). Schedule: $scheduleName."
            $dynamicMessagePart = if ($daysUntilBlocked -eq 30) { "Your access will be blocked in 30 days." } else { "Your access will be blocked in $daysUntilBlocked days." }
            $message = "$dynamicMessageIntro $dynamicMessagePart $MessageBase"
            $subject = $SubjectBase

            $notificationId = Create-Notification -DisplayName $displayName -Uri $createNotificationUrl
            if (-not [string]::IsNullOrWhiteSpace($notificationId)) {
                Create-NotificationMessage -Message $message -Subject $subject -NotificationId $notificationId -Uri $createNotificationUrl -NotificationDisplayName $displayName
            }
            else {
                Write-Host "Failed to create notification for $displayName" -ForegroundColor Red
            }

            $index++
        }
    }



    #First, load secrets and create a credential object:
    # $secrets = Get-Secrets
    # $credential = New-ClientSecretCredential -ClientId $secrets.clientId -ClientSecret $secrets.ClientSecret


    # Connect to Microsoft Graph:
    # Connect-Graph -TenantId $secrets.tenantID -Credential $credential

    # $MessageBaseBody = "\r\n\r\n\r\nDear {{UserName}},\r\n\r\n\r\nYour device {{DeviceName}} (ID: {{DeviceId}}, OS: {{OSAndVersion}}) is not in compliance with our security standards due to FortiClient EMS issues. To ensure continued secure access to corporate resources, please address the following promptly:\r\n\r\n\r\n1.\tFortiClient EMS Not Installed: If your device lacks FortiClient EMS, it\u0027s crucial for security compliance. Install the latest version (v7.2.3 or later) by following the guide at https://bellwoodscentres.sharepoint.com/:b:/s/intunenoncompliancenotifications/EbX4nWCh98lBuOK6H1QyXogBImBOtVM5fj7bCsK2DFcbHQ?e=LjgCfG\r\n\r\n\r\n2.\tOutdated FortiClient EMS Version: If FortiClient EMS is outdated, updating to the latest version (v7.2.3 or later) is required for compliance. Detailed instructions are available at the link above.\r\n\r\n\r\nImportant Steps:\r\n•\tVerify your FortiClient EMS installation and ensure it\u0027s the latest version.\r\n•\tIf issues persist or you need help with the installation/update process, IT support is here to assist.\r\n\r\n\r\nContact IT Support: Email support@novanetworks.com or call 1-844-802-0903 for any assistance or if you\u0027ve followed the steps but still receive this notice.\r\n\r\n\r\nPlease resolve this issue urgently to prevent any disruption in accessing corporate resources. Your cooperation is highly appreciated.\r\n\r\n\r\nBest regards, \r\nNova Networks IT\r\n"


    # # Define the hashtable for splatting
    # $params = @{
    #     SubjectBase = "Immediate Action Required: Compliance Issue on Your Device {{DeviceName}}"
    #     # MessageBase = "This is my MessageBase param value"
    #     MessageBase = $MessageBaseBody
    #     DisplayNameBase = "FortiClient EMS v7.2.3" # Assuming 'Alert' is the base for your display names
    # }

    # # Call the function using splatting
    # Send-NotificationMessages @params



































    # $MessageBaseBody = "\r\n\r\n\r\nDear {{UserName}},\r\n\r\nYour device {{DeviceName}} (ID: {{DeviceId}}, OS: {{OSAndVersion}}) doesn\u0027t meet our security due to Bitlocker issues. To secure our network and maintain access to resources, please address the following:\r\n\r\n1.\tBitlocker Not Enabled: Check if Bitlocker is active by going to Control Panel \u003e System and Security \u003e Bitlocker Drive Encryption. If it\u0027s off and you lack admin rights, contact IT for help.\r\n2.\tBitlocker Issues: If Bitlocker is on but problems persist, check the encryption status. Issues like Encryption Paused need IT\u0027s intervention.\r\n\r\nActions Needed:\r\n•\tIf unable to enable Bitlocker or if errors arise during checks, contact IT.\r\n•\tIf Bitlocker is enabled but notifications continue, seek IT assistance.\r\n\r\nContact IT at support@novanetworks.com or 1-844-802-0903 for support.\r\n\r\nAddress this urgently to avoid access disruption. Thanks for your cooperation.\r\n\r\nRegards,\r\nNova Networks IT"


    # # Define the hashtable for splatting
    # $params = @{
    #     SubjectBase = "Immediate Action Required: Compliance Issue on Your Device {{DeviceName}}"
    #     # MessageBase = "This is my MessageBase param value"
    #     MessageBase = $MessageBaseBody
    #     DisplayNameBase = "Bitlocker Disk Encryption" # Assuming 'Alert' is the base for your display names
    # }

    # # Call the function using splatting
    # Send-NotificationMessages @params
















    $MessageBaseBody = "\r\n\r\n\r\nDear {{UserName}},\r\n\r\nOur records indicate that your device, {{DeviceName}} (Device ID: {{DeviceId}}, OS: {{OSAndVersion}}), is currently not in compliance with our organization's security requirements because it is not running the required version of Windows 11.\r\n\r\nTo ensure secure access to corporate resources, please review the following and take the necessary actions:\r\n\r\n1. Minimum Required Version: Your device must be running Windows 11 version 23H2 (OS Build 10.0.22631.4169) or later to comply with our security standards.\r\n\r\n2. Update Windows 11: If your device is running an older version, please update to the required version of Windows 11 as soon as possible. You can check for updates by navigating to Settings > Windows Update and selecting Check for updates. Ensure that your device installs all available updates to meet the compliance requirements.\r\n\r\nPlease address this compliance issue promptly to avoid any disruption to your access to corporate resources. If you have updated your device and still receive this notification, or if you require further assistance, please contact our IT support team.\r\n\r\nContact Details: Please reach out to our IT support team for assistance by emailing support@novanetworks.com or calling 1-844-802-0903. Providing details of your device and the issue will facilitate a quicker resolution.\r\n\r\nThank you for your immediate attention to this matter.\r\n\r\nBest regards,\r\nNova Networks IT"


    # Define the hashtable for splatting
    $params = @{
        # SubjectBase     = "Immediate Action Required: Compliance Issue on Your Device {{DeviceName}}"
        SubjectBase     = "Immediate Action Required: Windows Updates Compliance for {{DeviceName}}"
        # MessageBase = "This is my MessageBase param value"
        MessageBase     = $MessageBaseBody
        DisplayNameBase = "WinUpdates - OS Version" # Assuming 'Alert' is the base for your display names
    }

    # Call the function using splatting
    Send-NotificationMessages @params

 
    #endregion Script Logic
}
catch {
    Write-EnhancedLog -Message "An error occurred during script execution: $_" -Level 'ERROR'
    if ($transcriptPath) {
        Stop-Transcript
        Write-EnhancedLog -Message "Transcript stopped." -ForegroundColor Cyan
        # Stop logging in the finally block

    }
    else {
        Write-EnhancedLog -Message "Transcript was not started due to an earlier error." -ForegroundColor Red
    }

    # Stop PSF Logging

    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in the finally block by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false

    Handle-Error -ErrorRecord $_
    throw $_  # Re-throw the error after logging it
} 
finally {
    # Ensure that the transcript is stopped even if an error occurs
    if ($transcriptPath) {
        Stop-Transcript
        Write-EnhancedLog -Message "Transcript stopped." -ForegroundColor Cyan
        # Stop logging in the finally block

    }
    else {
        Write-EnhancedLog -Message "Transcript was not started due to an earlier error." -ForegroundColor Red
    }
    # 

    
    # Ensure the log is written before proceeding
    Wait-PSFMessage

    # Stop logging in the finally block by disabling the provider
    Set-PSFLoggingProvider -Name 'logfile' -InstanceName $instanceName -Enabled $false

}