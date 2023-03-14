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


# Get-SecretInfo -Vault <KEEPER VAULT NAME>
Get-SecretInfo -Vault ""


# Listing Secrets
# Run the following PowerShell command to see a list of secrets from Keeper
# PS> Get-SecretInfo -Vault Keeper

# Name                                  Type      VaultName
# ----                                  ----      ---------
# bf3dg-99-Juh3feswgtFxg Home SSH       Hashtable Keeper
# _3zT0HvBtRdYzKTMw1IySA ACME Login     Hashtable Keeper
# Use the name set for your Keeper secrets vault, in the examples above we use Keeper.
# The secrets shown are any records shared with the Secrets Manager Application.  The Name column  displays each record's UID and title.