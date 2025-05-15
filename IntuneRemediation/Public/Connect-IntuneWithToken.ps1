function Connect-IntuneWithToken {
    <#
    .SYNOPSIS
        Connects to Microsoft Intune using a browser-acquired token.
        
    .DESCRIPTION
        This function establishes a connection to Microsoft Intune using a token acquired from a browser.
        It validates the token, ensures required modules are installed, and establishes both PowerShell cmdlet
        and REST API access.
        
    .PARAMETER Token
        The authentication token string obtained from a browser session.
        
    .PARAMETER ShowScopes
        If specified, displays all permission scopes available in the token.
        
    .PARAMETER SuppressWarnings
        If specified, suppresses warnings about missing specific scopes when the token
        contains administrative roles or broader permissions.
        
    .EXAMPLE
        Connect-IntuneWithToken -Token "eyJ0eXAiOiJKV..."
        
    .EXAMPLE
        Connect-IntuneWithToken -Token "eyJ0eXAiOiJKV..." -ShowScopes -SuppressWarnings
        
    .NOTES
        Requires Microsoft.Graph.Authentication and Microsoft.Graph.DeviceManagement modules.
        The token expires after approximately one hour and will need to be refreshed.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowScopes,
        
        [Parameter(Mandatory = $false)]
        [switch]$SuppressWarnings
    )
    
    try {
        # Extract and decode token information
        $tokenParts = $Token.Split('.')
        if ($tokenParts.Count -ge 2) {
            $payload = $tokenParts[1].Replace('-', '+').Replace('_', '/')
            while ($payload.Length % 4) { $payload += "=" }
            
            $decodedToken = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
            
            # Extract scopes and roles
            $scopes = @()
            $roles = @()
            
            if ($decodedToken.scp) {
                $scopes = $decodedToken.scp -split " "
            }
            
            if ($decodedToken.roles) {
                $roles = $decodedToken.roles
            }
            
            if ($decodedToken.wids) {
                $roles += $decodedToken.wids
            }
            
            # Show scopes and roles if requested
            if ($ShowScopes) {
                Write-Host "`nToken information:" -ForegroundColor Cyan
                
                # Show username
                if ($decodedToken.upn) {
                    Write-Host "  User: $($decodedToken.upn)" -ForegroundColor Yellow
                } elseif ($decodedToken.unique_name) {
                    Write-Host "  User: $($decodedToken.unique_name)" -ForegroundColor Yellow
                }
                
                # Show expiration
                if ($decodedToken.exp) {
                    $expirationTime = [DateTimeOffset]::FromUnixTimeSeconds($decodedToken.exp).DateTime.ToLocalTime()
                    Write-Host "  Expires: $expirationTime" -ForegroundColor Yellow
                }
                
                # Show scopes
                if ($scopes.Count -gt 0) {
                    Write-Host "`n  Available scopes:" -ForegroundColor Cyan
                    foreach ($scope in $scopes | Sort-Object) {
                        # Use simple asterisk instead of bullet point for better compatibility
                        Write-Host "    * $scope" -ForegroundColor Green
                    }
                }
                
                # Show roles with friendly names
                if ($roles.Count -gt 0) {
                    Write-Host "`n  Assigned roles:" -ForegroundColor Cyan
                    foreach ($roleId in $roles | Sort-Object) {
                        # Get friendly name for this role ID
                        $friendlyName = Get-IntuneRoleFriendlyName -RoleId $roleId
                        
                        # Display both the friendly name and ID for transparency and debugging
                        if ($friendlyName -ne $roleId) {
                            Write-Host "    * $friendlyName  [$roleId]" -ForegroundColor Magenta
                        } else {
                            # If no friendly name was found, just show the ID
                            Write-Host "    * $roleId" -ForegroundColor Magenta
                        }
                    }
                }
                
                Write-Host ""
            }
            
            # Check for admin roles that would supersede specific scopes
            $hasAdminRole = $false
            $adminRoleIds = @(
                # Intune Administrator role
                "3a2c62db-5318-420d-8d74-23affee5d9d5",
                # Global Administrator role
                "62e90394-69f5-4237-9190-012177145e10",
                # Intune Service Administrator role
                "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3",
                # Check for Application Administrator as well
                "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
            )
            
            if ($roles) {
                foreach ($roleId in $adminRoleIds) {
                    if ($roles -contains $roleId) {
                        $hasAdminRole = $true
                        break
                    }
                }
            }
        }
        
        # Convert token to SecureString
        $SecureToken = ConvertTo-SecureString -String $Token -AsPlainText -Force
        
        # Verify required modules are installed
        $RequiredModules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.DeviceManagement")
        foreach ($Module in $RequiredModules) {
            if (-not (Get-Module -Name $Module -ListAvailable)) {
                Write-Warning "$Module module not found. Attempting to install..."
                try {
                    # Try installing with machine scope first
                    try {
                        Install-Module -Name $Module -Scope AllUsers -Force -AllowClobber
                        Write-Host "Installed $Module module with machine scope (AllUsers)." -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Failed to install with machine scope. This may require admin rights. Error: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host "Attempting to install with user scope instead..." -ForegroundColor Yellow
                        Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
                        Write-Host "Installed $Module module with user scope (CurrentUser)." -ForegroundColor Green
                    }
                }
                catch {
                    Write-Error "Failed to install $Module. Please install it manually using: Install-Module -Name $Module -Scope CurrentUser -Force"
                    return $false
                }
            }
        }
        
        # Disconnect from any existing Graph connection
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            # Ignore any errors from disconnection
        }
        
        # Connect to Microsoft Graph with the token
        try {
            Connect-MgGraph -AccessToken $SecureToken -NoWelcome
            
            # Suppress scope warnings if the user has admin roles or specified the parameter
            if (-not $SuppressWarnings -and -not $hasAdminRole) {
                # Check for required scopes
                $requiredScopes = @(
                    "DeviceManagementManagedDevices.Read.All",
                    "DeviceManagementConfiguration.Read.All"
                )
                
                foreach ($requiredScope in $requiredScopes) {
                    if ($scopes -notcontains $requiredScope -and -not $hasAdminRole) {
                        Write-Warning "The token may not have all required permissions. Missing: $requiredScope"
                    }
                }
            }
            
            Write-Host "[SUCCESS] Successfully connected to Microsoft Graph!" -ForegroundColor Green
            
            # Store REST API headers for direct API calls if needed
            $script:IntuneHeaders = @{
                "Authorization" = "Bearer $Token"
                "Content-Type" = "application/json"
            }
            
            # Store the token for potential reconnection
            $script:IntuneToken = $Token
            
            return $true
        }
        catch {
            Write-Error "Failed to connect to Microsoft Graph: $_"
            return $false
        }
    }
    catch {
        Write-Error "Error in Connect-IntuneWithToken: $_"
        return $false
    }
} 