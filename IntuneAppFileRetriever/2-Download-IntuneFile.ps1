# IntuneAppFileRetriever
# Function: 3/3 - Download-IntuneFile
# Function's description:

# Downloads a specified Intune app file based on its contentLocation.
# Saves the file to a specified path or by default to the current working directory.
# Requires the content location URL which is typically retrieved from Get-IntuneAppMetadata.
# Function's code:

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

Download-IntuneFile -contentLocation $contentLocation