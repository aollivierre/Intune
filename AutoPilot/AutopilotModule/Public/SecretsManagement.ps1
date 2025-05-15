# Secrets management functions

function New-SecretsFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    Write-Host "`nNo secrets file found or current secrets are invalid. Let's create one!" -ForegroundColor Yellow
    Write-Host "Please enter the following information:" -ForegroundColor Cyan
    
    $tenantId = Read-Host -Prompt "Enter your Tenant ID"
    $clientId = Read-Host -Prompt "Enter your Application (Client) ID"
    $clientSecret = Get-SecureInput -Prompt "Enter your Client Secret"
    
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

function Import-SecretsFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        try {
            # Import encrypted secrets from JSON
            $importedSecrets = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
            
            # Decrypt the values
            $config = @{
                TenantID = Unprotect-String -EncryptedString $importedSecrets.TenantID
                ClientID = Unprotect-String -EncryptedString $importedSecrets.ClientID
                ClientSecret = Unprotect-String -EncryptedString $importedSecrets.ClientSecret
            }
            
            return $config
        }
        catch {
            Write-Warning "Failed to import secrets file: $_"
            return $null
        }
    }
    else {
        Write-Warning "Secrets file does not exist: $FilePath"
        return $null
    }
}

function Get-ValidSecrets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $config = $null
    $secretsValid = $false
    $validationResults = $null
    $tenantName = "Unknown Tenant"
    
    if (Test-Path -Path $FilePath) {
        try {
            # Import secrets
            $config = Import-SecretsFile -FilePath $FilePath
            
            # Test if secrets are valid
            $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
            $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
            
            if ($secretsValid) {
                # Get tenant name from Graph API
                $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
            }
            
            if (-not $secretsValid) {
                Write-Warning "Current secrets are invalid or expired. Let's create new ones."
                $config = New-SecretsFile -FilePath $FilePath
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
            $config = New-SecretsFile -FilePath $FilePath
            $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
            $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
            if ($secretsValid) {
                $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
            }
        }
    }
    else {
        Write-Host "No secrets file found. Creating new one..." -ForegroundColor Yellow
        $config = New-SecretsFile -FilePath $FilePath
        $validationResults = Test-SecretsValidity -TenantID $config.TenantID -ClientID $config.ClientID -ClientSecret $config.ClientSecret
        $secretsValid = $validationResults.TokenValid -and $validationResults.PermissionsValid
        if ($secretsValid) {
            $tenantName = Get-TenantDetails -TenantID $config.TenantID -AccessToken $validationResults.AccessToken
        }
    }
    
    return @{
        Config = $config
        SecretsValid = $secretsValid
        ValidationResults = $validationResults
        TenantName = $tenantName
    }
}

# Export functions to make them available within the module
Export-ModuleMember -Function New-SecretsFile, Import-SecretsFile, Get-ValidSecrets
