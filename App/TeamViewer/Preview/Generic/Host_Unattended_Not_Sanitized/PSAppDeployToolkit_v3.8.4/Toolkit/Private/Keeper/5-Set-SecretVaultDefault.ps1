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



# Set Keeper Vault as Default Secret Storage (Optional)
# Set the Keeper vault you just added as the default secret storage.  This will tell the PowerShell SecretsManagement module to use your Keeper vault when getting and setting secrets.


Set-SecretVaultDefault keeper



# This step is optional, but if you choose not to do it, you may receive secrets from your default vault if they have the same name, and you will need to add -Vault <keeper vault name>  (e.g. -Vault keeper ) to Set-Secret commands
# The Keeper Secrets Manager PowerShell Plugin is now ready to be used