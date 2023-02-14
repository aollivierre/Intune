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

#Config Files I
# C:\Windows\System32\config\systemprofile\AppData\Local\CentraStage
# C:\Windows\SysWOW64\config\systemprofile\AppData\Local\CentraStage

$Script:SYS_ENV_SYSDIRECTORY_32 = $null
$Script:SYS_ENV_SYSDIRECTORY_32 = [System.Environment]::SystemDirectory

$Script:SYS_ENV_SYSDIRECTORY_64 = $null
$Script:SYS_ENV_SYSDIRECTORY_64 = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::SystemX86)

$AppName = "Datto RMM (Centra Stage)"

Try {
    if ((Test-Path -Path "$Script:SYS_ENV_SYSDIRECTORY_32\config\systemprofile\AppData\Local\CentraStage") -or (Test-Path -Path "$Script:SYS_ENV_SYSDIRECTORY_64\config\systemprofile\AppData\Local\CentraStage") ) {
        Write-Output "$AppName is installed!"
        exit 0
    }
    else { 
        Write-Warning "$AppName  is not installed!"
        Exit -1
    }
}
catch [execption] {
    Write-Error "[Error] $($_.Exception.Message)"
}


# $Script:SYS_ENV_SYSDIRECTORY_64 = $null
# $Script:SYS_ENV_SYSDIRECTORY_64 = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::SystemX86)


# Try {
#     if (Test-Path -Path "$Script:SYS_ENV_SYSDIRECTORY_64\config\systemprofile\AppData\Local\CentraStage") {
#         Write-Output "$AppName is installed!"
#         exit 0
#     }
#     else { 
#         Write-Warning "$AppName  is not installed!"
#         Exit -1
#     }
# }
# catch [execption] {
#     Write-Error "[Error] $($_.Exception.Message)"
# }