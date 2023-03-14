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


find-module -Tag SecretManagement


Install-Module Microsoft.PowerShell.SecretManagement -Repository PSGallery
Install-Module Microsoft.PowerShell.SecretStore -Repository PSGallery



#or 


Install-Module -Name Microsoft.PowerShell.SecretStore, Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force:$true