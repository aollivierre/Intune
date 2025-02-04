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



# Ensure you're connected to Microsoft Graph
# Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"



# Assuming secrets.json is in the same directory as your script
$xmlPath = Join-Path -Path $PSScriptRoot -ChildPath "Wi-Fi-Sudbury.xml"

# Load the secrets from the JSON file
# $secrets = Get-Content -Path $secretsPath -Raw | ConvertFrom-Json


## Set Variables
$name = "Wi-Fi-Sudbury"
$description = "Wi-Fi-Sudbury"
$groupId = "76c595c4-c54d-40a5-a1c7-2c743f3f6621" # Update this to your actual group ID

## Set URL for creating profile
$createProfileUrl = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"

## Read the XML file (Wi-Fi-Sudbury.xml) and convert it to Base64
# $xmlPath = ".\Wi-Fi-Sudbury.xml"
$base64Payload = [Convert]::ToBase64String([IO.File]::ReadAllBytes($xmlPath))

## Populate JSON for profile creation
$jsonForProfileCreation = @"
{
    "@odata.type": "#microsoft.graph.windowsWifiConfiguration",
    "displayName": "$name",
    "description": "$description",
    "payloadFileName": "Wi-Fi-Sudbury.xml",
    "profileName": "Wi-Fi-Sudbury",
    "payload": "$base64Payload"
}
"@

## Create Profile
Write-Host "Creating Windows Wi-Fi Profile for Wi-Fi-Sudbury"
$profileCreationResponse = Invoke-MgGraphRequest -Method POST -Uri $createProfileUrl -Body $jsonForProfileCreation -ContentType "application/json"
Write-Host "Profile created successfully"

## Get ID of the created profile
$profileId = $profileCreationResponse.id
Write-Host "Profile ID: $profileId"

## Populate URL for profile assignment
$assignProfileUrl = "$createProfileUrl/$profileId/assign"

## Populate JSON for profile assignment
$jsonForProfileAssignment = @"
{
    "assignments": [
        {
            "target": {
                "@odata.type": "#microsoft.graph.groupAssignmentTarget",
                "groupId": "$groupId"
            }
        }
    ]
}
"@

## Assign Profile
Write-Host "Assigning Profile to Wi-Fi-Sudbury"
Invoke-MgGraphRequest -Method POST -Uri $assignProfileUrl -Body $jsonForProfileAssignment -ContentType "application/json"
Write-Host "Profile assigned successfully"
