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

Set-Secret -Name "ClientSecret" -Secret 'g~08Q~h~CMnfGnTaG6CWg5hy.ttoZ9GZFnaYYdfN' -Metadata @{Description = '002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Client Secret.' }


Set-Secret -Name "ClientID" -Secret '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -Metadata @{Description = '002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Client ID.' }

Set-Secret -Name "TenantID" -Secret 'dc3227a4-53ba-48f1-b54b-89936cd5ca53' -Metadata @{Description = '002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Tenant ID.' }





$getMsalTokenSplat = @{
    ClientId     = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
    Scopes       = 'https://graph.microsoft.com/.default'
    RedirectUri  = 'https://login.microsoftonline.com'
    ClientSecret = (ConvertTo-SecureString 'g~08Q~h~CMnfGnTaG6CWg5hy.ttoZ9GZFnaYYdfN' -AsPlainText -Force)
}

$AccessToken = (Get-MsalToken @getMsalTokenSplat).AccessToken
$AccessToken





# AT#1
$connectionDetails = @{
    TenantId          = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'
    ClientId          = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
    ClientCertificate = Get-Item -Path 'Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'
}

# Get-MsalToken @connectionDetails


$AccessToken = (Get-MsalToken @connectionDetails).AccessToken
$AccessToken | clip.exe

# AT#2
#once signed in to Azure using 

Connect-AzAccount
$AccessToken = $null
$AccessToken = (Get-AzAccessToken).Token
$AccessToken | clip.exe



# AT#3 AFTER adding Keyvault API permissions
$connectionDetails = @{
    TenantId          = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'
    ClientId          = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
    ClientCertificate = Get-Item -Path 'Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'
}

$AccessToken = (Get-MsalToken @connectionDetails).AccessToken
$AccessToken | clip.exe



# AT#4 Connect-AzAccount and Get-AzAccesstoken using Cert Thumb print
$Thumbprint = '165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'
$TenantId = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'
$ApplicationId = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
Connect-AzAccount -CertificateThumbprint $Thumbprint -ApplicationId $ApplicationId -Tenant $TenantId -ServicePrincipal

$AccessToken = $null
$AccessToken = (Get-AzAccessToken).Token
$AccessToken | clip.exe



# AT#5 using Scope https://graph.microsoft.com/.default
$connectionDetails = @{
    TenantId          = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'
    ClientId          = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
    Scope             = 'https://graph.microsoft.com/.default'
    ClientCertificate = Get-Item -Path 'Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'
}

$AccessToken = $null
$AccessToken = (Get-MsalToken @connectionDetails).AccessToken
$AccessToken | clip.exe






# AT#6 using Scope https://graph.microsoft.com/.default AFTER giving the service principal RBAC at the Key Vault level but have not changed the permissions model in the Key vault
Clear-MsalTokenCache
$connectionDetails = @{
    TenantId          = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'
    ClientId          = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
    Scope             = 'https://graph.microsoft.com/.default'
    ClientCertificate = Get-Item -Path 'Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'
}

$AccessToken = $null
$AccessToken = (Get-MsalToken @connectionDetails).AccessToken
$AccessToken | clip.exe
$AccessToken


$AccountId = $null
$AccountId = 'Admin-Abdullah@canadacomputing.ca'
$TenantID = $null
$TenantID = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

$connectAzAccountSplat = $null
$connectAzAccountSplat = @{
    AccessToken = $AccessToken
    AccountId   = $AccountId
    # GraphAccessToken = $graphToken_3001.AccessToken
    Tenant      = $TenantID
}

Connect-AzAccount @connectAzAccountSplat




https://vault.azure.net
$queryUrl = "https://$vaultName.vault.azure.net/keys" + '?api-version=2016-10-01'



# AT#7 using Scope https://graph.microsoft.com/.default AFTER giving the service principal RBAC at the Key Vault level but have not changed the permissions model in the Key vault with PIPING

<#
.SYNOPSIS
    Acquire a token using MSAL.NET library.
.DESCRIPTION
    This command will acquire OAuth tokens for both public and confidential clients. Public clients authentication can be interactive, integrated Windows auth, or silent (aka refresh token authentication).
.EXAMPLE
    PS C:\>Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -Scope 'https://graph.microsoft.com/User.Read','https://graph.microsoft.com/Files.ReadWrite'
    Get AccessToken (with MS Graph permissions User.Read and Files.ReadWrite) and IdToken using client id from application registration (public client).
.EXAMPLE
    PS C:\>Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId '00000000-0000-0000-0000-000000000000' -Interactive -Scope 'https://graph.microsoft.com/User.Read' -LoginHint user@domain.com
    Force interactive authentication to get AccessToken (with MS Graph permissions User.Read) and IdToken for specific Azure AD tenant and UPN using client id from application registration (public client).
