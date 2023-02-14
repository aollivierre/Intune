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


<#
#Example 1

$ErrorActionPreference = "SilentlyContinue"
# Set ScripRoot variable to the path which the script is executed from
$ScriptRoot1 = $null
$ScriptRoot1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}

#Get public and private function definition files.
$Public = "$ScriptRoot1\Public"
$Private = "$ScriptRoot1\Private"
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
#>



<#
#Example 2


    .SYNOPSIS
        Root module file.
 
    .DESCRIPTION
        The root module file loads all classes, helpers and functions into the
        module context.


# Get and dot source all classes (internal)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Classes' -Directory |
        Get-ChildItem -Include '*.ps1' -File -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all helper functions (internal)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Helpers' -Directory |
        Get-ChildItem -Include '*.ps1' -File -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all external functions (public)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Functions' -Directory |
        Get-ChildItem -Include '*.ps1' -File -Recurse |
            ForEach-Object { . $_.FullName }

#>

