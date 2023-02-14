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



    New-Object : Cannot find an overload for "PSCredential" and the argument count: "2".
At C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Private\AzKeyVault\0.6-Connect-AzAccount.ps1:63 char:15
+ ... redential = New-Object -TypeName System.Management.Automation.PSCrede ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [New-Object], MethodException
    + FullyQualifiedErrorId : ConstructorInvokedThrowException,Microsoft.PowerShell.Commands.NewObjectCommand



    Connect-AzAccount : Cannot bind argument to parameter 'Credential' because it is null.
At C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Private\AzKeyVault\0.6-Connect-AzAccount.ps1:64 char:69
+ ... Account -ServicePrincipal -TenantId $TenantId -Credential $Credential
+                                                               ~~~~~~~~~~~
    + CategoryInfo          : InvalidData: (:) [Connect-AzAccount], ParameterBindingValidationException
    + FullyQualifiedErrorId : ParameterArgumentValidationErrorNullNotAllowed,Microsoft.Azure.Commands.Profile.ConnectAzureRmAccountCommand

#>


# Connect-AzAccount


$Connect_AzAccount_Script_Root_1 = $null
$Connect_AzAccount_Script_Root_1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}



# ."$Connect_AzAccount_Script_Root_1\Decrypt-Secret.ps1"
."$Connect_AzAccount_Script_Root_1\Import-TeamViewerSecretStore.ps1"

Disconnect-AzAccount

# $ClientID = Decrypt-Secret -Description 'ClientID'
# $TenantId = Decrypt-Secret -Description 'TenantId'
# $ClientSecret = Decrypt-Secret -Description 'ClientSecret'

# $ClientSecret = ConvertTo-SecureString "$ClientSecret" -AsPlainText -Force:$true

# $ClientID
# $TenantId
# $ClientSecret


Import-TeamViewerSecretStore

$ClientSecret = $null
$ClientSecret = Get-Secret 'ClientSecret'


$ClientID = $null
$ClientID = Get-Secret 'ClientID' -AsPlainText


$TenantID = $null
$TenantID = Get-Secret 'TenantID' -AsPlainText


# $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientID, $ClientSecret
# Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

# Account                SubscriptionName TenantId                Environment
# -------                ---------------- --------                -----------
# xxxx-xxxx-xxxx-xxxx    Subscription1    xxxx-xxxx-xxxx-xxxx     AzureCloud



# Connect-AzAccount -AccessToken $AccessToken -AccountId "Admin-Abdullah@canadacomputing.ca"
# Connect-AzAccount -AccessToken $AccessToken -AccountId "Admin-Abdullah@canadacomputing.ca"




$Thumbprint = '165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'
$TenantId = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'
$ApplicationId = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
Connect-AzAccount -CertificateThumbprint $Thumbprint -ApplicationId $ApplicationId -Tenant $TenantId -ServicePrincipal







