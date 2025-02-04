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

    # Retrieve all PR4B folders, excluding 'Archive' folders
    $folders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $_.Name -match '^PR4B' -and $_.FullName -notmatch '\\Archive\\'
    } | Sort-Object CreationTime -Descending

    $uniqueFolders = @{}

    foreach ($folder in $folders) {
        $baseName = $folder.Name -replace '(_v?[\d-]+)?$', ''
        if (-not $uniqueFolders.ContainsKey($baseName)) {
            $uniqueFolders[$baseName] = $folder
        }
    }

    $uniqueFolders.Values | ForEach-Object {
        "{0} - Created On: {1}" -f $_.FullName, $_.CreationTime.ToString('g')
    }
}

# To run the function, just call it:
Get-MostRecentPR4BFolder





function Validate-MostRecentPR4BFolder {
    [CmdletBinding()]
    Param (
        [string]$Path = "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer"
    )

    Write-Verbose "Starting validation..."
    if (-Not (Test-Path -Path $Path)) {
        Write-Error "Path does not exist: $Path"
        return
    }

    Write-Verbose "Retrieving folders..."
    $folders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $_.Name -match '^PR4B' -and $_.FullName -notmatch '\\Archive\\'
    }

    Write-Verbose "Processing folders..."
    $uniqueFolders = @{}

    foreach ($folder in $folders) {
        $baseName = $folder.Name -replace '(_v?[\d-]+)?$', ''
        Write-Verbose "Processing folder: $($folder.Name)"
        Write-Verbose "Derived base name: $baseName"
        
        if (-not $uniqueFolders.ContainsKey($baseName)) {
            Write-Verbose "Adding new unique folder to list: $($folder.FullName)"
            $uniqueFolders[$baseName] = $folder
        } else {
            $existingFolder = $uniqueFolders[$baseName]
            Write-Verbose "Existing folder found for $baseName $($existingFolder.FullName)"

            if ($folder.CreationTime -gt $existingFolder.CreationTime) {
                Write-Verbose "Replacing older folder with newer folder: $($folder.FullName)"
                $uniqueFolders[$baseName] = $folder
            } else {
                Write-Verbose "Retained existing folder as it is newer: $($existingFolder.FullName)"
            }
        }
    }

    Write-Verbose "Final unique folders selection:"
    $uniqueFolders.Values | ForEach-Object {
        $message = "Folder: $($_.FullName) - Created On: $($_.CreationTime.ToString('g'))"
        Write-Verbose $message
        Write-Output $message
    }

    Write-Verbose "Validation complete."
}

# To run the function with verbose output, use:
Validate-MostRecentPR4BFolder -Verbose















