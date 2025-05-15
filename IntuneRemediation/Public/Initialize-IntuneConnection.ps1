function Initialize-IntuneConnection {
    <#
    .SYNOPSIS
        Establishes a connection to Microsoft Intune using either a saved token or a new browser authentication.
        
    .DESCRIPTION
        This function connects to Microsoft Intune for management operations.
        It can use a saved authentication token or prompt for a new browser-based authentication.
        Saved tokens are securely stored and can be reused for subsequent connections.
        
    .PARAMETER ProfileName
        The name of the profile to use or create for token storage.
        Default is "Default".
        
    .PARAMETER ForceBrowser
        If specified, forces the use of browser authentication even if a saved token exists.
        By default, interactive authentication is disabled and only token-based auth is used.
        
    .PARAMETER Scopes
        The Microsoft Graph API scopes to request. By default, includes scopes needed for Intune management.
        
    .PARAMETER SaveTokenForReuse
        If specified, saves the token for future use. Default is $true.
        
    .PARAMETER UseDeviceCode
        If specified, uses device code flow instead of interactive browser authentication.
        
    .PARAMETER TokenFilePath
        Optional path to a token file to use instead of the default profile storage.
        
    .PARAMETER DisableInteractiveAuth
        If specified (default is $true), disables interactive authentication and only uses tokens.
        Set to $false to allow fallback to interactive authentication if no valid token is found.
        
    .EXAMPLE
        Initialize-IntuneConnection
        
        Connects to Intune using a saved token if available. Will not use interactive auth by default.
        
    .EXAMPLE
        Initialize-IntuneConnection -ProfileName "CompanyAdmin" -ForceBrowser -DisableInteractiveAuth:$false
        
        Forces a new browser authentication and saves the token under the "CompanyAdmin" profile.
        
    .NOTES
        Requires Microsoft Graph PowerShell SDK to be installed.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ProfileName = "Default",
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceBrowser = $false,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Scopes = @(
            "DeviceManagementApps.ReadWrite.All",
            "DeviceManagementConfiguration.ReadWrite.All",
            "DeviceManagementManagedDevices.ReadWrite.All",
            "DeviceManagementRBAC.ReadWrite.All",
            "DeviceManagementServiceConfig.ReadWrite.All"
        ),
        
        [Parameter(Mandatory = $false)]
        [bool]$SaveTokenForReuse = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseDeviceCode = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$TokenFilePath = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$DisableInteractiveAuth = $true
    )
    
    # Check for required modules
    if (-not (Get-Module -Name Microsoft.Graph.Authentication -ListAvailable) -and 
        -not (Get-Module -Name Microsoft.Graph.Authentication)) {
        Write-Error "Microsoft Graph PowerShell SDK is not installed. Please install it using:"
        Write-Error "Install-Module Microsoft.Graph -Scope CurrentUser -Force"
        return $false
    }
    
    try {
        # First, check if any token is already connected
        try {
            $graphContext = Get-MgContext -ErrorAction SilentlyContinue
            if ($graphContext -and -not $ForceBrowser) {
                Write-Host "Already connected to Microsoft Graph as $($graphContext.Account)" -ForegroundColor Green
                Write-Verbose "Graph context scopes: $($graphContext.Scopes -join ', ')"
                
                # Check if connected scopes include what we need
                $missingScopes = $Scopes | Where-Object { $graphContext.Scopes -notcontains $_ }
                if ($missingScopes.Count -eq 0) {
                    Write-Verbose "Current connection has all required scopes"
                    return $true
                } else {
                    Write-Warning "Current connection is missing required scopes: $($missingScopes -join ', ')"
                    Write-Verbose "Will attempt to reconnect with all required scopes"
                    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
                }
            }
        } catch {
            Write-Verbose "No existing Graph connection or error checking context: $_"
        }
        
        $token = $null
        $browserRequired = $ForceBrowser
        $attemptedTokenRefresh = $false
        
        # Handle token from explicit file path if provided
        if ($TokenFilePath -and (Test-Path $TokenFilePath)) {
            try {
                Write-Host "Loading token from specified file: $TokenFilePath" -ForegroundColor Yellow
                $encryptedToken = Get-Content -Path $TokenFilePath -Raw
                $token = Unprotect-IntuneString -EncryptedString $encryptedToken
                
                # Validate the token
                Write-Host "Validating token from file..." -ForegroundColor Yellow
                $isValid = Test-IntuneToken -Token $token
                
                if (-not $isValid) {
                    Write-Warning "Token from file is invalid or expired."
                    $token = $null
                    # Only set browserRequired if interactive auth is allowed
                    $browserRequired = -not $DisableInteractiveAuth
                }
            } catch {
                Write-Warning "Error loading token from file: $_"
                $token = $null
                # Only set browserRequired if interactive auth is allowed
                $browserRequired = -not $DisableInteractiveAuth
            }
        }
        # Try to use a saved token if not forcing browser and no explicit file path
        elseif (-not $ForceBrowser) {
            Write-Host "Checking for saved tokens..." -ForegroundColor Yellow
            
            try {
                $tokenPath = Get-IntuneTokenStoragePath -ProfileName $ProfileName
                $tokenFilePath = Join-Path -Path $tokenPath -ChildPath "$ProfileName.token.xml"
                
                if (Test-Path $tokenFilePath) {
                    Write-Host "Found saved token for profile '$ProfileName'" -ForegroundColor Green
                    
                    # Load and decrypt the token
                    $encryptedToken = Get-Content -Path $tokenFilePath -Raw
                    $savedToken = Unprotect-IntuneString -EncryptedString $encryptedToken
                    
                    # Also load metadata
                    $metadataFilePath = Join-Path -Path $tokenPath -ChildPath "$ProfileName.metadata.xml"
                    if (Test-Path $metadataFilePath) {
                        $metadata = Import-Clixml -Path $metadataFilePath
                        Write-Host "  Associated with: $($metadata.UserPrincipalName)" -ForegroundColor Cyan
                        Write-Host "  Token status: $($metadata.Status) until $($metadata.ExpirationTime)" -ForegroundColor Cyan
                    }
                    
                    # Check if token is valid
                    Write-Host "Validating token..." -ForegroundColor Yellow
                    $isValid = Test-IntuneToken -Token $savedToken
                    
                    if ($isValid) {
                        Write-Host "[SUCCESS] Token validated successfully." -ForegroundColor Green
                        $token = $savedToken
                    } else {
                        Write-Warning "Saved token is invalid or expired."
                        if (-not $DisableInteractiveAuth) {
                            Write-Host "Will attempt to get a new token via browser authentication." -ForegroundColor Yellow
                            $browserRequired = $true
                        } else {
                            Write-Error "No valid token found and interactive authentication is disabled."
                            return $false
                        }
                    }
                } else {
                    Write-Host "No saved token found for profile '$ProfileName'" -ForegroundColor Yellow
                    if (-not $DisableInteractiveAuth) {
                        $browserRequired = $true
                    } else {
                        Write-Error "No saved token found and interactive authentication is disabled."
                        return $false
                    }
                }
            } catch {
                Write-Warning "Error retrieving saved token: $_"
                if (-not $DisableInteractiveAuth) {
                    $browserRequired = $true
                } else {
                    Write-Error "Error accessing token and interactive authentication is disabled: $_"
                    return $false
                }
            }
        }
        
        # Get a new token via browser if needed
        if (($browserRequired -or -not $token) -and -not $DisableInteractiveAuth) {
            Write-Host "Initiating authentication process..." -ForegroundColor Yellow
            
            if ($UseDeviceCode) {
                Write-Host "Using device code authentication flow" -ForegroundColor Yellow
                Connect-MgGraph -Scopes $Scopes -UseDeviceCode -NoWelcome
            } else {
                Write-Host "Using interactive browser authentication" -ForegroundColor Yellow
                Connect-MgGraph -Scopes $Scopes -NoWelcome
            }
            
            # Get the token from the existing connection
            $graphContext = Get-MgContext
            
            if ($graphContext -and $graphContext.AccessToken) {
                Write-Host "Successfully authenticated as $($graphContext.Account)" -ForegroundColor Green
                $token = $graphContext.AccessToken
                
                # Save token for future use if requested
                if ($SaveTokenForReuse) {
                    Write-Host "Saving token for future use..." -ForegroundColor Yellow
                    $tokenInfo = Save-IntuneToken -Token $token -ProfileName $ProfileName
                    Write-Host "Token saved successfully to $($tokenInfo.FilePath)." -ForegroundColor Green
                    Write-Host "Token expires on: $($tokenInfo.ExpirationTime)" -ForegroundColor Cyan
                    Write-Host "Token associated with: $($tokenInfo.UserPrincipalName)" -ForegroundColor Cyan
                }
                
                return $true
            } else {
                Write-Error "Failed to obtain access token from Microsoft Graph authentication."
                return $false
            }
        } elseif (($browserRequired -or -not $token) -and $DisableInteractiveAuth) {
            Write-Error "No valid token found and interactive authentication is disabled. Please provide a valid token."
            return $false
        } else {
            # We have a valid saved token, use it
            try {
                # Create a secure string for the token
                $secureToken = ConvertTo-SecureString -String $token -AsPlainText -Force
                
                # Connect using the token
                Connect-MgGraph -AccessToken $secureToken -NoWelcome
                
                # Verify connection
                $graphContext = Get-MgContext
                if ($graphContext -and $graphContext.Account) {
                    Write-Host "Successfully connected to Microsoft Graph as $($graphContext.Account)" -ForegroundColor Green
                    
                    # Refresh the saved token if we're using it
                    if ($SaveTokenForReuse -and -not $TokenFilePath) {
                        Write-Host "Refreshing saved token..." -ForegroundColor Yellow
                        $tokenInfo = Save-IntuneToken -Token $token -ProfileName $ProfileName
                        Write-Host "Token refreshed successfully." -ForegroundColor Green
                    }
                    
                    return $true
                } else {
                    Write-Error "Failed to establish Microsoft Graph PowerShell session with token."
                    
                    # If we've not tried browser auth yet and interactive auth is allowed, fall back to it
                    if (-not $attemptedTokenRefresh -and -not $ForceBrowser -and -not $DisableInteractiveAuth) {
                        Write-Host "Attempting browser authentication as fallback..." -ForegroundColor Yellow
                        $browserRequired = $true
                        $attemptedTokenRefresh = $true
                        
                        # Disconnect any failed session
                        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
                        
                        # Go back and try browser auth
                        return Initialize-IntuneConnection -ProfileName $ProfileName -ForceBrowser -Scopes $Scopes -SaveTokenForReuse $SaveTokenForReuse -UseDeviceCode:$UseDeviceCode -DisableInteractiveAuth:$false
                    } else {
                        if ($DisableInteractiveAuth) {
                            Write-Error "Failed to connect with token and interactive authentication is disabled."
                        }
                    }
                    
                    return $false
                }
            } catch {
                Write-Error "Could not establish Microsoft Graph PowerShell session: $_"
                
                # If we've not tried browser auth yet and interactive auth is allowed, fall back to it
                if (-not $attemptedTokenRefresh -and -not $ForceBrowser -and -not $DisableInteractiveAuth) {
                    Write-Host "Attempting browser authentication as fallback..." -ForegroundColor Yellow
                    
                    # Disconnect any failed session
                    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
                    
                    # Go back and try browser auth
                    return Initialize-IntuneConnection -ProfileName $ProfileName -ForceBrowser -Scopes $Scopes -SaveTokenForReuse $SaveTokenForReuse -UseDeviceCode:$UseDeviceCode -DisableInteractiveAuth:$false
                } else {
                    if ($DisableInteractiveAuth) {
                        Write-Error "Failed to connect with token and interactive authentication is disabled."
                    }
                }
                
                return $false
            }
        }
    } catch {
        Write-Error "Error in Initialize-IntuneConnection: $_"
        return $false
    }
} 