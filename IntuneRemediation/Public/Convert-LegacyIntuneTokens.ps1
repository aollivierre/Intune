function Convert-LegacyIntuneTokens {
    <#
    .SYNOPSIS
        Migrates legacy token storage format to the new format.
        
    .DESCRIPTION
        This function finds and converts tokens stored in the legacy format (token.xml) 
        to the new format (ProfileName.token.xml) with proper encryption.
        
    .PARAMETER ProfileName
        Optional profile name to convert a specific profile's token.
        If not specified, all profiles will be processed.
        
    .EXAMPLE
        Convert-LegacyIntuneTokens
        
        Finds and converts all legacy tokens to the new format.
        
    .EXAMPLE
        Convert-LegacyIntuneTokens -ProfileName "Default"
        
        Converts only the "Default" profile's token to the new format.
        
    .NOTES
        This function is intended to help with the transition to the new token format.
        Legacy tokens use Export-Clixml for storage, while new tokens use Protect-IntuneString.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ProfileName
    )
    
    try {
        # Get the base token storage path
        $appDataPath = [Environment]::GetFolderPath('ApplicationData')
        $baseStoragePath = Join-Path -Path $appDataPath -ChildPath "IntuneRemediation\TokenStorage"
        
        if (-not (Test-Path -Path $baseStoragePath)) {
            Write-Host "No token storage directory found. Nothing to convert." -ForegroundColor Yellow
            return
        }
        
        # If profile is specified, only check that profile
        if ($ProfileName) {
            $profilePaths = @(Join-Path -Path $baseStoragePath -ChildPath $ProfileName)
        } else {
            # Get all profile directories
            $profilePaths = Get-ChildItem -Path $baseStoragePath -Directory | Select-Object -ExpandProperty FullName
        }
        
        $convertedCount = 0
        $skippedCount = 0
        $errorCount = 0
        
        foreach ($profilePath in $profilePaths) {
            if (-not (Test-Path -Path $profilePath)) {
                Write-Warning "Profile path not found: $profilePath"
                continue
            }
            
            $currentProfile = Split-Path -Path $profilePath -Leaf
            $legacyTokenPath = Join-Path -Path $profilePath -ChildPath "token.xml"
            
            if (Test-Path -Path $legacyTokenPath) {
                Write-Host "Found legacy token for profile '$currentProfile'" -ForegroundColor Yellow
                
                try {
                    # Load the legacy token
                    $secureToken = Import-Clixml -Path $legacyTokenPath
                    $tokenValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                    )
                    
                    # Validate the token
                    $isValid = Test-IntuneToken -Token $tokenValue
                    
                    if ($isValid) {
                        # Save in new format
                        $result = Save-IntuneToken -Token $tokenValue -ProfileName $currentProfile
                        
                        if ($result) {
                            Write-Host "  Successfully converted token for profile '$currentProfile'" -ForegroundColor Green
                            
                            # Rename the old file to keep as backup
                            $backupPath = Join-Path -Path $profilePath -ChildPath "token.xml.old"
                            Rename-Item -Path $legacyTokenPath -NewName "token.xml.old" -Force
                            Write-Host "  Legacy token backed up to: $backupPath" -ForegroundColor Cyan
                            
                            $convertedCount++
                        } else {
                            Write-Warning "  Failed to save converted token for profile '$currentProfile'"
                            $errorCount++
                        }
                    } else {
                        Write-Warning "  Legacy token for profile '$currentProfile' is invalid or expired. Skipping."
                        $skippedCount++
                    }
                } catch {
                    Write-Error "  Error processing legacy token for profile '$currentProfile': $_"
                    $errorCount++
                }
            } else {
                Write-Verbose "No legacy token found for profile '$currentProfile'"
            }
        }
        
        # Summary
        Write-Host "`nToken Conversion Summary:" -ForegroundColor Cyan
        Write-Host "- Converted: $convertedCount" -ForegroundColor Green
        Write-Host "- Skipped (invalid/expired): $skippedCount" -ForegroundColor Yellow
        Write-Host "- Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
    } catch {
        Write-Error "Error in Convert-LegacyIntuneTokens: $_"
    }
} 