<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.

Running the script
To run the sample script you can modify the samples below to match the type and conditions you want to upload:



.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.


    https://github.com/microsoftgraph/powershell-intune-samples/tree/master/LOB_Application
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines

Sample 1
PowerShell Detection Rule and default return codes

#>

$ErrorActionPreference = "SilentlyContinue"
# Set ScripRoot variable to the path which the script is executed from
$ScriptRoot1 = $null
$ScriptRoot1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}

# $log_dir_1 = $null
# $log_dir_1 = "$ScriptRoot1\logs"


# if (!(Test-Path -Path $log_dir_1 )) { 
#     New-Item -Force -ItemType directory -Path $log_dir_1
# }


# $Modules = Get-Childitem -path "$ScriptRoot1\*\Modules\*"

#Get public and private function definition files.
$Public = "$ScriptRoot1\Public"
$PSScripts_1 = @( Get-ChildItem -Path $Public\*.ps1 -Recurse -ErrorAction SilentlyContinue )
        
#Dot source the files
Foreach ($import in @($PSScripts_1)) {
    Try {

        Write-host "processing $import"
        #         $files = Get-ChildItem -Path $root -Filter *.ps1
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}


#=================================================================
#=================================================================
#=================================================================
#Starting the main function

$SourceFile = "C:\packages\package.intunewin"

$PowerShellScript = "C:\Scripts\sample.ps1"

$PowerShellRule = New-DetectionRule -PowerShell -ScriptFile "$PowerShellScript" -enforceSignatureCheck $false -runAs32Bit $true

# Creating Array for detection Rule
$DetectionRule = @($PowerShellRule)

$ReturnCodes = Get-DefaultReturnCodes

# Win32 Application Upload (no splat)
# Upload-Win32Lob -SourceFile "$SourceFile" -publisher "Publisher" -description "Description" -detectionRules $DetectionRule -returnCodes $ReturnCodes -installCmdLine "powershell.exe -executionpolicy Bypass .\install.ps1" -uninstallCmdLine "powershell.exe -executionpolicy Bypass .\uninstall.ps1"

# Win32 Application Upload (with splat using editor command suite)
$uploadWin32LobSplat = @{
    displayName       = "displayname"
    SourceFile        = "$SourceFile"
    publisher         = "Publisher"
    description       = "Description"
    returnCodes       = $ReturnCodes
    installCmdLine    = "powershell.exe -executionpolicy Bypass .\install.ps1"
    uninstallCmdLine  = "powershell.exe -executionpolicy Bypass .\uninstall.ps1"
    detectionRules    = $DetectionRule
    installExperience = "system"
    
}
Upload-Win32Lob @uploadWin32LobSplat


