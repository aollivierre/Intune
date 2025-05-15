# Microsoft Graph API related functions

function Get-TenantDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TenantID,
        
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )
    
    try {
        Write-Host "Fetching tenant details from Microsoft Graph..." -ForegroundColor Yellow
        
        $headers = @{
            'Authorization' = "Bearer $AccessToken"
            'Content-Type' = 'application/json'
        }
        
        $response = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/organization" -Headers $headers
        
        if ($response.value -and $response.value[0].displayName) {
            Write-Host "Successfully retrieved tenant name: $($response.value[0].displayName)" -ForegroundColor Green
            return $response.value[0].displayName
        } else {
            Write-Warning "Tenant name not found in the Graph API response"
            Write-Host "Response content: $($response | ConvertTo-Json)" -ForegroundColor Yellow
            return "Unknown Tenant"
        }
    }
    catch {
        Write-Warning "Could not fetch tenant name from Graph API: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Warning "Detailed error: $responseBody"
        }
        return "Unknown Tenant"
    }
}

function Get-AppRegistrationDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientID,
        
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )
    
    try {
        Write-Host "Fetching app registration details..." -ForegroundColor Yellow
        
        $headers = @{
            'Authorization' = "Bearer $AccessToken"
            'Content-Type' = 'application/json'
        }
        
        # Use $filter query to find application by appId (ClientID)
        $response = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=appId eq '$ClientID'" -Headers $headers
        
        if ($response.value.Count -gt 0) {
            $app = $response.value[0]
            Write-Host "Successfully retrieved app details for: $($app.displayName)" -ForegroundColor Green
            return @{
                DisplayName = $app.displayName
                AppId = $app.appId
                CreatedDateTime = $app.createdDateTime
                ObjectId = $app.id
            }
        } else {
            Write-Warning "No application found with Client ID: $ClientID"
            return $null
        }
    }
    catch {
        Write-Warning "Could not fetch app registration details: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Warning "Detailed error: $responseBody"
        }
        return $null
    }
}

function Show-InitializationReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$TenantName = "Unknown Tenant",
        
        [Parameter(Mandatory = $true)]
        [string]$TenantID,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientID,
        
        [Parameter()]
        [hashtable]$ValidationResults,
        
        [Parameter()]
        [hashtable]$AppDetails,
        
        [Parameter()]
        [hashtable]$SecretValidation
    )
    
    $border = "-" * 80
    
    Write-Host $border -ForegroundColor Cyan
    Write-Host "WINDOWS AUTOPILOT REGISTRATION - INITIALIZATION REPORT" -ForegroundColor Cyan
    Write-Host $border -ForegroundColor Cyan
    
    # Tenant Information
    Write-Host "TENANT INFORMATION:" -ForegroundColor Cyan
    Write-Host "   Tenant Name: $TenantName"
    Write-Host "   Tenant ID: $TenantID"
    
    # Application Information
    Write-Host "`nAPPLICATION INFORMATION:" -ForegroundColor Cyan
    if ($AppDetails) {
        Write-Host "   App Name: $($AppDetails.DisplayName)"
        Write-Host "   Client ID: $ClientID"
        Write-Host "   Object ID: $($AppDetails.ObjectId)"
        Write-Host "   Created: $($AppDetails.CreatedDateTime)"
    } else {
        Write-Host "   Client ID: $ClientID"
        Write-Host "   [!] Could not retrieve detailed application information" -ForegroundColor Yellow
    }
    
    # Authentication Status
    Write-Host "`nAUTHENTICATION STATUS:" -ForegroundColor Cyan
    if ($ValidationResults.TokenValid) {
        Write-Host "   [✓] Authentication Successful" -ForegroundColor Green
        Write-Host "   Token Expires: $($ValidationResults.TokenExpiresOn)"
    } else {
        Write-Host "   [✗] Authentication Failed" -ForegroundColor Red
    }
    
    # Client Secret Status
    Write-Host "`nCLIENT SECRET STATUS:" -ForegroundColor Cyan
    if ($SecretValidation.Valid) {
        Write-Host "   [✓] Client Secret Valid" -ForegroundColor Green
        Write-Host "   Secret Expires On: $($SecretValidation.ExpiresOn)"
    } else {
        Write-Host "   [✗] Client Secret Invalid or Expired" -ForegroundColor Red
        if ($SecretValidation.Error) {
            Write-Host "   Error: $($SecretValidation.Error)" -ForegroundColor Red
        }
    }
    
    # Permission Status
    Write-Host "`nPERMISSION STATUS:" -ForegroundColor Cyan
    if ($ValidationResults.PermissionsValid) {
        Write-Host "   [✓] All Required Permissions Granted" -ForegroundColor Green
    } else {
        Write-Host "   [✗] Missing Required Permissions" -ForegroundColor Red
    }
    
    # Show individual permissions
    if ($ValidationResults.PermissionsReport) {
        Write-Host "`nPERMISSION DETAILS:" -ForegroundColor Cyan
        foreach ($permission in $ValidationResults.PermissionsReport.GetEnumerator()) {
            $status = if ($permission.Value) { "[✓]" } else { "[✗]" }
            $color = if ($permission.Value) { "Green" } else { "Red" }
            Write-Host "   $status $($permission.Name)" -ForegroundColor $color
        }
    }
    
    Write-Host $border -ForegroundColor Cyan
}

# Export functions to make them available within the module
Export-ModuleMember -Function Get-TenantDetails, Get-AppRegistrationDetails, Show-InitializationReport
