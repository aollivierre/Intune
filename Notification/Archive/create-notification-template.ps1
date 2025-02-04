# Assuming secrets.json is in the same directory as your script
$secretsPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"

# Load the secrets from the JSON file
$secrets = Get-Content -Path $secretsPath -Raw | ConvertFrom-Json

# Now populate the connection parameters with values from the secrets file
$connectionParams = @{
    clientId     = $secrets.clientId
    tenantID     = $secrets.tenantID
    ClientSecret = $secrets.ClientSecret
}

# Convert the Client Secret to a SecureString
$SecureClientSecret = ConvertTo-SecureString $connectionParams.ClientSecret -AsPlainText -Force

# Create a PSCredential object with the Client ID as the user and the Client Secret as the password
$ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($connectionParams.ClientId, $SecureClientSecret)

# Connect to Microsoft Graph
Connect-MgGraph -TenantId $connectionParams.TenantId -ClientSecretCredential $ClientSecretCredential






##Set Variables
$subject = "First Warning"
$message = "Your device is now showing as non-compliant.  Please contact IT to resolve the issue.\nYour access will be blocked in xx days"
$displayname = "First Alert"

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
