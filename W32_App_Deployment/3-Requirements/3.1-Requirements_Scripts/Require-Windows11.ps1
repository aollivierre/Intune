<#
.SYNOPSIS
    
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.

    https://smsagent.blog/2022/03/03/user-context-detection-rules-for-intune-win32-apps/
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

# {0}



[int]$BuildNumber = Get-CimInstance Win32_OperatingSystem -Property BuildNumber | Select-Object -ExpandProperty BuildNumber
If ($BuildNumber -ge 22000)
{
    Write-Output "Pass"
}
else
{
    Write-Output "Fail"
}

