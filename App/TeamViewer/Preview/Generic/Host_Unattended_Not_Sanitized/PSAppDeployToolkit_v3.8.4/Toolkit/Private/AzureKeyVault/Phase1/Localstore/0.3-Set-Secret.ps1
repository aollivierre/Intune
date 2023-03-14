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

Set-Secret -Name "ClientSecret" -Secret 'g~08Q~h~CMnfGnTaG6CWg5hy.ttoZ9GZFnaYYdfN' -Metadata @{Description ='002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Client Secret.'}


Set-Secret -Name "ClientID" -Secret '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -Metadata @{Description ='002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Client ID.'}

Set-Secret -Name "TenantID" -Secret 'dc3227a4-53ba-48f1-b54b-89936cd5ca53' -Metadata @{Description ='002 - Azure Key Vault - TeamViewer - Service Principal - PowerShell Automation - Tenant ID.'}
