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





# Download a File
# Use dot notation to specify a file attached to a secret in the Keeper vault.  Then pass that file to the Set-Content command to download it.
# Get-Secret <RECORD NAME OR UID>.files[<FILENAME>] `
# | Set-Content -Path <FILE PATH> -AsByteStream
# PS> Get-Secret my_record.files[file1.json] `
# | Set-Content -Path ./file1.json -AsByteStream
# The specified file will be downloaded to the path location given to Set-Content


Get-Secret my_record.files[file1.json]  | Set-Content -Path ./file1.json -AsByteStream