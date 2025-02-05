# https://andrewstaylor.com/2023/06/13/authenticating-to-new-get-windowsautopilotinfo/

# Copy script to temp directory for portability at the start
$tempScriptPath = Join-Path $env:TEMP "Get-WindowsAutopilotinfowithAppreg.ps1"
try {
    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $tempScriptPath -Force
    Write-Host "Script copied to: $tempScriptPath" -ForegroundColor Green
    Write-Host "You can safely remove the USB drive and use the script from the temp location." -ForegroundColor Green
}
catch {
    Write-Warning "Failed to copy script to temp directory: $_"
}

$script:Version = "1.1.0"

# Function to encrypt string with portable encryption
function Protect-String {
    param(
        [string]$String
    )
    
    $secureString = ConvertTo-SecureString -String $String -AsPlainText -Force
    $encrypted = $secureString | ConvertFrom-SecureString -Key (1..16)
    return $encrypted
}

# Function to decrypt string with portable encryption
function Unprotect-String {
    param(
        [string]$EncryptedString
    )
    
    try {
        $secureString = ConvertTo-SecureString -String $EncryptedString -Key (1..16)
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    finally {
        if ($BSTR) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
}

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

# Function to get app registration details
function Get-AppRegistrationDetails {
    param (
        [string]$ClientID,
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

# Function to test client secret validity
function Test-ClientSecretValidity {
    param (
        [string]$ClientID,
        [string]$ClientSecret
    )
    
    try {
        $result = @{
            IsValid = $false
            ExpiryDate = $null
            Error = $null
        }

        # Try to decode the secret to get its expiry (if possible)
        if ($ClientSecret -match '^[A-Za-z0-9+/=]+$') {
            try {
                $decodedBytes = [System.Convert]::FromBase64String($ClientSecret)
                $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
                if ($decodedText -match 'exp=(\d+)') {
                    $expiryTimestamp = [int]$matches[1]
                    $result.ExpiryDate = (Get-Date "1970-01-01").AddSeconds($expiryTimestamp)
                }
            }
            catch {
                # Ignore decoding errors
            }
        }

        # Test the secret by attempting to get a token
        $url = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
        $body = @{
            grant_type = "client_credentials"
            client_id = $ClientID
            client_secret = $ClientSecret
            scope = "https://graph.microsoft.com/.default"
        }
        
        $response = Invoke-RestMethod -Method Post -Uri $url -Body $body -ContentType "application/x-www-form-urlencoded"
        $result.IsValid = $true
        
        return $result
    }
    catch {
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Show-InitializationReport {
    param (
        [string]$TenantName,
        [string]$TenantID,
        [string]$ClientID,
        [hashtable]$ValidationResults,
        [hashtable]$AppDetails,
        [hashtable]$SecretValidation
    )
    
    $horizontalLine = "=" * 80
    Write-Host $horizontalLine -ForegroundColor Cyan
    Write-Host "Windows Autopilot Device Registration Script v$script:Version" -ForegroundColor Cyan
    Write-Host $horizontalLine -ForegroundColor Cyan
    Write-Host "Purpose: Register this device with Windows Autopilot in your Intune tenant"
    Write-Host "Script Location: $PSScriptRoot"
    Write-Host "Temp Script Location: $tempScriptPath"
    Write-Host "Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""
    Write-Host "Application Details:" -ForegroundColor Yellow
    if ($AppDetails) {
        Write-Host "- App Name: $($AppDetails.DisplayName)"
        Write-Host "- App ID: $($AppDetails.AppId)"
        Write-Host "- Created: $($AppDetails.CreatedDateTime)"
    } else {
        Write-Host "- App Details: Not available (insufficient permissions)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Connection Parameters:" -ForegroundColor Yellow
    Write-Host "- Tenant Name: $TenantName"
    Write-Host "- Tenant ID: $TenantID"
    Write-Host ""
    Write-Host "Credential Validation Results:" -ForegroundColor Yellow
    Write-Host "- Access Token Valid: $($ValidationResults.TokenValid)" -ForegroundColor $(if ($ValidationResults.TokenValid) { 'Green' } else { 'Red' })
    Write-Host "- Token Expiration: $($ValidationResults.TokenExpiration)" -ForegroundColor $(if ($ValidationResults.TokenValid) { 'Green' } else { 'Red' })
    Write-Host "- Required Permissions Present: $($ValidationResults.PermissionsValid)" -ForegroundColor $(if ($ValidationResults.PermissionsValid) { 'Green' } else { 'Red' })
    if ($SecretValidation.ExpiryDate) {
        Write-Host "- Client Secret Expires: $($SecretValidation.ExpiryDate)" -ForegroundColor $(if ($SecretValidation.ExpiryDate -gt (Get-Date)) { 'Green' } else { 'Red' })
    }
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
    
    # Convert SecureString to plain text for encryption
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)
    $plainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    # Create object with encrypted values
    $secretsObject = "@{`n"
    $secretsObject += "    TenantID = `"$(Protect-String -String $tenantId)`"`n"
    $secretsObject += "    ClientID = `"$(Protect-String -String $clientId)`"`n"
    $secretsObject += "    ClientSecret = `"$(Protect-String -String $plainSecret)`"`n"
    $secretsObject += "}"
    
    try {
        $secretsObject | Out-File -FilePath $FilePath -Force -Encoding UTF8
        Write-Host "Secrets file created successfully!" -ForegroundColor Green
        
        # Return plain text version for immediate use
        return @{
            TenantID = $tenantId
            ClientID = $clientId
            ClientSecret = $plainSecret
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
            },
            @{
                Name = "Organization.Read.All"
                Endpoint = "https://graph.microsoft.com/v1.0/organization"
                Method = "GET"
            },
            @{
                Name = "Application.Read.All"
                Endpoint = "https://graph.microsoft.com/v1.0/applications"
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
[WARNING] Before proceeding, ensure your Entra ID App Registration has the following Microsoft Graph API permissions:

Required Application Permissions (NOT Delegated):
1. DeviceManagementServiceConfig.ReadWrite.All
   - Purpose: Read and write Windows Autopilot deployment configurations
   - Type: Application
   - Required: Yes

2. Device.ReadWrite.All
   - Purpose: Create and manage device objects
   - Type: Application
   - Required: Yes

3. DeviceManagementManagedDevices.ReadWrite.All
   - Purpose: Read and write Microsoft Intune managed devices
   - Type: Application
   - Required: Yes

4. Organization.Read.All
   - Purpose: Read organization information (tenant details)
   - Type: Application
   - Required: Yes

5. Application.Read.All
   - Purpose: Read application information (app registration details)
   - Type: Application
   - Required: Yes

Optional Application Permissions (NOT Delegated):
6. Group.ReadWrite.All
   - Purpose: Manage group assignments for devices
   - Type: Application
   - Required: Only if using group assignments

7. Domain.ReadWrite.All
   - Purpose: Manage domain settings for hybrid join
   - Type: Application
   - Required: Only if using hybrid Azure AD join

Important Notes:
- ALL permissions must be configured as Application permissions (NOT Delegated)
- Admin consent MUST be granted for all permissions
- A valid client secret with sufficient expiry time is required
- Global Administrator rights needed for granting admin consent

Press Ctrl+C to cancel if these permissions are not configured.
"@

Write-Host $warningMessage -ForegroundColor Yellow

Start-Sleep -Seconds 5

# Ensure we're running with the right execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Set TLS 1.2 for compatibility
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install NuGet silently if not already installed
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
    Write-Host "Installing NuGet provider..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -ForceBootstrap -Force -Confirm:$false | Out-Null
    Write-Host "NuGet provider installed successfully." -ForegroundColor Green
}

# Install required script if not already installed
if (-not (Get-InstalledScript -Name Get-WindowsAutoPilotInfo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Get-WindowsAutoPilotInfo script..." -ForegroundColor Yellow
    Install-Script -Name Get-WindowsAutoPilotInfo -Force -Scope CurrentUser -Confirm:$false
    Write-Host "Get-WindowsAutoPilotInfo script installed successfully." -ForegroundColor Green
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
            # Import encrypted secrets from JSON
            $importedSecrets = Get-Content -Path $psdFilePath -Raw | ConvertFrom-Json
            
            # Decrypt the values
            $config = @{
                TenantID = Unprotect-String -EncryptedString $importedSecrets.TenantID
                ClientID = Unprotect-String -EncryptedString $importedSecrets.ClientID
                ClientSecret = Unprotect-String -EncryptedString $importedSecrets.ClientSecret
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
            Write-Host "Creating new secrets file..." -ForegroundColor Yellow
            $config = New-SecretsFile -FilePath $psdFilePath
            $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
            $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
            if ($secretsValid) {
                $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
            }
        }
    }
    else {
        Write-Host "No secrets file found. Creating new one..." -ForegroundColor Yellow
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

# After getting valid credentials, get app details and test secret
if ($secretsValid) {
    $appDetails = Get-AppRegistrationDetails -ClientID $config.ClientID -AccessToken $validationResults.AccessToken
    $secretValidation = Test-ClientSecretValidity -ClientID $config.ClientID -ClientSecret $config.ClientSecret
}

# Show initialization report with all details
Show-InitializationReport -TenantName $tenantName -TenantID $config.TenantID -ClientID $config.ClientID `
    -ValidationResults $validationResults -AppDetails $appDetails -SecretValidation $secretValidation

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

# After successful execution, add reboot countdown
if ($?) {
    Write-Host "`nDevice registration successful!" -ForegroundColor Green
    Write-Host "System will reboot in 10 seconds to apply changes..." -ForegroundColor Yellow
    
    # Countdown display
    10..1 | ForEach-Object {
        Write-Host "Rebooting in $_ seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    
    # Initiate reboot
    Restart-Computer -Force
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
