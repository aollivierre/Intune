$Register_SecretVault_Script_Root_1 = $null
$Register_SecretVault_Script_Root_1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}



."$Register_SecretVault_Script_Root_1\Decrypt-Secret.ps1"





$ClientSecret = Decrypt-Secret -Description 'SecretStoreCred'
$Credentials = $ClientSecret


$pass = (ConvertTo-SecureString -String $Credentials.Password -AsPlainText -Force)


Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout (60*60) -Interaction None -Password $pass -Confirm:$false
 
# Register-SecretVault -Name "CCISecretStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault
Register-SecretVault -Name "LocalStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault

Unlock-SecretStore -Password $pass