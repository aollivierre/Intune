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

#Installation Directory	
# C:\Program Files (x86)\CentraStage


$AppName = "Datto RMM (Centra Stage) ver 4.4.2181.2181"
$File = "C:\Program Files (x86)\CentraStage\CagService.exe"
$FileVersion = "4.4.2181.2181"

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