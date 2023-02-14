# $LoadModuleFileScriptRoot_1 = $null
# $LoadModuleFileScriptRoot_1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
#     Split-Path -Path $MyInvocation.MyCommand.Path
# }
# else {
#     $PSScriptRoot
# }

function Load-ModuleFile {
    [CmdletBinding()]
    param (
        [Parameter()]
        $ModulesPath
    )
        
    begin {
            
    }
        
    process {


        try {
                 
            foreach ($module in $ModulesPath) {
    
    
                $modulename = $module.Name
                $DEFAULTMODULESPATH = "C:\Program Files\WindowsPowerShell\Modules\$modulename"
    
                if (!(test-path $DEFAULTMODULESPATH) ) {
                    write-host "$modulename NOT found in $DEFAULTMODULESPATH .. copying it now" -ForegroundColor gree
                    Copy-Item -Path "$Module" -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse
            
                    Import-Module -Name "$modulename" -Force
    
                }
    
                else {
                    write-host "$modulename already found $DEFAULTMODULESPATH"
                }
    
            }

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
            
    }
}




# $Modules = "C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Public\Modules"
# $Modules = Get-Childitem -path "$LoadModuleFileScriptRoot_1\*\Modules\*"
# $Modules = Get-Childitem -path "$LoadModuleFileScriptRoot_1\Modules\*"
# Load-ModuleFile -ModulesPath $Modules
