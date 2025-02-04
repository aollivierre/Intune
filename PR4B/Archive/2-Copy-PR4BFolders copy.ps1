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

    $folders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $_.Name -match 'PR4B' -and $_.FullName -notmatch '\\Archive\\'
    }

    $mostRecentFolders = @{}

    foreach ($folder in $folders) {
        if ($folder.Name -match '^(PR4B-.+?)(v?\d+)?$') {
            $identifier = $matches[1] # Base name without version

            if (-not $mostRecentFolders.ContainsKey($identifier) -or
                $folder.CreationTime -gt $mostRecentFolders[$identifier].CreationTime) {
                $mostRecentFolders[$identifier] = $folder
            }
        }
    }

    # Instead of formatting and outputting strings, return an array of full names
    return $mostRecentFolders.Values.FullName
}

# To run the function and capture its output:
$mostRecentPR4BFolders = Get-MostRecentPR4BFolder
$mostRecentPR4BFolders
# Now, $mostRecentPR4BFolders contains the full paths of the most recent PR4B folders




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

    $mostRecentPR4BFolders = Get-MostRecentPR4BFolder

    foreach ($folderFullPath in $mostRecentPR4BFolders) {
        # Since $folderFullPath is a string, we need to extract the folder name for the destination path.
        $folderName = Split-Path -Path $folderFullPath -Leaf
        $destinationFolder = Join-Path -Path $TargetPath -ChildPath $folderName

        if (-Not (Test-Path -Path $destinationFolder)) {
            Write-Host "Copying $folderFullPath to $destinationFolder..."
            Copy-Item -Path $folderFullPath -Destination $destinationFolder -Recurse -Force
        } else {
            Write-Host "Destination already exists and will be skipped: $destinationFolder"
        }
    }
}
Copy-MostRecentPR4BFoldersToTarget