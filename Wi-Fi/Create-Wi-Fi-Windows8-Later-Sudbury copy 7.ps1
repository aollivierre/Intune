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

$groupId = "76c595c4-c54d-40a5-a1c7-2c743f3f6621" # Update this with the actual target group ID

# Assuming you're already connected to Microsoft Graph with the necessary permissions
$createProfileUrl = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Get all XML files in the script directory
$xmlFiles = Get-ChildItem -Path $scriptPath -Filter *.xml

# Initialize suffix counter
$suffixCounter = 36

# Loop through XML files and create Wi-Fi profiles
foreach ($xmlFile in $xmlFiles) {
    # Read XML content
    [xml]$xmlContent = Get-Content -Path $xmlFile.FullName

    # Setup namespace manager for XPath
    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($xmlContent.NameTable)
    $namespaceManager.AddNamespace("ns", "http://www.microsoft.com/networking/WLAN/profile/v1")

    # Extract various elements from the XML
    $profileName = $xmlContent.SelectSingleNode("//ns:WLANProfile/ns:name", $namespaceManager).InnerText
    $ssidName = $xmlContent.SelectSingleNode("//ns:WLANProfile/ns:SSIDConfig/ns:SSID/ns:name", $namespaceManager).InnerText

    # Construct the display name and detailed description for the device configuration profile
    $configName = "CP{0:D3} - Wi-Fi - $profileName-$ssidName" -f $suffixCounter
    $creationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $description = @"
- Created by: AOllivierre (Nova Admin)
- Created on: $creationDate
- Created for: Moving away from On-prem RADIUS/NPS and cert based auth to Pre-shared key (PSK) based auth.
- Connection Name: $profileName (visible to user)
- SSID Name: $ssidName (not visible to user/Only AP Side)
- Original XML File Name: $($xmlFile.Name)
- Connection Mode: $($xmlContent.SelectSingleNode("//ns:WLANProfile/ns:connectionMode", $namespaceManager).InnerText)
- Authentication Type: $($xmlContent.SelectSingleNode("//ns:WLANProfile/ns:MSM/ns:security/ns:authEncryption/ns:authentication", $namespaceManager).InnerText)
- Encryption Type: $($xmlContent.SelectSingleNode("//ns:WLANProfile/ns:MSM/ns:security/ns:authEncryption/ns:encryption", $namespaceManager).InnerText)
- Key Type: $($xmlContent.SelectSingleNode("//ns:WLANProfile/ns:MSM/ns:security/ns:sharedKey/ns:keyType", $namespaceManager).InnerText)
- Protected: $($xmlContent.SelectSingleNode("//ns:WLANProfile/ns:MSM/ns:security/ns:sharedKey/ns:protected", $namespaceManager).InnerText)
"@

    # Convert the XML content to Base64 for the payload
    $base64Payload = [Convert]::ToBase64String([IO.File]::ReadAllBytes($xmlFile.FullName))

    # Construct the JSON payload for profile creation
    $jsonForProfileCreation = @{
        "@odata.type"     = "#microsoft.graph.windows81WifiImportConfiguration"
        "displayName"     = $configName
        "description"     = $description
        "version"         = 1
        "payloadFileName" = $xmlFile.Name
        "profileName"     = $profileName
        "payload"         = $base64Payload
    } | ConvertTo-Json -Depth 10

    # Create the Wi-Fi profile in Intune
    Write-Host "Creating Wi-Fi Profile for: $configName"
    $profileCreationResponse = Invoke-MgGraphRequest -Method POST -Uri $createProfileUrl -Body $jsonForProfileCreation -ContentType "application/json"
    
    if ($profileCreationResponse -and $profileCreationResponse.id) {
        Write-Host "Profile created successfully. Profile ID: $($profileCreationResponse.id)"
    }
    else {
        Write-Host "Failed to create profile for $configName"
    }

  



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
                    "groupId"     = $groupId
                }
            }
        )
    } | ConvertTo-Json -Depth 10

    ## Assign Profile to Group
    Write-Host "Assigning Wi-Fi-Sudbury Profile"
    Invoke-MgGraphRequest -Method POST -Uri $assignProfileUrl -Body $jsonForProfileAssignment -ContentType "application/json"
    Write-Host "Wi-Fi-Sudbury Profile assigned successfully"

    # Increment the suffix counter for the next profile
    $suffixCounter++

}