<#
.SYNOPSIS
Loads secrets from a JSON file.

.DESCRIPTION
This function reads a JSON file containing secrets and returns an object with these secrets.

.EXAMPLE
$secrets = Get-Secrets

.NOTES
Assumes the JSON file is named "secrets.json" and is located in the same directory as the script.
#>
function Get-Secrets {
	[CmdletBinding()]
	Param ()
    
	$secretsPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"
	$secrets = Get-Content -Path $secretsPath -Raw | ConvertFrom-Json
	return $secrets
}






<#
.SYNOPSIS
Creates a PSCredential object for authentication.

.DESCRIPTION
This function creates a PSCredential object using a client ID and a client secret.

.PARAMETER ClientId
The client ID to be used for authentication.

.PARAMETER ClientSecret
The client secret to be used for authentication.

.EXAMPLE
$credential = New-ClientSecretCredential -ClientId $clientId -ClientSecret $clientSecret
#>
function New-ClientSecretCredential {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$ClientId,

		[Parameter(Mandatory = $true)]
		[string]$ClientSecret
	)
    
	$secureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
	$clientSecretCredential = New-Object System.Management.Automation.PSCredential ($ClientId, $secureClientSecret)
	return $clientSecretCredential
}






<#
.SYNOPSIS
Connects to Microsoft Graph using a credential object.

.DESCRIPTION
This function establishes a connection to Microsoft Graph using the provided tenant ID and credential object.

.PARAMETER TenantId
The tenant ID for the Microsoft Graph connection.

.PARAMETER Credential
The PSCredential object containing the client ID and client secret.

.EXAMPLE
Connect-Graph -TenantId $tenantId -Credential $credential
#>
function Connect-Graph {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$TenantId,

		[Parameter(Mandatory = $true)]
		[PSCredential]$Credential
	)
    
	Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential
}


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
        "7 days" = 7
        "14 days" = 14
        "21 days" = 21
        "28 days" = 28
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
        } else {
            Write-Host "Failed to create notification for $displayName" -ForegroundColor Red
        }

        $index++
    }
}



#First, load secrets and create a credential object:
$secrets = Get-Secrets
$credential = New-ClientSecretCredential -ClientId $secrets.clientId -ClientSecret $secrets.ClientSecret


# Connect to Microsoft Graph:
Connect-Graph -TenantId $secrets.tenantID -Credential $credential

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
















$MessageBaseBody = "\r\n\r\n\r\nDear {{UserName}},\r\n\r\nWe have noticed a critical issue with your device, {{DeviceName}} (Device ID: {{DeviceId}}, OS: {{OSAndVersion}}), regarding its security posture. It is either not onboarded into Microsoft Defender for Endpoint or has been assigned a risk score of High. This situation does not align with our organization\u0027s security standards and requires immediate attention.\r\n\r\nImmediate Action Required:\r\n\r\nBoth scenarios—lack of onboarding and a high-risk score—pose significant security risks and necessitate urgent action. However, due to potential restrictions or complexities in resolving these issues, we ask that you directly contact our IT support team for assistance.\r\n\r\nContact IT Support for Resolution:\r\n•\tNot Onboarded: If Microsoft Defender for Endpoint is not active on your device, IT support will guide you through the onboarding process to ensure your device is monitored and protected against threats.\r\n•\tHigh Risk Score: If your device has a high-risk score, it indicates serious vulnerabilities or threats have been detected. Our IT support team will assist in taking appropriate actions to mitigate these risks and secure your device.\r\nContact Details: Please reach out to our IT support team as soon as possible by emailing support@novanetworks.com or calling 1-844-802-0903. Providing details of your device and the issue will facilitate a quicker resolution.\r\n\r\nIt\u0027s crucial to address this matter promptly to maintain your access to corporate resources and ensure the security of our network. Your cooperation and immediate action are greatly appreciated.\r\n\r\nThank you for your attention to this important security matter.\r\n\r\nBest regards, \r\nNova Networks IT"


# Define the hashtable for splatting
$params = @{
    SubjectBase = "Immediate Action Required: Compliance Issue on Your Device {{DeviceName}}"
    # MessageBase = "This is my MessageBase param value"
    MessageBase = $MessageBaseBody
    DisplayNameBase = "Defender for Endpoint - Risk" # Assuming 'Alert' is the base for your display names
}

# Call the function using splatting
Send-NotificationMessages @params