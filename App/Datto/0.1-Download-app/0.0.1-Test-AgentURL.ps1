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


$Platform = 'zinfandel'
$SiteID = 'a4ebb808-023a-4469-bca2-da440e08adbc'
$AgentURL = "https://$Platform.centrastage.net/csm/profile/downloadAgent/$SiteID"
Write-Host $AgentURL -ForegroundColor Green

#wrong link
# https://zinfandelmm.centrastage.net/csm/profile/downloadAgent/a4ebb808-023a-4469-bca2-da440e08adbc

#!correct link (with no 'rmm')
# https://zinfandel.centrastage.net/csm/profile/downloadAgent/a4ebb808-023a-4469-bca2-da440e08adbc