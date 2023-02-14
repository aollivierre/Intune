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

#Config Files II (RDP passwords and window sizes)	
# %userprofile%\AppData\Local\CentraStage



$AppName = "Datto RMM (Centra Stage)"

Try {
    if ((Test-Path -Path "$($env:LOCALAPPDATA)\CentraStage") ) {
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