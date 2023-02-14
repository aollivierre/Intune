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


# $LoadModuleFileScriptRoot_1 = $null
# $LoadModuleFileScriptRoot_1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
#     Split-Path -Path $MyInvocation.MyCommand.Path
# }
# else {
#     $PSScriptRoot
# }

function Get-TeamViewerSecret {
    [CmdletBinding()]
    param (
        [Parameter()]
        $TeamViewerSecretName
    )
        
    begin {
            
        $TeamViewerSecretValue = $null
    }
        
    process {


        try {


            $TeamViewerSecretValue = Get-Secret -Name $TeamViewerSecretName -AsPlainText


        }
           
        <#Do this if a terminating exception happens#>


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
                


        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
            
    }
        
    end {

        return $TeamViewerSecretValue
            
    }
}



# Get-TeamViewerSecret
