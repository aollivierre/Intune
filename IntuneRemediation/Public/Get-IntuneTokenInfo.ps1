function Get-IntuneTokenInfo {
    <#
    .SYNOPSIS
        Retrieves information about a saved Intune authentication token.
        
    .DESCRIPTION
        This function retrieves information about a saved Intune authentication token,
        including its expiration status, user information, and permissions scope.
        
        If you need the token storage path for other operations, you can use the
        Get-IntuneTokenStoragePath function which is now exposed as a public function.
        
    .PARAMETER ProfileName
        The profile name associated with the token. Default is "Default".
        
    .PARAMETER ShowScopes
        If specified, displays the full list of scopes the token has access to.
        
    .EXAMPLE
        Get-IntuneTokenInfo
        
        Retrieves information about the token saved under the "Default" profile.
        
    .EXAMPLE
        Get-IntuneTokenInfo -ProfileName "WorkAccount" -ShowScopes
        
        Retrieves information about the token saved under the "WorkAccount" profile,
        including full scope information.
        
    .NOTES
        This function does not retrieve the actual token value for security reasons.
        
        Related functions:
        - Get-IntuneTokenStoragePath: Get the path where tokens are stored
        - Get-IntuneToken: Retrieve the actual token value for use in authentication
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ProfileName = "Default",
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowScopes
    )
    
    try {
        # Get the token storage path using the standard function
        $tokenPath = Get-IntuneTokenStoragePath -ProfileName $ProfileName
        
        # Define possible file patterns for both token and metadata
        $possibleTokenFiles = @(
            # Current naming pattern (with ProfileName prefix)
            (Join-Path -Path $tokenPath -ChildPath "$ProfileName.token.xml"),
            # Legacy naming pattern (without prefix)
            (Join-Path -Path $tokenPath -ChildPath "token.xml")
        )
        
        $possibleMetadataFiles = @(
            # Current naming pattern (with ProfileName prefix)
            (Join-Path -Path $tokenPath -ChildPath "$ProfileName.metadata.xml"),
            # Legacy naming pattern (without prefix)
            (Join-Path -Path $tokenPath -ChildPath "metadata.xml")
        )
        
        # Find the first token file that exists
        $tokenFilePath = $null
        foreach ($path in $possibleTokenFiles) {
            if (Test-Path -Path $path) {
                $tokenFilePath = $path
                Write-Verbose "Found token file at: $tokenFilePath"
                break
            }
        }
        
        # Find the first metadata file that exists
        $metadataPath = $null
        foreach ($path in $possibleMetadataFiles) {
            if (Test-Path -Path $path) {
                $metadataPath = $path
                Write-Verbose "Found metadata file at: $metadataPath"
                break
            }
        }
        
        # Check if files exist
        $tokenFound = ($tokenFilePath -ne $null)
        $metadataFound = ($metadataPath -ne $null)
        
        Write-Verbose "Token path: $(if ($tokenFilePath) { $tokenFilePath } else { 'None found' }) (Exists: $tokenFound)"
        Write-Verbose "Metadata path: $(if ($metadataPath) { $metadataPath } else { 'None found' }) (Exists: $metadataFound)"
        
        # Initialize return object
        $result = [PSCustomObject]@{
            ProfileName = $ProfileName
            TokenPath = $tokenFilePath
            MetadataPath = $metadataPath
            UserPrincipalName = $null
            IsExpired = $true
            ExpirationTime = $null
            Scopes = @()
            TokenFound = $tokenFound
            Status = if (-not $tokenFound) { "NotFound" } else { "Unknown" }
        }
        
        # Process token info if both files exist
        if ($tokenFound -and $metadataFound) {
            # Load metadata
            try {
                $metadata = Import-Clixml -Path $metadataPath -ErrorAction Stop
                
                # Check if token is expired
                $isExpired = $false
                if ($metadata.ExpirationTime) {
                    $isExpired = $metadata.ExpirationTime -lt (Get-Date)
                }
                
                # Update the result object with metadata information
                $result.UserPrincipalName = $metadata.UserPrincipalName
                $result.IsExpired = $isExpired
                $result.ExpirationTime = $metadata.ExpirationTime
                $result.Scopes = $metadata.Scopes
                $result.Status = if ($isExpired) { "Expired" } else { "Valid" }
                
                # If ShowScopes specified, display all scopes
                if ($ShowScopes -and $result.Scopes -and $result.Scopes.Count -gt 0) {
                    Write-Host "`nToken Scopes for profile '$ProfileName':" -ForegroundColor Cyan
                    foreach ($scope in $result.Scopes | Sort-Object) {
                        # Use simple asterisk instead of bullet point for better compatibility
                        Write-Host "  * $scope" -ForegroundColor Yellow
                    }
                    Write-Host ""
                }
            }
            catch {
                Write-Warning "Error loading metadata: $_"
                $result.Status = "Error"
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Error retrieving token information: $_"
        return [PSCustomObject]@{
            ProfileName = $ProfileName
            TokenFound = $false
            Status = "Error"
            Error = $_.Exception.Message
        }
    }
} 