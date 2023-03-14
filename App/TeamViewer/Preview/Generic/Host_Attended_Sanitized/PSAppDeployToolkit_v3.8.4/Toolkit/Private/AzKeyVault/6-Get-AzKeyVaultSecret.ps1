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


# Retrieve a secret from Key Vault
# To view the value contained in the secret as plain text, use the Azure PowerShell Get-AzKeyVaultSecret cmdlet:

# $secret = Get-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -Name "mytopsecrethelloworld" -AsPlainText
$001_TeamViewerTeamsWebhook = Get-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -Name "001-TeamViewerTeamsWebhook" -AsPlainText
$002_TeamViewerAPITOKEN = Get-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -Name "002-TeamViewerAPITOKEN" -AsPlainText
$003_TeamViewerCUSTOMCONFIGID = Get-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -Name "003-TeamViewerCUSTOMCONFIGID" -AsPlainText -Debug:$true
$004_TeamViewerSettings = Get-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -Name "004-TeamViewerSettings" -AsPlainText

$secret1
$secret2
$secret3
$secret4






