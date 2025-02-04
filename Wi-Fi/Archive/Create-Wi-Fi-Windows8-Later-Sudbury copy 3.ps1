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
$name = "Wi-Fi-Sudbury"
$description = "Wi-Fi-Sudbury configuration profile"
$groupId = "76c595c4-c54d-40a5-a1c7-2c743f3f6621" # Update this with the actual target group ID

## Set URL for creating profile
$createProfileUrl = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"

## Read the XML file for Wi-Fi-Sudbury and convert it to Base64
$xmlPath = Join-Path -Path $PSScriptRoot -ChildPath "Wi-Fi-Sudbury.xml"
$base64Payload = [Convert]::ToBase64String([IO.File]::ReadAllBytes($xmlPath))

## Construct JSON for profile creation with the necessary attributes
$jsonForProfileCreation = @{
    "@odata.type" = "#microsoft.graph.windowsWifiImportConfiguration"
    "displayName" = $name
    "description" = $description
    "version" = 1
    "payloadFileName" = "Wi-Fi-Sudbury.xml"
    "profileName" = $name
    "payload" = $base64Payload
} | ConvertTo-Json -Depth 10

## Create Profile
Write-Host "Creating Windows Wi-Fi Profile for Wi-Fi-Sudbury"
$profileCreationResponse = Invoke-MgGraphRequest -Method POST -Uri $createProfileUrl -Body $jsonForProfileCreation -ContentType "application/json"
Write-Host "Profile created successfully"

## Extract ID of the created profile to use in assignment
$profileId = $profileCreationResponse.id
if (-not $profileId) {
    Write-Host "Failed to retrieve profile ID. Exiting..."
    exit
}
Write-Host "Profile ID: $profileId"

## Prepare URL for profile assignment
$assignProfileUrl = "$createProfileUrl/$profileId/assign"

## Construct JSON for profile assignment
$jsonForProfileAssignment = @{
    "assignments" = @(
        @{
            "target" = @{
                "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                "groupId" = $groupId
            }
        }
    )
} | ConvertTo-Json -Depth 10

## Assign Profile to Group
Write-Host "Assigning Wi-Fi-Sudbury Profile"
Invoke-MgGraphRequest -Method POST -Uri $assignProfileUrl -Body $jsonForProfileAssignment -ContentType "application/json"
Write-Host "Wi-Fi-Sudbury Profile assigned successfully"