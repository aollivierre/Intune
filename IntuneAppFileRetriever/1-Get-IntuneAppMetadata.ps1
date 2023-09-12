# IntuneAppFileRetriever
# Function: 2/3 - Get-IntuneAppMetadata
# Function's description:

# Retrieves metadata for a specified Intune app.
# Uses the /deviceAppManagement/mobileApps/{mobileAppId} endpoint on Microsoft Graph.
# Requires an authenticated session (handled by Connect-To-GraphAPI).
# Function's code:

function Get-IntuneAppMetadata {
    param (
        [Parameter(Mandatory=$true)]
        [string]$AppId
    )

    $graphUrl = "https://graph.microsoft.com/v1.0"
    $endPoint = "/deviceAppManagement/mobileApps/$AppId"
    
    # Use the Invoke-MgGraphRequest cmdlet from the Microsoft.Graph module to make the request
    $response = Invoke-MgGraphRequest -Method GET -Uri "$graphUrl$endPoint" -Verbose

    # Return the response
    return $response
}

$AppId = "98ee768c-9e80-472c-b60d-fda9b9e83742"
Get-IntuneAppMetadata -AppId $AppId