.EXAMPLE
    PS C:\>Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -ClientSecret (ConvertTo-SecureString 'SuperSecretString' -AsPlainText -Force) -TenantId '00000000-0000-0000-0000-000000000000' -Scope 'https://graph.microsoft.com/.default'
    Get AccessToken (with MS Graph permissions .Default) and IdToken for specific Azure AD tenant using client id and secret from application registration (confidential client).
.EXAMPLE
    PS C:\>$ClientCertificate = Get-Item Cert:\CurrentUser\My\0000000000000000000000000000000000000000
    PS C:\>$MsalClientApplication = Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -ClientCertificate $ClientCertificate -TenantId '00000000-0000-0000-0000-000000000000'
    PS C:\>$MsalClientApplication | Get-MsalToken -Scope 'https://graph.microsoft.com/.default'
    Pipe in confidential client options object to get a confidential client application using a client certificate and target a specific tenant.
#>



# TenantId          = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'
# ClientId          = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
# Scope             = 'https://graph.microsoft.com/.default'
# ClientCertificate = Get-Item -Path 'Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'


Clear-MsalTokenCache
$AccessToken = $null
$ClientCertificate = $null
$MsalClientApplication = $null

$ClientCertificate = Get-Item Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d
$MsalClientApplication = Get-MsalClientApplication -ClientId '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -ClientCertificate $ClientCertificate -TenantId 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

$AccessToken = ($MsalClientApplication | Get-MsalToken -Scope 'https://graph.microsoft.com/.default').AccessToken
$AccessToken | clip.exe
$AccessToken







# AT#8 using Scope https://graph.microsoft.com/.default AFTER giving the service principal RBAC at the Key Vault level AND changed the permissions model in the Key vault to RBAC instead of Access Policies

# WARNING: Unable to acquire token for tenant 'organizations' with error 'Authentication failed.'
# connect-AzAccount : Authentication failed.
# At line:1 char:1
# + connect-AzAccount -accessToken $AccessToken -AccountId "Admin-Abdulla ...
# + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : CloseError: (:) [Connect-AzAccount], CloudException
#     + FullyQualifiedErrorId : Microsoft.Azure.Commands.Profile.ConnectAzureRmAccountCommand
 

$ClientCertificate = Get-Item Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d
$MsalClientApplication = Get-MsalClientApplication -ClientId '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -ClientCertificate $ClientCertificate -TenantId 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

$AccessToken = $null
$AccessToken = ($MsalClientApplication | Get-MsalToken -Scope 'https://graph.microsoft.com/.default').AccessToken
$AccessToken | clip.exe

$AccountId = $null
$AccountId = 'Admin-Abdullah@canadacomputing.ca'
$TenantID = $null
$TenantID = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

$connectAzAccountSplat = $null
$connectAzAccountSplat = @{
    AccessToken = $AccessToken
    AccountId   = $AccountId
    # GraphAccessToken = $graphToken_3001.AccessToken
    Tenant      = $TenantID
}

Connect-AzAccount @connectAzAccountSplat







#AT #9

# WARNING: The access token has been obtained for wrong audience or resource 'https://vault.azure.net'. It should exactly match with one of the allowed audiences 
# 'https://management.core.windows.net/','https://management.core.windows.net','https://management.azure.com/','https://management.azure.com'.
# Connect-AzAccount : The access token has been obtained for wrong audience or resource 'https://vault.azure.net'. It should exactly match with one of the allowed audiences 
# 'https://management.core.windows.net/','https://management.core.windows.net','https://management.azure.com/','https://management.azure.com'.
# At line:1 char:1
# + Connect-AzAccount @connectAzAccountSplat
# + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : CloseError: (:) [Connect-AzAccount], CloudException
#     + FullyQualifiedErrorId : Microsoft.Azure.Commands.Profile.ConnectAzureRmAccountCommand

$ClientCertificate = Get-Item Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d
$MsalClientApplication = Get-MsalClientApplication -ClientId '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -ClientCertificate $ClientCertificate -TenantId 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

$AccessToken = $null
$AccessToken = ($MsalClientApplication | Get-MsalToken -Scope 'https://vault.azure.net/.default').AccessToken
$AccessToken | clip.exe

$AccountId = $null
$AccountId = 'Admin-Abdullah@canadacomputing.ca'
$TenantID = $null
$TenantID = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

$connectAzAccountSplat = $null
$connectAzAccountSplat = @{
    AccessToken = $AccessToken
    AccountId   = $AccountId
    # GraphAccessToken = $graphToken_3001.AccessToken
    Tenant      = $TenantID
}

Connect-AzAccount @connectAzAccountSplat





#AT #10


$ClientCertificate = Get-Item Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d
$MsalClientApplication = Get-MsalClientApplication -ClientId '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -ClientCertificate $ClientCertificate -TenantId 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

$AccessToken = $null
$AccessToken = ($MsalClientApplication | Get-MsalToken -Scope 'https://AKV001-TeamViewer.vault.azure.net/.default').AccessToken
$AccessToken | clip.exe
