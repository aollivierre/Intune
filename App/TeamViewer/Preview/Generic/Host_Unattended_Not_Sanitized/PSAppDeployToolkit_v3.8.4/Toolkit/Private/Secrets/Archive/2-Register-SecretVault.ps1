# $pass = Read-Host -AsSecureString -Prompt 'Enter the extension vault password'
# $passwordPath = Join-Path (Split-Path $profile) SecretStore.vault.credential
# # Uses the DPAPI to encrypt the password
# $pass | Export-CliXml $passwordPath
 
# $pass = Import-CliXml $passwordPath
 

# Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Password $pass -Confirm:$false
 
# Register-SecretVault -Name "CCISecretStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault
 
# Unlock-SecretStore -Password $pass








# $Credential = Get-Credential
# $Credentials = Read-Host -AsSecureString -Prompt 'Enter the extension vault password'


$passwordPath = $null
$passwordPath = Join-Path (Split-Path $profile) SecretStore.vault.credential
$Credentials | Export-Clixml -Path $passwordPath
Get-Content $passwordPath

# $Credentials = Import-CliXml -Path ./cred_vault.xml
$Credentials = Import-CliXml -Path $passwordPath









$Credentials = $ClientSecret
$Credentials 




$pass = (ConvertTo-SecureString -String $Credentials.Password -AsPlainText -Force)


Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Password $pass -Confirm:$false
 
Register-SecretVault -Name "CCISecretStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault

Unlock-SecretStore -Password $pass