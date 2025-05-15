function Get-IntuneToken {
    <#
    .SYNOPSIS
        Retrieves a saved Intune authentication token.
        
    .DESCRIPTION
        This function retrieves a previously saved Intune authentication token.
        It validates the token and ensures it has not expired before returning it.
        
    .PARAMETER ProfileName
        The profile name associated with the saved token. Default is "Default".
        
    .EXAMPLE
        Get-IntuneToken
        
        Retrieves the token saved under the default profile.
        
    .EXAMPLE
        Get-IntuneToken -ProfileName "WorkAccount"
        
        Retrieves the token saved under the "WorkAccount" profile.
        
    .NOTES
        If the token is expired or invalid, the function will return $null.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ProfileName = "Default"
    )
    
    try {
        # Get token storage path
        $storagePath = Get-IntuneTokenStoragePath -ProfileName $ProfileName
        
        # Check all possible file naming patterns
        $possibleTokenFiles = @(
            # Current naming pattern (with ProfileName prefix)
            (Join-Path -Path $storagePath -ChildPath "$ProfileName.token.xml"),
            # Legacy naming pattern (without prefix)
            (Join-Path -Path $storagePath -ChildPath "token.xml")
        )
        
        Write-Verbose "Looking for token files at:"
        $possibleTokenFiles | ForEach-Object { Write-Verbose "- $_" }
        
        # Try each filename pattern
        $tokenFilePath = $null
        foreach ($path in $possibleTokenFiles) {
            if (Test-Path -Path $path) {
                $tokenFilePath = $path
                Write-Verbose "Found token at: $tokenFilePath"
                break
            }
        }
        
        # If no token file found, return null
        if (-not $tokenFilePath) {
            Write-Verbose "No token file found in any of the expected locations"
            return $null
        }
        
        try {
            # Verify we have read access to the file
            $fileInfo = Get-Item -Path $tokenFilePath -ErrorAction Stop
            Write-Verbose "Token file found: $tokenFilePath (Size: $($fileInfo.Length) bytes)"
        }
        catch {
            Write-Warning "File exists but cannot be accessed: $tokenFilePath - $($_.Exception.Message)"
            return $null
        }
        
        # Read and decrypt the token
        try {
            Write-Verbose "Reading token from file: $tokenFilePath"
            $encryptedToken = Get-Content -Path $tokenFilePath -Raw -ErrorAction Stop
            
            if ([string]::IsNullOrWhiteSpace($encryptedToken)) {
                Write-Warning "Token file exists but is empty: $tokenFilePath"
                return $null
            }
            
            Write-Verbose "Successfully read encrypted token from file (Length: $(($encryptedToken | Measure-Object -Character).Characters) characters)"
            
            Write-Verbose "Decrypting token..."
            $token = Unprotect-IntuneString -EncryptedString $encryptedToken
            
            if ([string]::IsNullOrWhiteSpace($token)) {
                Write-Warning "Token decryption resulted in empty string"
                return $null
            }
            
            Write-Verbose "Successfully decrypted token (Length: $(($token | Measure-Object -Character).Characters) characters)"
            
            # Validate the token
            Write-Verbose "Validating token..."
            $isValid = Test-IntuneToken -Token $token
            
            if ($isValid) {
                Write-Verbose "Successfully retrieved and validated token for profile '$ProfileName'."
                return $token
            } else {
                Write-Warning "Token for profile '$ProfileName' failed validation. It may be expired or invalid."
                return $null
            }
        } catch {
            Write-Error "Error retrieving or decrypting token for profile '$ProfileName': $_"
            return $null
        }
    } catch {
        Write-Error "Error in Get-IntuneToken: $_"
        return $null
    }
} 