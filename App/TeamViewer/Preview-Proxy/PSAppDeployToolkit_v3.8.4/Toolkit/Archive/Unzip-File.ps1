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



function unzip-file {
    [CmdletBinding()]
    param (
    
        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $zipfile,

        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $outpath

    )
    
    begin {

        Add-Type -AssemblyName System.IO.Compression.FileSystem


        #Install and Import the 7Zip module
        # Install-Module -Name "7Zip4Powershell" -Scope CurrentUser -force
        # Import-Module -Name "7Zip4Powershell" -force


        
    }
    
    process {

        try {

            # [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)



            $dir = split-path -parent $MyInvocation.MyCommand.Definition
            $7zipinstallfile = "$dir\7z1805-x64.msi"
            $7ziplogile = "$dir\7z.log"
            $Zipdirectory = "$dir\localstreamingclient.exe"
            $7zippath = "C:\Program Files\7-Zip\7z.exe"
            $7zoptions = "l $zipdirectory *.txt -r -y"
            $7zipinstalloptions = "/i $7zipinstallfile /quiet /qn /norestart /log $7ziplogile"
            $outputfile = "$dir\output.txt"
            $filteredoutputfile = "$dir\filteredoutput.txt"
            $errorfile = "$($svnm)_$($dbname)_db_$($dt)_error.txt"


            # $pmsiexec = Start-Process msiexec.exe -ArgumentList "$7zipinstalloptions" -wait -PassThru -verb RunAs
            # $pmsiexec = Start-Process msiexec.exe -ArgumentList "$7zipinstalloptions" -wait -PassThru
            # $pmsiexec.WaitForExit()
            # $pmsiexec.HasExited | Out-Null
            # $pmsiexec.ExitCode | Out-Null



            # $p7zip = start-process -FilePath $7zippath -ArgumentList "$7zoptions" -wait -PassThru -verb RunAs
            $p7zip = start-process -FilePath $7zippath -ArgumentList "$7zoptions" -wait -RedirectStandardOutput $outputfile
            # $p7zip.WaitForExit() | Out-Null
            $p7zip.HasExited | Out-Null
            $p7zip.ExitCode | Out-Null
			
			


        
        }
        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
                    
                    
            $ErrorMessage_3 = $_.Exception.Message
            write-host $ErrorMessage_3  -ForegroundColor Red
            Write-Output "Ran into an issue: $PSItem"
            Write-host "Ran into an issue: $PSItem" -ForegroundColor Red
            throw "Ran into an issue: $PSItem"
            throw "I am the catch"
            throw "Ran into an issue: $PSItem"
            $PSItem | Write-host -ForegroundColor
            $PSItem | Select-Object *
            $PSCmdlet.ThrowTerminatingError($PSitem)
            throw
            throw "Something went wrong"
            Write-Log $PSItem.ToString()
            $PSCmdlet.WriteError($_)
                


        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
        
    }
    
    end {
        
    }
}

# $zipfile = $null
# $zipfile = "C:\Momentum\Version 4_7_2\infrastructure.zip"

# $outpath = $null
# $outpath =  "C:\Momentum\extracted"

# unzip-file -zipfile $zipfile -outpath $outpath









