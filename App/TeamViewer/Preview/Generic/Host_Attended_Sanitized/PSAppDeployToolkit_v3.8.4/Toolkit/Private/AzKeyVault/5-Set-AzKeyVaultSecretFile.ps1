<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>



$path = 'C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Public\Settings\teamviewer_settings_export-v3.tvopt'

# Set-AzureKeyVaultSecret -VaultName MyKeyVault -SecretName rootca -SecretValue (ConvertTo-SecureString (Get-Content C:\test\rootCA.cer -Raw) -force -AsPlainText )
# Set-AzureKeyVaultSecret -VaultName MyKeyVault -SecretName rootca -SecretValue (ConvertTo-SecureString (Get-Content $path -Raw) -force -AsPlainText )
Set-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -SecretName '004-TeamViewerSettings' -SecretValue (ConvertTo-SecureString (Get-Content $path -Raw) -force -AsPlainText )