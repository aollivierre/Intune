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


    Set-AzKeyVaultSecret : Operation returned an invalid status code 'Forbidden'
Code: Forbidden
Message: The policy requires the caller 
'appid=4d80ad41-b02b-4465-9e60-a83e24fcd64f;oid=a64289cc-d7e7-4018-a8e3-6b6036ae54ce;iss=https://sts.windows.net/dc3227a4-53ba-48f1-b54b-89936cd5ca53/' to use on-behalf-of (OBO) flow.     
For more information on OBO, please see https://go.microsoft.com/fwlink/?linkid=2152310
At C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Private\AzKeyVault\4-Set-AzKeyVaultSecret.ps1:21 char:11
+ $secret = Set-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -Name " ...
+           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [Set-AzKeyVaultSecret], KeyVaultErrorException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.KeyVault.SetAzureKeyVaultSecret




Set-AzKeyVaultSecret : 'secretName' does not match expected pattern '^[0-9a-zA-Z-]+$'.
At C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Private\AzKeyVault\4-Set-AzKeyVaultSecret.ps1:68 char:41
+ ... cretvalue = Set-AzKeyVaultSecret -VaultName "$AzKeyVault_Name_1" -Nam ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [Set-AzKeyVaultSecret], ValidationException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.KeyVault.SetAzureKeyVaultSecret

#>



#! Make sure you run the Set-AzKeyVaultAccessPolicy to give the service principal access on the Az Key Vault
#! make sure that you do not have an "Authorized application" selected in any of them, and use a service principal to access the secret rather than an application.

# https://docs.microsoft.com/en-us/answers/questions/117610/how-to-fix-34the-policy-requires-the-caller-3939-t.html

# First convert the value of hVFkk965BuUv to a secure string by typing:
# $secretvalue = ConvertTo-SecureString "secret123!@#" -AsPlainText -Force


# Then, use the Azure PowerShell Set-AzKeyVaultSecret cmdlet to create a secret in Key Vault called ExamplePassword with the value hVFkk965BuUv :
# $secret = Set-AzKeyVaultSecret -VaultName "AKV001-TeamViewer" -Name "mytopsecrethelloworld" -SecretValue $secretvalue


$AzKeyVault_Name_1= $null
$AzKeyVault_Name_1= 'AKV001-TeamViewer'


$TeamViewer_Teams_Webhook_Value = $null
$TeamViewer_API_Token_Value = $null
$TeamViewer_Custom_ConfigID_Value = $null


$TeamViewer_Teams_Webhook_Value = 'https://canadacomputing.webhook.office.com/webhookb2/55fe0bd5-5db4-4078-b922-005e7117f2ff@dc3227a4-53ba-48f1-b54b-89936cd5ca53/IncomingWebhook/120ed4936cb8422ca1ae604081f3fc0b/bf72cc2b-b88d-4570-afc6-dc785e5e5f80'
$TeamViewer_API_Token_Value = '7757967-7qRfr5r4Voq9MRxS7UKZ'
$TeamViewer_Custom_ConfigID_Value = 'he26pyq'



$TeamViewer_Teams_Webhook_secretvalue = ConvertTo-SecureString "$TeamViewer_Teams_Webhook_Value" -AsPlainText -Force
$TeamViewer_API_Token_secretvalue = ConvertTo-SecureString "$TeamViewer_API_Token_Value" -AsPlainText -Force
$TeamViewer_Custom_ConfigID_secretvalue = ConvertTo-SecureString "$TeamViewer_Custom_ConfigID_Value" -AsPlainText -Force


$TeamViewer_Teams_Webhook_SecretValue_Tags = @{ 'Secret Description' = 'This is a webhook that posts to the #TeamViewer channel in CCI MS Teams'; 'IT' = 'true'}
$TeamViewer_API_Token_SecretValue_Tags = @{ 'Secret Description' = 'This is the API token for the TeamViewer host'; 'IT' = 'true'}
$TeamViewer_Custom_ConfigID_SecretValue_Tags = @{ 'Secret Description' = 'This is the custom config ID for the TeamViewer host'; 'IT' = 'true'}


$TeamViewer_Teams_Webhook_secretvalue = Set-AzKeyVaultSecret -VaultName "$AzKeyVault_Name_1" -Name "001-TeamViewerTeamsWebhook" -SecretValue $TeamViewer_Teams_Webhook_secretvalue -Tags $TeamViewer_Teams_Webhook_SecretValue_Tags

$TeamViewer_API_Token_secretvalue = Set-AzKeyVaultSecret -VaultName "$AzKeyVault_Name_1" -Name "002-TeamViewerAPITOKEN" -SecretValue $TeamViewer_API_Token_secretvalue -Tags $TeamViewer_API_Token_SecretValue_Tags

$TeamViewer_Custom_ConfigID_secretvalue = Set-AzKeyVaultSecret -VaultName "$AzKeyVault_Name_1" -Name "003-TeamViewerCUSTOMCONFIGID" -SecretValue $TeamViewer_Custom_ConfigID_secretvalue -Tags $TeamViewer_Custom_ConfigID_SecretValue_Tags


# Set-Secret -Name "TeamViewer-Teams-Webhook" -Secret 'https://canadacomputing.webhook.office.com/webhookb2/55fe0bd5-5db4-4078-b922-005e7117f2ff@dc3227a4-53ba-48f1-b54b-89936cd5ca53/IncomingWebhook/120ed4936cb8422ca1ae604081f3fc0b/bf72cc2b-b88d-4570-afc6-dc785e5e5f80' -Metadata @{Description ='This is a webhook that posts to the #TeamViewer channel in CCI MS Teams.'}


# Set-Secret -Name "TeamViewer-API_TOKEN_1" -Secret '7757967-7qRfr5r4Voq9MRxS7UKZ' -Metadata @{Description ='This is the API token for the TeamViewer host.'}


# Set-Secret -Name "TeamViewer-CUSTOMCONFIG_ID_1" -Secret 'he26pyq' -Metadata @{Description ='This is the custom config ID for the TeamViewer host.'}

