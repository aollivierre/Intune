function Get-IntuneTokenStoragePath {
    <#
    .SYNOPSIS
        Gets the path for storing Intune authentication tokens.
        
    .DESCRIPTION
        This function returns the path where Intune authentication tokens are stored.
        It creates the directory if it doesn't exist.
        
        The token storage path follows this pattern:
        - Windows: %AppData%\IntuneRemediation\TokenStorage\{ProfileName}
        - macOS/Linux: ~/.config/IntuneRemediation/TokenStorage/{ProfileName}
        
    .PARAMETER ProfileName
        The profile name to get the path for. Default is "Default".
        
    .EXAMPLE
        Get-IntuneTokenStoragePath
        
        Returns the path for the "Default" profile.
        
    .EXAMPLE
        Get-IntuneTokenStoragePath -ProfileName "WorkAccount"
        
        Returns the path for the "WorkAccount" profile.
        
    .NOTES
        This function is part of the public API and can be used in scripts that utilize this module.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ProfileName = "Default"
    )
    
    try {
        # Use AppData\Roaming for more consistent availability
        $appDataPath = [Environment]::GetFolderPath('ApplicationData')  # This is AppData\Roaming
        
        # Construct the full path including TokenStorage and ProfileName subdirectories
        $fullPath = Join-Path -Path $appDataPath -ChildPath "IntuneRemediation\TokenStorage\$ProfileName"
        
        # Create the directory if it doesn't exist
        if (-not (Test-Path -Path $fullPath -PathType Container)) {
            $null = New-Item -Path $fullPath -ItemType Directory -Force
            Write-Verbose "Created token storage directory: $fullPath"
        }
        
        # Return the full path (not including the filename)
        return $fullPath
    }
    catch {
        Write-Error "Error determining token storage path: $_"
        # Fallback to temp directory
        $fallbackPath = Join-Path -Path $env:TEMP -ChildPath "IntuneRemediation\TokenStorage\$ProfileName"
        
        if (-not (Test-Path -Path $fallbackPath -PathType Container)) {
            $null = New-Item -Path $fallbackPath -ItemType Directory -Force
            Write-Verbose "Created fallback token storage directory: $fallbackPath"
        }
        
        Write-Warning "Using fallback storage path: $fallbackPath"
        return $fallbackPath
    }
} 