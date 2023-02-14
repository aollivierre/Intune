<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'


    Version    Name                                Repository           Description
-------    ----                                ----------           -----------
4.6.1      Az.KeyVault                         PSGallery            Microsoft Azure PowerShell - Key Vault service cmdlets for Azure Resource Manager in Windows PowerShell and PowerShell Core....     
1.0.6      Microsoft.PowerShell.SecretStore    PSGallery            This PowerShell module is an extension vault for the PowerShell SecretManagement module....
0.9.2      SecretManagement.KeePass            PSGallery            A cross-platform Keepass Secret Management vault extension. See the README.MD in the module for more details.
2.0.0      SecretManagement.Hashicorp.Vault.KV PSGallery            A PowerShell SecretManagement extension for Hashicorp Vault Key Value Engine
0.1.1      SecretManagement.BitWarden          PSGallery            SecretManagement extension for BitWarden!
0.2.1      SecretManagement.LastPass           PSGallery            SecretManagement extension for LastPass!
0.3        SecretManagement.CyberArk           PSGallery            SecretManagement extension for CyberArk
0.1.3      SecretManagement.KeyChain           PSGallery            SecretManagement extension vault for macOS KeyChain
0.0.4.6    SecretManagement.1Password          PSGallery            SecretManagement extension for 1Password
16.3.3     SecretManagement.Keeper             PSGallery            SecretManagement extension vault for Keeper
1.3.0      SecretManagement.Keybase            PSGallery            Keybase Secret Management Extension
0.0.9.1    SecretManagement.Chromium           PSGallery            A cross-platform Chromium (Edge/Chrome) Secret Management vault extension. See the README.MD in the module for more details.        
1.0.435    SecretManagement.PleasantPasswor... PSGallery            A cross-platform Pleasent Password Server Secret Management vault extension. See the README.MD in the module for more details.      
0.3.0      SecretManagement.DevolutionsHub     PSGallery            Secret management extension for Devolutions Hub
2.0.1      PersonalVault                       PSGallery            Module to manage secrets in easy and efficient way.
0.2        SecretManagement.DevolutionsServer  PSGallery            Secret management extension for Devolutions Server
0.0.1      SecretManagement.LAPS               PSGallery            SecretManagement extension for Microsoft's Local Administrator Password Solution

.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


find-module -Tag SecretManagement


Install-Module Microsoft.PowerShell.SecretManagement -Repository PSGallery
Install-Module Microsoft.PowerShell.SecretStore -Repository PSGallery



Get-SecretStoreConfiguration


# Register-SecretVault -Name "MyFirstSecretStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault
Register-SecretVault -Name "CCISecretStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault


Set-SecretStoreConfiguration -Authentication 'None'


Set-Secret -Name "BestKeptSecret" -Secret "Pineapple on pizza is great!"


Get-Secret -Name "BestKeptSecret" -AsPlainText



Set-Secret -Name "TeamViewer-Teams-Webhook" -Secret 'https://canadacomputing.webhook.office.com/webhookb2/55fe0bd5-5db4-4078-b922-005e7117f2ff@dc3227a4-53ba-48f1-b54b-89936cd5ca53/IncomingWebhook/120ed4936cb8422ca1ae604081f3fc0b/bf72cc2b-b88d-4570-afc6-dc785e5e5f80' -Metadata @{Description ='This is a webhook that posts to the #TeamViewer channel in CCI MS Teams.'}



# Set-Secret -Name "DiscordWebhook" -Secret 'https://discord.com/api/webhooks/123456789/xxxxxxxx' -Metadata @{Description ='This is a webhook that posts to the #general channel in my discord server.'}


Get-secretinfo | select-object


Get-Secret -Name "DiscordWebhook" -AsPlainText

Get-Secret -Name "TeamViewer-Teams-Webhook" -AsPlainText



$pass = Read-Host -AsSecureString -Prompt 'Enter the extension vault password'
$passwordPath = Join-Path (Split-Path $profile) SecretStore.vault.credential
# Uses the DPAPI to encrypt the password
$pass | Export-CliXml $passwordPath
 
 
# Install-Module -Name Microsoft.PowerShell.SecretStore, Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force:$true
 
$pass = Import-CliXml $passwordPath
 
# Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Password $pass -Confirm:$false
Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Password $pass -Confirm:$false

# Set-SecretStorePassword -NewPassword $newPassword -Password $oldPassword

# Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Confirm:$false

# Set-SecretStoreConfiguration -Scope CurrentUser -Authentication None
 
Register-SecretVault -Name "CCISecretStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault
 
Unlock-SecretStore -Password $pass



$pass = Import-CliXml 'C:\Users\username\Documents\PowerShell\SecretStore.vault.credential'
 
Unlock-SecretStore -Password $pass



# Reset-SecretStore -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Password $pass -Confirm:$false -Force:$true
Reset-SecretStore -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Confirm:$false -Force:$true




Get-SecretVault | Unregister-SecretVault
Get-SecretVault












# Create Microsoft 365 Credential Secret
$username = "admin@domain.onmicrosoft.com"
$password = ConvertTo-SecureString "Pass@word1" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($username,$password)
# Create the secret by storing the PSCredential object
Set-Secret -Name M365 -Secret $cred -Metadata @{Information="M365 Credentials for Tenant"}
# Retrieve the Stored Credentials
$m365creds = Get-Secret -Name M365Creds
# Connect to Microsoft Online with the retrieved credentials
Connect-MsolService -Credential $m365creds