<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.

    Here is a sample script to use with Custom detection script rule with Win32 App. The script will check for file existance and it's version. It will return Exit code 0 and write string value in STDOUT if condition mathced. Else, it will return Exit code 0. The intune extension manager will capture the output written to STDOUT ( using Write-host ) and show that in the log file.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.


    https://www.techuisitive.com/post/intune-understanding-win32-app-detection-rules

.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

$AppName = "Winzip ver 26.0"
$File = "D:\Program Files\WinZip26\winzip64.exe"
$FileVersion = "50.260.14610 (64-bit)"

Write-Host "Custom script based detection : $AppName"

if (Test-path $File) {
    $ActualVersion = (Get-ItemProperty -Path $File).VersionInfo.FileVersion
    If ($ActualVersion -eq $FileVersion) {
        Write-host "Actual version: $Actualversion, Compared version: $FileVersion"
        Write-host "Same version of application installed"
        Exit 0}
    else { 
        Write-host "Actual version: $Actualversion, Compared version: $FileVersion"
        Write-host "Different Version of application installed"
        Exit 0}
} 
else { 
Write-Host "File $file not found. Application not installed"
Exit 1
}