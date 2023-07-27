function Install-RequiredModules {
    # Set up security protocol
    # [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12


    # Check if NuGet package provider is installed
    $NuGetProvider = Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue

    # Install NuGet package provider if not installed
    if (-not $NuGetProvider) {
        Write-Host "NuGet package provider not found. Installing..."
        Install-PackageProvider -Name "NuGet" -Force
    }
    else {
        Write-Host "NuGet package provider is already installed."
    }

    # Install PowerShellGet module if not installed
    $PowerShellGetModule = Get-Module -Name "PowerShellGet" -ListAvailable
    if (-not $PowerShellGetModule) {
        Install-Module -Name "PowerShellGet" -AllowClobber -Force
    }


    # Install-Module -Name PowerShellGet -Repository PSGallery -Force
    # Install-Module -Name PackageManagement -Repository PSGallery -Force
    Get-PSRepository
    # Register-PSRepository -Default

    # Install SecretManagement.KeePass module if not installed or if the version is less than 0.9.2
    $KeePassModule = Get-Module -Name "SecretManagement.KeePass" -ListAvailable
    if (-not $KeePassModule -or ($KeePassModule.Version -lt [System.Version]::new(0, 9, 2))) {
        write-host 'KeePass Module not found.. Installing'
        Install-Module -Name "SecretManagement.KeePass" -RequiredVersion 0.9.2 -Force:$true
        # Install-Module -Name "SecretManagement.KeePass" -Force:$true
    }
}

# Call the function to install the required modules and dependencies
Install-RequiredModules



$VaultName = "Database"
$clientId = "12432e62-ebe9-4e77-9ff8-2aaa1a7734c6"
$clientSecret = "ywO8Q~wKbqlCaavVAAlTv6fR6x2sAvso0Q7P9bHi"
$tenantID = "3c2de8d6-19e3-407f-93a7-92f916f715c8"

function Register-KeePassVault {
    # To securely store the KeePass database credentials, you'll need to register a KeePass vault:
    $VaultName = $VaultName

    $ExistingVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
    if ($ExistingVault) {
        # Set-KeepassSecretVaultConfiguration -Name $VaultName -Path $databaseKdbxPath -KeyPath $databaseKeyxPath

        Write-Host "Keepass $VaultName is already Registered..."
        Unregister-SecretVault -Name $VaultName
        Register-KeePassSecretVault -Name $VaultName -Path $databaseKdbxPath -KeyPath $databaseKeyxPath
    } 
    else {
        Unregister-SecretVault -Name $VaultName
        Register-KeePassSecretVault -Name $VaultName -Path $databaseKdbxPath -KeyPath $databaseKeyxPath
    }
    
}


$toolkitPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$secretsPath = Join-Path $toolkitPath "Secrets"
$databaseKdbxPath = Join-Path $secretsPath "Database.kdbx"
$databaseKeyxPath = Join-Path $secretsPath "Database.keyx"

Register-KeePassVault




function Add-KeePassSecret {
    param(
        [string]$VaultName,
        [string]$EntryName,
        [string]$Username,
        [string]$Password
    )

    $secureUsername = ConvertTo-SecureString -String $Username -AsPlainText -Force
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

    Set-Secret -Name "${EntryName}_Username" -Secret $secureUsername -Vault $VaultName
    Set-Secret -Name "${EntryName}_Password" -Secret $securePassword -Vault $VaultName
}


function Remove-KeePassSecretIfExists {
    param(
        [string]$VaultName,
        [string]$EntryName
    )

    # Check if the secrets exist
    $UsernameSecret = Get-Secret -Name "${EntryName}_Username" -Vault $VaultName -ErrorAction SilentlyContinue
    $PasswordSecret = Get-Secret -Name "${EntryName}_Password" -Vault $VaultName -ErrorAction SilentlyContinue

    # If secrets exist, remove them
    if ($UsernameSecret) {
        Remove-Secret -Name "${EntryName}_Username" -Vault $VaultName
    }
    if ($PasswordSecret) {
        Remove-Secret -Name "${EntryName}_Password" -Vault $VaultName
    }
}




#you can find secrets in the Secrets.secretx file


# $document_drive_name = "Documents"


$SecretsToStore = @(
    @{
        "EntryName" = "ClientId";
        "Username" = "N/A";
        "Password" = $clientId
    },
    @{
        "EntryName" = "ClientSecret";
        "Username" = "N/A";
        "Password" = $clientSecret
    },
    @{
        "EntryName" = "tenantID";
        "Username" = "N/A";
        "Password" = $tenantID
    }
)

foreach ($secret in $SecretsToStore) {
    # Remove existing secrets if they exist
    Remove-KeePassSecretIfExists -VaultName $VaultName -EntryName $secret.EntryName

    # Add new secrets
    Add-KeePassSecret -VaultName $VaultName -EntryName $secret.EntryName -Username $secret.Username -Password $secret.Password
}


function Get-SecretsFromKeePass {
    param (
        [string[]]$KeePassEntryNames
    )
    
    $Secrets = @{}
    
    foreach ($entryName in $KeePassEntryNames) {
        $PasswordSecret = Get-Secret -Name "${EntryName}_Password" -Vault "Database"

        # $DBG
        $SecurePassword = $PasswordSecret
                
        # Convert plain text password to SecureString
        $SecurePasswordString = ConvertTo-SecureString -String $SecurePassword -AsPlainText -Force

        # $DBG
        
        # Convert SecureString back to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSecret)
        $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        # $DBG
        
        $Secrets[$entryName] = @{
            "Username"       = $PasswordSecret.UserName
            "SecurePassword" = $SecurePasswordString
            "PlainText"      = $PlainText
        }
    }
    
    return $Secrets
}

$KeePassEntryNames = $null
$KeePassEntryNames = @("ClientId", "ClientSecret", "tenantID")
$Secrets = Get-SecretsFromKeePass -KeePassEntryNames $KeePassEntryNames

$clientId = $Secrets["ClientId"].PlainText
$clientPlainTextSecret = $Secrets["ClientSecret"].PlainText
$tenantID= $Secrets["TenantID"].PlainText
# $tenantName = $Secrets["TenantName"].PlainText
# $site_objectid = $Secrets["SiteObjectId"].PlainText
# $webhook_url = $Secrets["WebhookUrl"].PlainText


$clientId
$clientPlainTextSecret
$tenantID
# $tenantname
# $site_objectid
# $webhook_url



# Remove variables and clear secrets
Remove-Variable -Name clientId
Remove-Variable -Name clientPlainTextSecret
Remove-Variable -Name tenantID
# Remove-Variable -Name tenantName
# Remove-Variable -Name site_objectid
# Remove-Variable -Name webhook_url

$Secrets.Clear()
Remove-Variable -Name Secrets
# Unregister-SecretVault -Name $VaultName