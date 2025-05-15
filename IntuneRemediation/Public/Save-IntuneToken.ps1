function Save-IntuneToken {
    <#
    .SYNOPSIS
        Securely saves an Intune authentication token for future use.
        
    .DESCRIPTION
        This function securely saves an Intune authentication token with metadata
        for future connections. The token is encrypted before storage.
        
    .PARAMETER Token
        The authentication token to save.
        
    .PARAMETER ProfileName
        The profile name to associate with the token. Default is "Default".
        
    .EXAMPLE
        Save-IntuneToken -Token $token -ProfileName "WorkAccount"
        
        Saves the token under the "WorkAccount" profile.
        
    .NOTES
        Tokens are securely encrypted before storage using DPAPI.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter(Mandatory = $false)]
        [string]$ProfileName = "Default"
    )
    
    try {
        # Validate token format
        if ([string]::IsNullOrEmpty($Token)) {
            Write-Error "Token is empty or null."
            return $null
        }
        
        if (-not $Token.StartsWith("eyJ")) {
            Write-Error "Token is not in the correct format. It should start with 'eyJ'."
            return $null
        }
        
        # Validate token is still valid
        Write-Verbose "Validating token before saving..."
        $isValid = Test-IntuneToken -Token $Token
        
        if (-not $isValid) {
            Write-Error "The token is invalid or expired and cannot be saved."
            return $null
        }
        
        # Extract metadata from token for storage
        try {
            # First chunk of token is base64url encoded
            $tokenPayload = $Token.Split(".")[1]
            
            # Add padding to avoid Base64 decoding errors
            while ($tokenPayload.Length % 4) { $tokenPayload += "=" }
            
            # Replace Base64URL characters with standard Base64
            $tokenPayload = $tokenPayload.Replace('-', '+').Replace('_', '/')
            
            # Decode the payload
            $tokenBytes = [System.Convert]::FromBase64String($tokenPayload)
            $tokenJson = [System.Text.Encoding]::UTF8.GetString($tokenBytes)
            $tokenData = ConvertFrom-Json -InputObject $tokenJson
            
            # Extract useful metadata
            $metadata = @{
                Status = "valid"
                UserPrincipalName = ""
                Scopes = @()
                ExpirationTime = $null
                IssuedAt = $null
                Issuer = ""
            }
            
            # Get user info
            if ($tokenData.upn) {
                $metadata.UserPrincipalName = $tokenData.upn
            } elseif ($tokenData.email) {
                $metadata.UserPrincipalName = $tokenData.email
            } elseif ($tokenData.unique_name) {
                $metadata.UserPrincipalName = $tokenData.unique_name
            }
            
            # Get expiration time
            if ($tokenData.exp) {
                $epochTime = $tokenData.exp
                $metadata.ExpirationTime = [System.DateTimeOffset]::FromUnixTimeSeconds($epochTime).DateTime.ToLocalTime()
            }
            
            # Get issued at time
            if ($tokenData.iat) {
                $issuedEpochTime = $tokenData.iat
                $metadata.IssuedAt = [System.DateTimeOffset]::FromUnixTimeSeconds($issuedEpochTime).DateTime.ToLocalTime()
            }
            
            # Get scopes
            if ($tokenData.scp) {
                $metadata.Scopes = $tokenData.scp -split " "
            } elseif ($tokenData.roles) {
                $metadata.Scopes = $tokenData.roles
            }
            
            # Get issuer
            if ($tokenData.iss) {
                $metadata.Issuer = $tokenData.iss
            }
        } catch {
            Write-Warning "Could not fully extract token metadata: $_"
            $metadata = @{
                Status = "unknown"
                UserPrincipalName = "unknown"
                ExpirationTime = (Get-Date).AddDays(1)
            }
        }
        
        # Create storage directory if it doesn't exist
        $appDataPath = [Environment]::GetFolderPath('ApplicationData')
        $tokenStoragePath = Join-Path -Path $appDataPath -ChildPath "IntuneRemediation\TokenStorage\$ProfileName"
        
        # Create directory if it doesn't exist
        if (-not (Test-Path -Path $tokenStoragePath)) {
            Write-Verbose "Creating token storage directory: $tokenStoragePath"
            New-Item -Path $tokenStoragePath -ItemType Directory -Force | Out-Null
        }
        
        # Use consistent file naming pattern with profile name prefix
        $tokenPath = Join-Path -Path $tokenStoragePath -ChildPath "$ProfileName.token.xml"
        $metadataPath = Join-Path -Path $tokenStoragePath -ChildPath "$ProfileName.metadata.xml"
        
        # Check for legacy files (without profile name prefix)
        $legacyTokenPath = Join-Path -Path $tokenStoragePath -ChildPath "token.xml"
        $legacyMetadataPath = Join-Path -Path $tokenStoragePath -ChildPath "metadata.xml"
        
        # Remove legacy files if they exist to avoid confusion
        if (Test-Path -Path $legacyTokenPath) {
            Write-Verbose "Removing legacy token file: $legacyTokenPath"
            Remove-Item -Path $legacyTokenPath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -Path $legacyMetadataPath) {
            Write-Verbose "Removing legacy metadata file: $legacyMetadataPath"
            Remove-Item -Path $legacyMetadataPath -Force -ErrorAction SilentlyContinue
        }
        
        # Encrypt and save token using our custom protection function
        $encryptedToken = Protect-IntuneString -String $Token
        Set-Content -Path $tokenPath -Value $encryptedToken -Force
        
        # Verify the token was saved correctly
        if (Test-Path -Path $tokenPath) {
            $savedEncryptedToken = Get-Content -Path $tokenPath -Raw -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($savedEncryptedToken)) {
                Write-Warning "Token file was created but appears to be empty. This may cause issues."
            } else {
                Write-Verbose "Token file saved successfully: $tokenPath"
            }
        } else {
            Write-Warning "Failed to verify token file was created: $tokenPath"
        }
        
        # Save metadata separately
        $metadata | Export-Clixml -Path $metadataPath -Force
        
        # Return information about the saved token
        return [PSCustomObject]@{
            ProfileName = $ProfileName
            FilePath = $tokenPath
            Status = $metadata.Status
            ExpirationTime = $metadata.ExpirationTime
            UserPrincipalName = $metadata.UserPrincipalName
            TokenLength = $Token.Length
            Scopes = $metadata.Scopes
        }
    } catch {
        Write-Error "Error saving token: $_"
        return $null
    } finally {
        # Clean up memory to avoid leaving sensitive information in memory
        [System.GC]::Collect()
    }
} 