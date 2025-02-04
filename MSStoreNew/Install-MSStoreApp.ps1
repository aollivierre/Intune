function Install-MSStoreApp {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppId, # Package Identifier for the Microsoft Store app
        
        [Parameter(Mandatory=$true)]
        [string]$AccessToken, # Access token for Graph API authentication
        
        [Parameter(Mandatory=$true)]
        [string]$DisplayName # Display name of the app
    )

    $GraphApiUri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps"

    $body = @{
        '@odata.type' = "#microsoft.graph.winGetApp"
        'displayName' = $DisplayName
        'packageIdentifier' = $AppId
        'installExperience' = @{
            'runAsAccount' = "user"
        }
    } | ConvertTo-Json

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
        'Content-Type' = 'application/json'
    }

    try {
        $response = Invoke-RestMethod -Uri $GraphApiUri -Method POST -Headers $headers -Body $body
        Write-Host "App installation initiated. Response: " $response
    }
    catch {
        Write-Error "Failed to initiate app installation. Error: $_"
    }
}


# #example usage
# $accessToken = "your_access_token_here"
# Install-MSStoreApp -AppId "9WZDNCRD2G0J" -AccessToken $accessToken -DisplayName "Microsoft To Do"



$accessToken = "your_access_token_here"
Install-MSStoreApp -AppId "9WZDNCRD2G0J" -AccessToken $accessToken -DisplayName "Microsoft To Do"