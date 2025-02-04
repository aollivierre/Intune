function Install-MSStoreApp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId, # Package Identifier for the Microsoft Store app
        
        [Parameter(Mandatory = $true)]
        [string]$DisplayName # Display name of the app
    )

    # Attempt to connect to Microsoft Graph
    $connection = Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"
    if (-not $connection) {
        Write-Error "Could not connect to Microsoft Graph."
        return
    }

    $GraphApiUri = "/beta/deviceAppManagement/mobileApps"

    $body = @{
        '@odata.type' = "#microsoft.graph.winGetApp"
        'displayName' = $DisplayName
        'packageIdentifier' = $AppId
        'installExperience' = @{
            'runAsAccount' = "user"
        }
    }

    try {
        $response = Invoke-MgGraphRequest -Method POST -Uri $GraphApiUri -Body ($body | ConvertTo-Json) -ContentType "application/json"
        Write-Host "App installation initiated. Response: " ($response | ConvertTo-Json)
    }
    catch {
        Write-Error "Failed to initiate app installation. Error: $_"
    }
}

# Install-MSStoreApp -AppId "9WZDNCRD2G0J" -DisplayName "Microsoft To Do"
Install-MSStoreApp -AppId "XPDLPKWG9SW2WD" -DisplayName "Adobe Creative Cloud"
