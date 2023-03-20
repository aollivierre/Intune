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


    expected output

    PS D:\Code\Intune> . "d:\Code\Intune\Intune\W32_App_Deployment\9-Assign-App\9.4-Package-Win32App.ps1"
VERBOSE: Successfully detected specified source folder: D:\Code\Intune\Intune\W32_App_Deployment\0-Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\ContosoHealth_Corp        
VERBOSE: Successfully detected specified setup file 'AgentSetup_Contoso_Corporate.exe' in source folder
VERBOSE: Successfully detected specified output folder: D:\Code\Intune\Intune\W32_App_Deployment\9-Assign-App\output
VERBOSE: Unable to detect IntuneWinAppUtil.exe in specified location, attempting to download to: C:\Users\ADMIN-~1.AZU\AppData\Local\Temp
VERBOSE: Successfully detected IntuneWinAppUtil.exe in: C:\Users\ADMIN-~1.AZU\AppData\Local\Temp\IntuneWinAppUtil.exe
INFO   Validating parameters
INFO   Validated parameters within 26 milliseconds
INFO   Compressing the source folder 'D:\Code\Intune\Intune\W32_App_Deployment\0-Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\ContosoHealth_Corp' to 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\IntunePackage.intunewin'
INFO   Calculated size for folder 'D:\Code\Intune\Intune\W32_App_Deployment\0-Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\ContosoHealth_Corp' is 10762224 within 0 milliseconds
INFO   Compressed folder 'D:\Code\Intune\Intune\W32_App_Deployment\0-Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\ContosoHealth_Corp' successfully within 236 milliseconds
INFO   Checking file type
INFO   Checked file type within 2 milliseconds
INFO   Encrypting file 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\IntunePackage.intunewin'
INFO   'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\IntunePackage.intunewin' has been encrypted successfully within 28 milliseconds
INFO   Computing SHA256 hash for C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\8e4e79d8-42e9-4c03-a3c1-b2be3a43aed7
INFO   Computed SHA256 hash for 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\8e4e79d8-42e9-4c03-a3c1-b2be3a43aed7' within 53 milliseconds
INFO   Computing SHA256 hash for C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\IntunePackage.intunewin
INFO   Computed SHA256 hash for C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\IntunePackage.intunewin within 55 milliseconds
INFO   Copying encrypted file from 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\8e4e79d8-42e9-4c03-a3c1-b2be3a43aed7' to 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Contents\IntunePackage.intunewin'


INFO   Generating detection XML file 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage\Metadata\Detection.xml'
INFO   Generated detection XML file within 16 milliseconds
INFO   Compressing folder 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage' to 'D:\Code\Intune\Intune\W32_App_Deployment\9-Assign-App\output\AgentSetup_Contoso_Corporate.intunewin'
INFO   Calculated size for folder 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage' is 10469202 within 0 milliseconds  
INFO   Compressed folder 'C:\Users\Admin-Abdullah.AzureAD\AppData\Local\Temp\b7334eac-5616-4e9e-ade4-0129b8c6f311\IntuneWinPackage' successfully within 81 milliseconds
INFO   Removing temporary files
INFO   Removed temporary files within 1 milliseconds
INFO   File 'D:\Code\Intune\Intune\W32_App_Deployment\9-Assign-App\output\AgentSetup_Contoso_Corporate.intunewin' has been generated successfully


[=================================================]   100%  
INFO   Done!!!

VERBOSE: Successfully created Win32 app package object


Name                   : AgentSetup_Contoso_Corporate.exe
FileName               : IntunePackage.intunewin
SetupFile              : AgentSetup_Contoso_Corporate.exe
UnencryptedContentSize : 10468257
Path                   : D:\Code\Intune\Intune\W32_App_Deployment\9-Assign-App\output\AgentSetup_Contoso_Corporate.intunewin

#>


# Package MSI as .intunewin file
# $SourceFolder = "C:\Win32Apps\Source\7-Zip"
# $SetupFile = "7z1900-x64.msi"
# $OutputFolder = "C:\Win32Apps\Output"
# New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose




$SourceFolder = "D:\Code\Intune\Intune\W32_App_Deployment\0-Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\Contoso_Corp"
$SetupFile = "AgentSetup_Contoso_Corporate.exe"
$OutputFolder = "D:\Code\Intune\Intune\W32_App_Deployment\9-Assign-App\output"
New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose