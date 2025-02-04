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

## Set Variables
$groupId = "76c595c4-c54d-40a5-a1c7-2c743f3f6621" # Update this with the actual target group ID

## Set URL for creating profile
$createProfileUrl = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"

## Read the XML file for Wi-Fi-Sudbury and convert it to Base64
$xmlPath = Join-Path -Path $PSScriptRoot -ChildPath "Wi-Fi-Sudbury.xml"
$base64Payload = [Convert]::ToBase64String([IO.File]::ReadAllBytes($xmlPath))

## Load JSON configuration for profile creation from config.json
# $configJsonPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$configJsonPath = Join-Path -Path $PSScriptRoot -ChildPath "Wi-Fi-Walton.json"
$configJson = Get-Content -Path $configJsonPath -Raw | ConvertFrom-Json

# Update the payload in the configuration with the base64 of the XML
$configJson.payload = $base64Payload

# Convert back to JSON string for the request body
$jsonForProfileCreation = $configJson | ConvertTo-Json -Depth 10

## Create Profile
Write-Host "Creating Windows Wi-Fi Profile for Wi-Fi-Sudbury"
$profileCreationResponse = Invoke-MgGraphRequest -Method POST -Uri $createProfileUrl -Body $jsonForProfileCreation -ContentType "application/json"
Write-Host "Profile created successfully"

## Check if a profile ID was retrieved
if (-not $profileCreationResponse.id) {
    Write-Host "Failed to create profile. Exiting script."
    exit
}

## Extract ID of the created profile to use in assignment
$profileId = $profileCreationResponse.id
Write-Host "Profile ID: $profileId"

## Prepare URL for profile assignment
$assignProfileUrl = "$createProfileUrl/$profileId/assign"

## Load JSON configuration for profile assignment from config.json (if different, otherwise adjust as needed)
# Assuming assignment details are the same, otherwise load a different JSON file or adjust $configJson accordingly
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

## Assign Profile to Group
Write-Host "Assigning Wi-Fi-Sudbury Profile"
Invoke-MgGraphRequest -Method POST -Uri $assignProfileUrl -Body $jsonForProfileAssignment -ContentType "application/json"
Write-Host "Wi-Fi-Sudbury Profile assigned successfully"