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



# Getting a Single Secret
# Get information and values of a single secret
# 
# PS> Get-Secret "ACME Login" -AsPlainText

# Name                           Value
# ----                           -----
# login                          user2
# password                       123
# Files                          {file1.json, file2.zip}
# Wrap the record name in quotation marks when there is a space in it.
# -AsPlainText Shows the actual values of the secrets.  Otherwise PowerShell shows them as a SecureString


Get-Secret "<RECORD NAME or UID>" -AsPlainText