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
function Send-NotificationMessages {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$SubjectBase,

		[Parameter(Mandatory = $true)]
		[string]$MessageBase
	)

	$schedules = @("Immediately", "7 days", "14 days", "21 days", "28 days")
	$displayNames = @("Immediately Alert Number 1", "7 Days Alert Number 2", "14 Days Alert Number 3", "21 Days Alert Number 4", "28 Days Alert Number 5 - Final")

	foreach ($index in 0..4) {
		$displayName = "$SubjectBase - $displayNames[$index]"
		$message = "Please note, this is Alert Number $(($index + 1)). Schedule: $($schedules[$index]). $MessageBase"
		$Subject = "Alert Number $(($index + 1)) - Schedule: $($schedules[$index]) - $SubjectBase"

		# Assuming all other necessary variables ($secrets, $credential, etc.) are initialized outside this function

		#Set URL for creating notification
		$createNotificationUrl = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates"

		# Populate JSON Body for notification
		$createNotificationJson = @"
{
    "brandingOptions": "includeCompanyLogo,includeCompanyName,includeContactInformation",
    "displayName": "$displayName",
    "roleScopeTagIds": [
        "0"
    ]
}
"@

		# Create Policy
		Write-Host "Creating Notification for $displayName"
		$createNotification = Invoke-MgGraphRequest -Uri $createNotificationUrl -Body $createNotificationJson -Method Post -ContentType "application/json" -OutputType PSObject
		Write-Host "Notification Created for $displayName"

		# Get Policy ID
		$createNotificationId = $createNotification.id
		Write-Host "Notification ID: $createNotificationId"

		# Populate ID into assignment URL
		$createNotificationMessageUrl = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates/$createNotificationId/localizedNotificationMessages"

		# Populate JSON Body for notification message
		$createNotificationMessageJson = @"
{
    "isDefault": true,
    "locale": "en-us",
    "messageTemplate": "$message",
    "subject": "$Subject"
}
"@

		# Create Notification Message
		Write-Host "Creating Notification Message for $displayName"
		$createNotificationMessage = Invoke-MgGraphRequest -Uri $createNotificationMessageUrl -Body $createNotificationMessageJson -Method Post -ContentType "application/json" -OutputType PSObject
		Write-Host "Notification Message Created for $displayName"
	}
}









Send-NotificationMessages -SubjectBase "NCN001 - FortiClient EMS v7.2.3 - notification" -MessageBase "Dear {{UserName}},\r\n\r\n\r\nYour device {{DeviceName}} (ID: {{DeviceId}}, OS: {{OSAndVersion}}) is not in compliance with our security standards due to FortiClient EMS issues. To ensure continued secure access to corporate resources, please address the following promptly:\r\n\r\n\r\n1.\tFortiClient EMS Not Installed: If your device lacks FortiClient EMS, it\u0027s crucial for security compliance. Install the latest version (v7.2.3 or later) by following the guide at https://bellwoodscentres.sharepoint.com/:b:/s/intunenoncompliancenotifications/EbX4nWCh98lBuOK6H1QyXogBImBOtVM5fj7bCsK2DFcbHQ?e=LjgCfG\r\n\r\n\r\n2.\tOutdated FortiClient EMS Version: If FortiClient EMS is outdated, updating to the latest version (v7.2.3 or later) is required for compliance. Detailed instructions are available at the link above.\r\n\r\n\r\nImportant Steps:\r\n•\tVerify your FortiClient EMS installation and ensure it\u0027s the latest version.\r\n•\tIf issues persist or you need help with the installation/update process, IT support is here to assist.\r\n\r\n\r\nContact IT Support: Email support@novanetworks.com or call 1-844-802-0903 for any assistance or if you\u0027ve followed the steps but still receive this notice.\r\n\r\n\r\nPlease resolve this issue urgently to prevent any disruption in accessing corporate resources. Your cooperation is highly appreciated.\r\n\r\n\r\nBest regards, \r\nNova Networks IT\r\n"






#First, load secrets and create a credential object:
$secrets = Get-Secrets
$credential = New-ClientSecretCredential -ClientId $secrets.clientId -ClientSecret $secrets.ClientSecret


# Connect to Microsoft Graph:
Connect-Graph -TenantId $secrets.tenantID -Credential $credential




# Send a notification message:
# Send-NotificationMessage -Subject "Your Subject Here" -Message "Your message here." -displayname "First Alert"
# Send-NotificationMessage -Subject "Your Subject Here" -Messagebase "Your message here."