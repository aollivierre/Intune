# https://andrewstaylor.com/2023/06/13/authenticating-to-new-get-windowsautopilotinfo/

$script:Version = "1.1.0"

function Get-TenantDetails {
    param (
        [string]$TenantID,
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

function Show-InitializationReport {
    param (
        [string]$TenantName,
        [string]$TenantID,
        [string]$ClientID,
        [hashtable]$ValidationResults
    )
    
    $horizontalLine = "=" * 80
    Write-Host $horizontalLine -ForegroundColor Cyan
    Write-Host "Windows Autopilot Device Registration Script v$script:Version" -ForegroundColor Cyan
    Write-Host $horizontalLine -ForegroundColor Cyan
    Write-Host "Purpose: Register this device with Windows Autopilot in your Intune tenant"
    Write-Host "Script Location: $PSScriptRoot"
    Write-Host "Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""
    Write-Host "Connection Parameters:" -ForegroundColor Yellow
    Write-Host "- Tenant Name: $TenantName"
    Write-Host "- Tenant ID: $TenantID"
    Write-Host "- App ID: $ClientID"
    Write-Host ""
    Write-Host "Credential Validation Results:" -ForegroundColor Yellow
    Write-Host "- Access Token Valid: $($ValidationResults.TokenValid)" -ForegroundColor $(if ($ValidationResults.TokenValid) { 'Green' } else { 'Red' })
    Write-Host "- Token Expiration: $($ValidationResults.TokenExpiration)" -ForegroundColor $(if ($ValidationResults.TokenValid) { 'Green' } else { 'Red' })
    Write-Host "- Required Permissions Present: $($ValidationResults.PermissionsValid)" -ForegroundColor $(if ($ValidationResults.PermissionsValid) { 'Green' } else { 'Red' })
    Write-Host $horizontalLine -ForegroundColor Cyan
    Write-Host ""
}

function Get-SecureInput {
    param (
        [string]$prompt
    )
    
    $secureString = Read-Host -Prompt $prompt -AsSecureString
    return $secureString
}

function New-SecretsFile {
    param (
        [string]$FilePath
    )
    
    Write-Host "`nNo secrets file found or current secrets are invalid. Let's create one!" -ForegroundColor Yellow
    Write-Host "Please enter the following information:" -ForegroundColor Cyan
    
    $tenantId = Read-Host -Prompt "Enter your Tenant ID"
    $clientId = Read-Host -Prompt "Enter your Application (Client) ID"
    $clientSecret = Get-SecureInput "Enter your Client Secret"
    
    $secretsObject = @{
        TenantID = $tenantId
        ClientID = $clientId
        ClientSecret = $clientSecret
    }
    
    try {
        # Convert to secure XML and save
        $secretsObject | Export-Clixml -Path $FilePath
        Write-Host "Secrets file created successfully!" -ForegroundColor Green
        
        # Return plain text version for immediate use
        return @{
            TenantID = $tenantId
            ClientID = $clientId
            ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)
            )
        }
    }
    catch {
        Write-Error "Failed to create secrets file: $_"
        exit 1
    }
}

