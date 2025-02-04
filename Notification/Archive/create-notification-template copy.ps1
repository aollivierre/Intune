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
Creates a notification policy and sends a notification message.

.DESCRIPTION
This function creates a notification policy on Microsoft Graph and then sends a localized notification message based on that policy.

.EXAMPLE
Send-NotificationMessage -Subject "First Warning" -Message "Your device is now showing as non-compliant. Please contact IT to resolve the issue. Your access will be blocked in xx days"
#>
function Send-NotificationMessage {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$Subject,

		[Parameter(Mandatory = $true)]
		[string]$Message,


		[Parameter(Mandatory = $true)]
		[string]$displayname
	)

	# Steps to create notification and message will go here
	# This will include creating the notification policy and then sending the message
	# Use Invoke-MgGraphRequest and handle the responses and IDs appropriately





	##Set Variables
	# $subject = "First Warning"
	# $message = "Your device is now showing as non-compliant.  Please contact IT to resolve the issue.\nYour access will be blocked in xx days"
	# $displayname = "First Alert"

	##Set URL
	$createnotificationurl = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates"

	##Populate JSON Body
	$createnotificationjson = @"
{
	"brandingOptions": "includeCompanyLogo,includeCompanyName,includeContactInformation",
	"displayName": "$displayname",
	"roleScopeTagIds": [
		"0"
	]
}
"@

	##Create Policy
	write-host "Creating Notification"
	$createnotification = invoke-mggraphrequest -uri $createnotificationurl -Body $createnotificationjson -method post -contenttype "application/json" -outputtype PSObject
	write-host "Notification Created"

	##Get Policy ID
	$createnotificationid = $createnotification.id
	write-host "Notification ID: $createnotificationid"

	##Populate ID into assignment URL
	$createnotificationmessageurl = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates/$createnotificationid/localizedNotificationMessages"

	##Populate JSON Body
	$createnotificationmessagejson = @"
{
	"isDefault": true,
	"locale": "en-us",
	"messageTemplate": "$message",
	"subject": "$subject"
}
"@

	##Create Policy
	write-host "Creating Notification Message"
	$createnotificationmessage = invoke-mggraphrequest -uri $createnotificationmessageurl -Body $createnotificationmessagejson -method post -contenttype "application/json" -outputtype PSObject
	write-host "Notification Message Created"




}




#First, load secrets and create a credential object:
$secrets = Get-Secrets
$credential = New-ClientSecretCredential -ClientId $secrets.clientId -ClientSecret $secrets.ClientSecret


# Connect to Microsoft Graph:
Connect-Graph -TenantId $secrets.tenantID -Credential $credential

# Send a notification message:
Send-NotificationMessage -Subject "Your Subject Here" -Message "Your message here." -displayname "First Alert"