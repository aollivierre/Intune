function Remove-IntuneToken {
    <#
    .SYNOPSIS
        Removes saved Intune authentication tokens.
        
    .DESCRIPTION
        This function removes previously saved Intune authentication tokens 
        from the local storage, including both token files and their associated metadata.
        
    .PARAMETER ProfileName
        The profile name to remove. If not specified, all profiles are removed.
        
    .PARAMETER RemoveExpiredOnly
        If specified, only expired tokens are removed.
        
    .EXAMPLE
        Remove-IntuneToken
        
        Removes all saved tokens (with confirmation).
        
    .EXAMPLE
        Remove-IntuneToken -ProfileName "WorkAccount"
        
        Removes the token for the "WorkAccount" profile.
        
    .EXAMPLE
        Remove-IntuneToken -RemoveExpiredOnly
        
        Removes only expired tokens.
        
    .NOTES
        Be careful when using this function without specifying a profile name,
        as it will remove all saved tokens.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ProfileName,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveExpiredOnly
    )
    
    try {
        # Get the base storage path
        $basePath = Get-IntuneTokenStoragePath
        
        if (-not (Test-Path -Path $basePath)) {
            Write-Warning "Token storage directory does not exist: $basePath"
            return $false
        }
        
        # Get token files to process
        $tokenFiles = if ($ProfileName) {
            # Specific profile
            $tokenFilePath = Join-Path -Path $basePath -ChildPath "$ProfileName.token.xml"
            $metadataFilePath = Join-Path -Path $basePath -ChildPath "$ProfileName.metadata.xml"
            
            if (Test-Path $tokenFilePath) {
                [PSCustomObject]@{
                    ProfileName = $ProfileName
                    TokenPath = $tokenFilePath
                    MetadataPath = $metadataFilePath
                    IsExpired = $false
                }
            }
        } else {
            # All profiles
            $allTokenFiles = Get-ChildItem -Path $basePath -Filter "*.token.xml"
            
            foreach ($file in $allTokenFiles) {
                $profileName = $file.BaseName -replace '\.token$', ''
                $metadataPath = Join-Path -Path $basePath -ChildPath "$profileName.metadata.xml"
                $isExpired = $false
                
                # Check if the token is expired when -RemoveExpiredOnly is specified
                if ($RemoveExpiredOnly -and (Test-Path $metadataPath)) {
                    try {
                        $metadata = Import-Clixml -Path $metadataPath
                        $isExpired = ($metadata.ExpirationTime -lt (Get-Date))
                    } catch {
                        Write-Verbose "Could not read metadata for $profileName, assuming not expired: $_"
                        $isExpired = $false
                    }
                }
                
                [PSCustomObject]@{
                    ProfileName = $profileName
                    TokenPath = $file.FullName
                    MetadataPath = $metadataPath
                    IsExpired = $isExpired
                }
            }
        }
        
        # Filter out non-expired tokens if requested
        if ($RemoveExpiredOnly) {
            $tokenFiles = $tokenFiles | Where-Object { $_.IsExpired -eq $true }
            
            if ($tokenFiles.Count -eq 0) {
                Write-Host "No expired tokens found." -ForegroundColor Green
                return $false
            }
        }
        
        if ($tokenFiles.Count -eq 0) {
            if ($ProfileName) {
                Write-Warning "No token found for profile '$ProfileName'."
            } else {
                Write-Warning "No saved tokens found."
            }
            return $false
        }
        
        $removedCount = 0
        
        foreach ($tokenFile in $tokenFiles) {
            $description = "profile '$($tokenFile.ProfileName)'"
            
            if ($PSCmdlet.ShouldProcess($description, "Remove token")) {
                try {
                    # Remove token file
                    if (Test-Path $tokenFile.TokenPath) {
                        Remove-Item -Path $tokenFile.TokenPath -Force
                        Write-Verbose "Removed token file: $($tokenFile.TokenPath)"
                    }
                    
                    # Remove metadata file
                    if (Test-Path $tokenFile.MetadataPath) {
                        Remove-Item -Path $tokenFile.MetadataPath -Force
                        Write-Verbose "Removed metadata file: $($tokenFile.MetadataPath)"
                    }
                    
                    $removedCount++
                    Write-Verbose "Removed token for $description"
                } catch {
                    Write-Warning "Failed to remove token for $description`: $_"
                }
            }
        }
        
        if ($removedCount -gt 0) {
            Write-Host "Successfully removed $removedCount token(s)." -ForegroundColor Green
            return $true
        }
        
        return $false
    } catch {
        Write-Error "Error in Remove-IntuneToken: $_"
        return $false
    }
} 