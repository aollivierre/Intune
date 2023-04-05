<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'


Module dependencies
IntuneWin32App module requires the following modules, which will be automatically installed as dependencies:

MSAL.PS
Authentication
In the previous versions of this module, the functions that interact with Microsoft Intune (essentially query the Graph API for resources), used have common parameters that required input on a per function basis. With the release of version 1.2.0 and going forward, the IntuneWin32App module replaces these common parameter requirements and replaces them with a single function, Connect-MSIntuneGraph, to streamline the authentication token retrieval with other modules and how they work.

Before using any of the functions within this module that interacts with Graph API, ensure that an authentication token is acquired using the following command:
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.

    https://github.com/MSEndpointMgr/IntuneWin32App#module-dependencies
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines



    expected output

Name                           Value
----                           -----
Authorization                  Bearer 'your access token'...
Content-Type                   application/json
ExpiresOn                      2022-07-24 2:08:50 AM

#>



Connect-MSIntuneGraph -TenantID "canadacomputing.onmicrosoft.com"
