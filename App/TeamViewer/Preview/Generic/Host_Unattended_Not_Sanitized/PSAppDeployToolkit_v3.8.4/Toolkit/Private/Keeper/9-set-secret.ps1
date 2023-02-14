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



# Set a Value to a Secret
# Update the value of a single secret field 
Set-Secret "<RECORD NAME OR UID>.<FIELD> <VALUE TO SET>"
# If the Keeper vault is not set as the default secret vault add 
# -Vault <keeper vault name> to the command