<#
.SYNOPSIS
Lists the most recent folders for each unique 'PR4B' prefix under a specified path, including subdirectories.

.DESCRIPTION
This function searches the specified directory and its subdirectories for folders starting with 'PR4B', grouping them by their unique prefix, and returns the most recent folder for each unique group based on the folder's creation date.

.EXAMPLE
Get-MostRecentPR4BFolder

This example searches for folders under the default path, including subdirectories, and lists the most recent folder for each unique 'PR4B' prefix.
#>
function Get-MostRecentPR4BFolder {
    Param (
        [string]$Path = "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer"
    )

    if (-Not (Test-Path -Path $Path)) {
        Write-Error "Path does not exist: $Path"
        return
    }

    # Get all directories that match 'PR4B', excluding any within '\Archive\'
    $folders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $_.Name -match 'PR4B' -and $_.FullName -notmatch '\\Archive\\'
    }

    $mostRecentFolders = @{}

    foreach ($folder in $folders) {
        # Attempt to extract a unique identifier assuming format is 'PR4B-[Description][vVersion]'
        if ($folder.Name -match '^(PR4B-.+?)(v?\d+)?$') {
            $identifier = $matches[1] # Base name without version
            $version = $matches[2] # Version number

            if (-not $mostRecentFolders.ContainsKey($identifier) -or
                $folder.CreationTime -gt $mostRecentFolders[$identifier].CreationTime) {
                $mostRecentFolders[$identifier] = $folder
            }
        }
    }

    # Output the most recent folders for each unique identifier
    $mostRecentFolders.Values | ForEach-Object {
        "{0} - Created On: {1}" -f $_.FullName, $_.CreationTime.ToString('g')
    }
}

# To run the function, just call it:
Get-MostRecentPR4BFolder
