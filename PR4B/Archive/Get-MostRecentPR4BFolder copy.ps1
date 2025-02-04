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
    } | Sort-Object CreationTime

    $processedFolders = @{}

    foreach ($folder in $folders) {
        # Simplify the logic: directly use folder names to group, relying on sorting by creation time
        $identifier = $folder.Name -replace '(_v?[\d-]+)?$', '' -replace '(-v?[\d-]+)?$', ''

        if (-not $processedFolders.ContainsKey($identifier)) {
            $processedFolders.Add($identifier, @($folder))
        } else {
            $existingFolder = $processedFolders[$identifier][0]
            if ($folder.CreationTime -gt $existingFolder.CreationTime) {
                $processedFolders[$identifier] = @($folder)
            }
        }
    }

    # Output the most recent folders for each unique identifier
    $processedFolders.Values | ForEach-Object {
        $folder = $_[0] # Since folders are wrapped in arrays
        "{0} - Created On: {1}" -f $folder.FullName, $folder.CreationTime.ToString('g')
    }
}

# To run the function, just call it:
Get-MostRecentPR4BFolder






function Validate-MostRecentPR4BFolder {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Verbose "Starting validation for path: $Path"

    if (-Not (Test-Path -Path $Path)) {
        Write-Error "Path does not exist: $Path"
        return
    }

    $folders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $_.Name -match 'PR4B' -and $_.FullName -notmatch '\\Archive\\'
    } | Sort-Object CreationTime

    $uniqueFolders = @{}

    foreach ($folder in $folders) {
        # Extracting the base name by removing known versioning patterns and suffixes
        $baseName = $folder.Name -replace '(v\d+.*|\d+)$', ''
        Write-Verbose "Processing folder: $($folder.Name) with base name: $baseName"

        # Determining if this base name has already been encountered
        if (-not $uniqueFolders.ContainsKey($baseName)) {
            $uniqueFolders.Add($baseName, $folder)
            Write-Verbose "Added to unique list: $($folder.FullName)"
        } else {
            # Compare the current folder's creation time to the stored folder's creation time
            $existingFolder = $uniqueFolders[$baseName]
            if ($folder.CreationTime -gt $existingFolder.CreationTime) {
                $uniqueFolders[$baseName] = $folder
                Write-Verbose "Updated unique list with newer folder: $($folder.FullName)"
            }
        }
    }

    # Output the most recent folders for each unique base name
    $uniqueFolders.Values | ForEach-Object {
        $output = "$($_.FullName) - Created On: $($_.CreationTime.ToString('g'))"
        Write-Output $output
        Write-Verbose $output
    }

    Write-Verbose "Validation complete."
}

# Example usage with verbose logging:
# Validate-MostRecentPR4BFolder -Path "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer" -Verbose















