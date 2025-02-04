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







<#
.SYNOPSIS
    Copies all folders and their descendant files from a specified source path to a target path, focusing on folders that contain 'PR4B' in their name.

.DESCRIPTION
    This function searches for folders matching the 'PR4B' pattern at the specified source path (including subdirectories), then copies these folders and all of their contents (files and subfolders) to the designated target path. It's designed to help streamline the process of relocating specific project folders to a new location.

.PARAMETER SourcePath
    The path where the function will search for 'PR4B' folders to copy. It includes all subdirectories in the search.

.PARAMETER TargetPath
    The base target path where the 'PR4B' folders and their contents will be copied. The function maintains the original folder structure within this target path.

.EXAMPLE
    Copy-PR4BFolders -SourcePath "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer" -TargetPath "C:\Code\CB\AppGallery\Intune-Win32-Deployer\PR4B"

    This example demonstrates how to use the Copy-PR4BFolders function to copy all 'PR4B' folders from the specified source path to the specified target path, maintaining their original folder structure.
#>

function Copy-MostRecentPR4BFoldersToTarget {
    Param (
        [string]$TargetPath = "C:\Code\CB\AppGallery\Intune-Win32-Deployer\PR4B"
    )

    $mostRecentFolders = Get-MostRecentPR4BFolder

    foreach ($folder in $mostRecentFolders) {
        if ($null -eq $folder.FullName) {
            Write-Warning "Skipping a folder because its FullName property is null."
            continue
        }

        $destinationFolder = Join-Path -Path $TargetPath -ChildPath $folder.Name
        if (-Not (Test-Path -Path $destinationFolder)) {
            Write-Host "Copying $($folder.FullName) to $destinationFolder..."
            Copy-Item -Path $folder.FullName -Destination $destinationFolder -Recurse -Force
        } else {
            Write-Host "Destination already exists and will be skipped: $destinationFolder"
        }
    }
}
Copy-MostRecentPR4BFoldersToTarget
