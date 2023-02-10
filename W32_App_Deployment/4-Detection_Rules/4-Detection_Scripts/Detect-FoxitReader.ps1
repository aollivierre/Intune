<#
.SYNOPSIS

.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.

    https://www.petervanderwoude.nl/post/working-with-custom-detection-rules-for-win32-apps/
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

# {0}


if (Test-Path "$($env:ProgramFiles)\Foxit Software\Foxit Reader\FoxitReader.exe") {
    Write-Host "Found it!"
}