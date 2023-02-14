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


function Detect-TeamViewer {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        
    }
    
    process {
        
        try {

            Write-host "Detecting TeamViewer"
           
            
            $TeamViewer_exe_X86_1 = $null
            $TeamViewer_exe_X86_1 = "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"

            if ((Test-Path -Path $TeamViewer_exe_X86_1 )) { 
                # & "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
                # Start-Process -Wait "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"


                $TeamViewerEXESplat_1002 = @{

                    filepath = "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
                    # Wait         = $true
                    Passthru = $true

                }
                # Start-Process @TeamViewerEXESplat_1002

            }

            else {
                write-host "$TeamViewer_exe_X86_1 does not exist"
                $TeamViewer_exe_X64_1 = $null
                $TeamViewer_exe_X64_1 = "C:\Program Files\TeamViewer\TeamViewer.exe"
  
                if ((Test-Path -Path $TeamViewer_exe_X64_1 )) { 
                    # & "C:\Program Files\TeamViewer\TeamViewer.exe"
                    # Start-Process -Wait "C:\Program Files\TeamViewer\TeamViewer.exe"

                    $TeamViewerEXESplat_1003 = @{

                        filepath = "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
                        # Wait         = $true
                        Passthru = $true

                    }
                    # Start-Process @TeamViewerEXESplat_1003
                }

                else {
                    throw "$TeamViewer_exe_X64_1 does not exist"
                }
            }
            
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
    }
    
    end {
        
    }
}
