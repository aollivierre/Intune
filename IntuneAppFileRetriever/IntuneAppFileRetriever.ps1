function Connect-To-GraphAPI {
    param (
        [Parameter(Mandatory=$false)]
        [string[]]$Scopes = @("DeviceManagementApps.Read.All", "DeviceManagementApps.ReadWrite.All")
    )

    # Authenticate using Connect-MgGraph
    Connect-MgGraph -Scopes $Scopes
}

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





function Get-IntuneAppFileURL {
    param (
        [Parameter(Mandatory=$true)]
        [string]$AppId,
        
        [Parameter(Mandatory=$true)]
        [string]$contentVersionId
    )

    $graphUrl = "https://graph.microsoft.com/v1.0"
    $endPoint = "/deviceAppManagement/mobileApps/$AppId/microsoft.graph.win32LobApp/contentVersions/$contentVersionId/files"
    
    # Use the Invoke-MgGraphRequest cmdlet from the Microsoft.Graph module to make the request
    $response = Invoke-MgGraphRequest -Method GET -Uri "$graphUrl$endPoint" -Verbose

    $response | Format-List

    # Assuming only one file is attached to the app, retrieve the azureStorageUri.
    $fileURL = $response.value[0].azureStorageUri

    # Return the URL
    return $fileURL
}



function Download-IntuneFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$contentLocation,

        [Parameter(Mandatory=$false)]
        [string]$destinationPath = ".\downloaded_file.zip"
    )

    # Use Invoke-WebRequest to download the file
    Invoke-WebRequest -Uri $contentLocation -OutFile $destinationPath

    Write-Output "File downloaded to $destinationPath"
}


# Connect-To-GraphAPI
# $metadata = Get-IntuneAppMetadata -AppId "98ee768c-9e80-472c-b60d-fda9b9e83742"
# $metadata | clip.exe
# $contentLocation = $metadata.contentLocation
# Download-IntuneFile -contentLocation $contentLocation -destinationPath "C:\Code\CB\Intune\IntuneAppFileRetriever\CNA\WSUS\.zip"



# $fileURL = Get-IntuneAppFileURL -AppId "98ee768c-9e80-472c-b60d-fda9b9e83742" -contentVersionId "1"
# $fileURL

$fileURL = Get-IntuneAppFileURL -AppId "98ee768c-9e80-472c-b60d-fda9b9e83742" -contentVersionId "1"
$fileURL
# Write-Host "File URL: $fileURL"



# Get-IntuneAppFileURL -AppId "98ee768c-9e80-472c-b60d-fda9b9e83742" -contentVersionId "1"


# Assuming $response holds the returned data
# $azureStorageUri = $response.value[0].azureStorageUri

# Download-IntuneFile -contentLocation $fileURL -destinationPath "C:\Code\CB\Intune\IntuneAppFileRetriever\CNA\WSUS\1.intunewin"



