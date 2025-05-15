# Authentication related functions

function Test-ClientSecretValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientID,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )
    
    try {
        $timeoutSec = 20
        $startTime = Get-Date
        
        $body = @{
            client_id = $ClientID
            client_secret = $ClientSecret
            scope = "/.default"
            grant_type = "client_credentials"
        }
        
        Write-Host "Testing client secret validity..." -ForegroundColor Yellow
        
        # Use Microsoft Graph token endpoint
        $msGraphTokenUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
        
        $params = @{
            Uri = $msGraphTokenUrl
            Method = "POST"
            Body = $body
            ContentType = "application/x-www-form-urlencoded"
            TimeoutSec = $timeoutSec
            ErrorAction = "Stop"
        }
        
        $response = Invoke-RestMethod @params
        
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        
        # Check if we got an access token
        if ($response.access_token) {
            Write-Host "Client secret is valid. Token acquired in $executionTime seconds." -ForegroundColor Green
            return @{
                Valid = $true
                TokenResponse = $response
                ExpiresOn = (Get-Date).AddSeconds($response.expires_in)
                ExecutionTime = $executionTime
            }
        } else {
            Write-Warning "Secret validation completed but no access token received."
            return @{
                Valid = $false
                TokenResponse = $null
                ExpiresOn = $null
                ExecutionTime = $executionTime
            }
        }
    }
    catch {
        Write-Warning "Client secret validation failed: $($_.Exception.Message)"
        if ($_.Exception.Response.StatusCode -eq 400) {
            if ($_.ErrorDetails.Message -like "*AADSTS7000215*") {
                Write-Host "Client secret is invalid or has expired." -ForegroundColor Red
            }
            elseif ($_.ErrorDetails.Message -like "*AADSTS700016*") {
                Write-Host "Application not found. Please verify the Application (Client) ID." -ForegroundColor Red
            }
        }
        return @{
            Valid = $false
            TokenResponse = $null
            ExpiresOn = $null
            ExecutionTime = (Get-Date - $startTime).TotalSeconds
            Error = $_.Exception.Message
        }
    }
}

function Test-SecretsValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TenantID,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientID,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )
    
    $validationResults = @{
        TokenValid = $false
        AccessToken = $null
        TokenExpiresOn = $null
        PermissionsValid = $false
        PermissionsReport = @{}
        ValidationStartTime = Get-Date
        ValidationEndTime = $null
        ValidationDurationSeconds = $null
    }
    
    try {
        Write-Host "Validating credentials and permissions..." -ForegroundColor Yellow
        
        # First, get an access token to validate the tenant ID, client ID, and secret
        $tokenUrl = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        $body = @{
            client_id = $ClientID
            client_secret = $ClientSecret
            scope = "https://graph.microsoft.com/.default"
            grant_type = "client_credentials"
        }
        
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
        $validationResults.TokenValid = $true
        $validationResults.AccessToken = $response.access_token
        $validationResults.TokenExpiresOn = (Get-Date).AddSeconds($response.expires_in)
        
        Write-Host "Authentication successful! Testing permissions..." -ForegroundColor Green
        
        # Define the permissions we need to test
        $requiredPermissions = @(
            @{
                Name = "DeviceManagementServiceConfig.ReadWrite.All"
                Uri = "https://graph.microsoft.com/v1.0/deviceManagement/deviceEnrollmentConfigurations"
                Method = "GET"
                Required = $true
            },
            @{
                Name = "Device.ReadWrite.All"
                Uri = "https://graph.microsoft.com/v1.0/devices"
                Method = "GET"
                Required = $true
            },
            @{
                Name = "DeviceManagementManagedDevices.ReadWrite.All"
                Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
                Method = "GET"
                Required = $true
            },
            @{
                Name = "Organization.Read.All"
                Uri = "https://graph.microsoft.com/v1.0/organization"
                Method = "GET"
                Required = $true
            },
            @{
                Name = "Application.Read.All"
                Uri = "https://graph.microsoft.com/v1.0/applications"
                Method = "GET"
                Required = $true
            }
        )
        
        $headers = @{
            "Authorization" = "Bearer $($response.access_token)"
        }
        
        $allRequiredPermissionsValid = $true
        
        foreach ($permission in $requiredPermissions) {
            try {
                Invoke-RestMethod -Uri $permission.Uri -Headers $headers -Method $permission.Method -ErrorAction Stop | Out-Null
                $validationResults.PermissionsReport[$permission.Name] = $true
                Write-Host "✓ Permission verified: $($permission.Name)" -ForegroundColor Green
            }
            catch {
                $validationResults.PermissionsReport[$permission.Name] = $false
                $errorMessage = "✗ Missing permission: $($permission.Name)"
                if ($permission.Required) {
                    $allRequiredPermissionsValid = $false
                    Write-Host $errorMessage -ForegroundColor Red
                }
                else {
                    Write-Host "$errorMessage (Optional)" -ForegroundColor Yellow
                }
            }
        }
        
        $validationResults.PermissionsValid = $allRequiredPermissionsValid
        $validationResults.ValidationEndTime = Get-Date
        $validationResults.ValidationDurationSeconds = ($validationResults.ValidationEndTime - $validationResults.ValidationStartTime).TotalSeconds
        
        if ($allRequiredPermissionsValid) {
            Write-Host "All required permissions verified successfully!" -ForegroundColor Green
        }
        else {
            Write-Warning "Some required permissions are missing. Please update your app registration."
        }
        
        return $validationResults
    }
    catch {
        Write-Warning "Failed to validate credentials: $($_.Exception.Message)"
        if ($_.Exception.Message -like "*AADSTS7000215*") {
            Write-Host "Invalid client secret. Please check if the secret has expired." -ForegroundColor Red
        }
        elseif ($_.Exception.Message -like "*AADSTS700016*") {
            Write-Host "Application not found. Please verify the Application (Client) ID." -ForegroundColor Red
        }
        return $validationResults
    }
}

# Export functions to make them available within the module
Export-ModuleMember -Function Test-ClientSecretValidity, Test-SecretsValidity