function Test-SecretsValidity {
    param (
        [string]$TenantID,
        [string]$ClientID,
        [string]$ClientSecret
    )
    
    $validationResults = @{
        TokenValid = $false
        TokenExpiration = $null
        PermissionsValid = $false
        AccessToken = $null
        PermissionDetails = @()
    }
    
    try {
        Write-Host "Testing credentials validity..." -ForegroundColor Yellow
        
        # Try to get an access token
        $url = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        $body = @{
            grant_type    = "client_credentials"
            client_id     = $ClientID
            client_secret = $ClientSecret
            scope         = "https://graph.microsoft.com/.default"
        }
        
        $response = Invoke-RestMethod -Method Post -Uri $url -Body $body -ContentType "application/x-www-form-urlencoded"
        
        $validationResults.TokenValid = $true
        $validationResults.TokenExpiration = (Get-Date).AddSeconds($response.expires_in)
        $validationResults.AccessToken = $response.access_token
        
        Write-Host "Access token obtained successfully. Testing permissions..." -ForegroundColor Green
        
        # Test required permissions
        $headers = @{
            'Authorization' = "Bearer $($response.access_token)"
            'Content-Type' = 'application/json'
        }
        
        # Test endpoints for each required permission
        $permissionTests = @(
            @{
                Name = "DeviceManagementServiceConfig.ReadWrite.All"
                Endpoint = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotSettings"
                Method = "GET"
            },
            @{
                Name = "Device.ReadWrite.All"
                Endpoint = "https://graph.microsoft.com/v1.0/devices"
                Method = "GET"
            },
            @{
                Name = "DeviceManagementManagedDevices.ReadWrite.All"
                Endpoint = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
                Method = "GET"
            }
        )
        
        $allPermissionsValid = $true
        foreach ($test in $permissionTests) {
            try {
                Write-Host "Testing permission: $($test.Name)..." -ForegroundColor Yellow
                $null = Invoke-RestMethod -Method $test.Method -Uri $test.Endpoint -Headers $headers
                Write-Host "[OK] $($test.Name) - Permission granted" -ForegroundColor Green
                $validationResults.PermissionDetails += @{
                    Permission = $test.Name
                    Status = "Granted"
                    Valid = $true
                }
            }
            catch {
                $allPermissionsValid = $false
                Write-Warning "[X] $($test.Name) - Permission denied: $($_.Exception.Message)"
                $validationResults.PermissionDetails += @{
                    Permission = $test.Name
                    Status = "Denied"
                    Valid = $false
                    Error = $_.Exception.Message
                }
            }
        }
        
        $validationResults.PermissionsValid = $allPermissionsValid
        
        if (-not $allPermissionsValid) {
            Write-Host "`nPermission validation failed. Please ensure:" -ForegroundColor Red
            Write-Host "1. The app registration has all required permissions" -ForegroundColor Red
            Write-Host "2. An admin has granted consent to these permissions" -ForegroundColor Red
            Write-Host "3. The client secret is valid and not expired" -ForegroundColor Red
            Write-Host "`nRequired permissions:" -ForegroundColor Yellow
            foreach ($detail in $validationResults.PermissionDetails) {
                $color = if ($detail.Valid) { 'Green' } else { 'Red' }
                Write-Host "- $($detail.Permission): $($detail.Status)" -ForegroundColor $color
            }
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

$ScriptName = $MyInvocation.MyCommand.Name
Write-Host "Executing $ScriptName" -ForegroundColor Green

$warningMessage = @"
[WARNING] Before proceeding, ensure your Entra ID App Registration has the following Graph API permissions:

Required Permissions:
1. DeviceManagementServiceConfig.ReadWrite.All
2. Device.ReadWrite.All
3. DeviceManagementManagedDevices.ReadWrite.All

Optional Permissions (depending on your scenario):
4. Group.ReadWrite.All (if using group assignments)
5. Domain.ReadWrite.All (if using hybrid join)

These permissions must be:
- Configured as Application permissions (not Delegated)
- Granted admin consent by a Global Administrator
- Associated with a valid client secret

Press Ctrl+C to cancel if these permissions are not configured.
"@

Write-Host $warningMessage -ForegroundColor Yellow

Start-Sleep -Seconds 5

# Ensure we're running with the right execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Install NuGet if not already installed
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

# Install required script if not already installed
if (-not (Get-InstalledScript -Name Get-WindowsAutoPilotInfo -ErrorAction SilentlyContinue)) {
    Install-Script -Name Get-WindowsAutoPilotInfo -Force
}

# Define the path to the PSD1 file using the script's location
$scriptPath = $PSScriptRoot
if (-not $scriptPath) {
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
$psdFilePath = Join-Path $scriptPath "secrets.psd1"

# Initialize variables
$config = $null
$secretsValid = $false
$validationResults = $null

# Try to get existing secrets or create new ones
do {
    if (Test-Path -Path $psdFilePath) {
        try {
            # Import encrypted secrets
            $importedSecrets = Import-Clixml -Path $psdFilePath
            $config = @{
                TenantID = $importedSecrets.TenantID
                ClientID = $importedSecrets.ClientID
                ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($importedSecrets.ClientSecret)
                )
            }
            
            # Test if secrets are valid
            $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
            $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
            
            if ($secretsValid) {
                # Get tenant name from Graph API
                $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
            }
            
            if (-not $secretsValid) {
                Write-Warning "Current secrets are invalid or expired. Let's create new ones."
                $config = New-SecretsFile -FilePath $psdFilePath
                $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
                $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
                if ($secretsValid) {
                    $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
                }
            }
        }
        catch {
            Write-Warning "Failed to import existing secrets: $_"
            $config = New-SecretsFile -FilePath $psdFilePath
            $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
            $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
            if ($secretsValid) {
                $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
            }
        }
    }
    else {
        $config = New-SecretsFile -FilePath $psdFilePath
        $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
        $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
        if ($secretsValid) {
            $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
        }
    }
    
    if (-not $secretsValid) {
        Write-Warning "Credentials validation failed. Please try again."
    }
} while (-not $secretsValid)

# Show initialization report with validation results
Show-InitializationReport -TenantName $tenantName -TenantID $config.TenantID -ClientID $config.ClientID -ValidationResults $validationResults

# Extract parameters from the config
$TenantID = $config.TenantID
$ClientID = $config.ClientID
$ClientSecret = $config.ClientSecret

# Get the path to the installed script
$installedScript = Get-InstalledScript -Name Get-WindowsAutoPilotInfo
if (-not $installedScript) {
    Write-Error "Get-WindowsAutoPilotInfo script not found. Please ensure it was installed correctly."
    exit 1
}

Write-Host "Using Get-WindowsAutoPilotInfo from: $($installedScript.InstalledLocation)" -ForegroundColor Green

# Create parameter hashtable for splatting
$params = @{
    Online = $true
    TenantId = $TenantID
    AppId = $ClientID
    AppSecret = $ClientSecret
}

# Execute the script with splatted parameters
try {
    & "$($installedScript.InstalledLocation)\Get-WindowsAutoPilotInfo.ps1" @params
} catch {
    Write-Error "Failed to execute Get-WindowsAutoPilotInfo: $_"
    exit 1
}

$nextStepsMessage = @"

[Next Steps]
1. Go to Endpoint Manager Portal > Devices > Windows > Windows enrollment > Devices (https://intune.microsoft.com/#view/Microsoft_Intune_Enrollment/AutopilotDevices.ReactView/filterOnManualRemediationRequired~/false)
2. Look for this device in the Windows Autopilot devices list (can take 15-30 minutes to appear)
3. Ensure an Autopilot deployment profile is assigned to the device
4. Restart the computer - you should see your company branding on the login screen

For User-Driven deployment:
- The user can now sign in and the device will be automatically configured
- To generate a Temp Access Pass, use Entra ID > Users > Authentication methods > Temp Access Pass

For Pre-Provisioning:
- Boot to Windows PE or use Autopilot Pre-provisioning (formally known as White Glove)
- Follow the OOBE process with the provided administrative credentials

Note: This script uses Autopilot v1 enrollment. For Autopilot Device Prep (v2.0), different steps are required.
"@

Write-Host $nextStepsMessage -ForegroundColor Cyan
