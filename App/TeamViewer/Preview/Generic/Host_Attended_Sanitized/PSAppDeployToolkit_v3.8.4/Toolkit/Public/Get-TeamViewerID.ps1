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

function Get-TeamViewerID {
    [CmdletBinding()]
    param (
        [Parameter()]
        $TeamViewerID
    )
        
    begin {
            
    }
        
    process {


        try {


                        #Region To Get TeamViewer Client ID in Decimal format from Registry using native PowerShell cmdlet

                        $MULTIPLE_PATH_2 = $null
                        $MULTIPLE_PATH_2 = @(
                            'HKLM:\SOFTWARE\Wow6432Node\TeamViewer'
            
                        )
            
                        foreach ($SINGLE_PATH_2 in $MULTIPLE_PATH_2) {
                            
                            $TeamViewer_Cliend_ID_REG_PATH_TO_CHECK_2 = $null
                            $TeamViewer_Cliend_ID_REG_PATH_TO_CHECK_2 = Test-Path $SINGLE_PATH_2
            
                            # do 
                            # {
            
                            #     Write-host 'waiting for the TeamViewer Client ID to populate in the reg path' $SINGLE_PATH_2
                            #     $TeamViewer_Client_ID_1 = $null
                            #     $TeamViewer_Client_ID_1 = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\TeamViewer').ClientID
                            #     $count1 = ($TeamViewer_Client_ID_1).count
                            #     Start-Sleep -Milliseconds 600
            
                            # } until ($count1 -eq 1)
            
                            if ($TeamViewer_Cliend_ID_REG_PATH_TO_CHECK_2) {
            
                                # write-host "found $SINGLE_PATH_2"
                                Write-Host 'gathering Teamviewer ID from reg' -ForegroundColor Green
                                # Start-Sleep -Seconds 3
                                $TeamViewer_Client_ID_1 = $null
                                $TeamViewer_Client_ID_1 = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\TeamViewer').ClientID

                                # Write-host "The TeamViewer ID is" $TeamViewer_Client_ID_1 -ForegroundColor Green

                            }
            
                            else {
                                write-host "not found $SINGLE_PATH_2"
                            }
            
                        }
            
                        #endRegion To Get TeamViewer Client ID in Decimal format from Registry using native PowerShell cmdlet


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
        return $TeamViewer_Client_ID_1
            
    }
}



# Get-TeamViewerID
