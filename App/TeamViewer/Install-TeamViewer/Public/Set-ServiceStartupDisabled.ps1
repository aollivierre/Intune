
#Change Log
#V1.0 initial version for testing
#V2.0 Added all different properties of a service that could contain the $Vendor_Service_to_disable_Descriptor_2
#V2.1 Added skeleton to the script

# Requires -Version 5.1
$ErrorActionPreference = "SilentlyContinue"

$Script:SYS_ENV_SYSDIRECTORY = $null
$Script:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory

function Set-ServiceStartupDisabled ($Service_Name_2) {
    # [CmdletBinding()]
    # param (

    #     [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, Position = 0)][alias("ServiceName", "VendorDescription", "VendorName")] [String[]] $Name
        
    # )
    
    begin {


        $Vendor_Service_to_disable_Descriptor_2 = $null
        $Vendor_Service_to_disable_Descriptor_2 = $Service_Name_2


        
    }
    
    process {

        try {

 

            # $All_Servicees = Get-Service | select-object -Property Path
            # $All_Services_2 = Get-Service

            $All_Services_2 = $null
            $All_Services_2 = Get-WmiObject win32_service
            # $ServicePath = (Get-Service | Where-Object { $_.Path -like "*$Vendor_Service_to_disable_Descriptor_2*" } -ErrorAction SilentlyContinue)
    
            $Multiple_services_to_disable_2 = foreach ($Sinlge_Service_2 in ($All_Services_2)) {
                if (
		
                    $Sinlge_Service_2.Name -like "*$Vendor_Service_to_disable_Descriptor_2*" -or
                    $Sinlge_Service_2.PathName -like "*$Vendor_Service_to_disable_Descriptor_2*" -or
                    $Sinlge_Service_2.__RELPATH -like "*$Vendor_Service_to_disable_Descriptor_2*" -or
                    $Sinlge_Service_2.__PATH -like "*$Vendor_Service_to_disable_Descriptor_2*" -or
                    $Sinlge_Service_2.Caption -like "*$Vendor_Service_to_disable_Descriptor_2*" -or	
                    $Sinlge_Service_2.Description -like "*$Vendor_Service_to_disable_Descriptor_2*" -or
                    $Sinlge_Service_2.Displayname -like "*$Vendor_Service_to_disable_Descriptor_2*" -or
                    # $Sinlge_Service_2.Modules -like "*$Vendor_Service_to_disable_Descriptor_2*" -or
                    $Sinlge_Service_2.Path -like "*$Vendor_Service_to_disable_Descriptor_2*"
		
                ) 
		
                {
                    $Sinlge_Service_2
                }
            }

            # $DBG
	
            foreach ($Single_Service_to_Disable_2 in ($Multiple_services_to_disable_2))
            {

                #Stopping Service
                If ($Single_Service_to_Disable_2) 
                {
                    # try gracefully first
                    # $Single_Service_to_Disable_2.CloseMainWindow()
                    # kill after five seconds
                    Start-Sleep 5
                    # If (!$Single_Service_to_Disable_2.HasExited) {
                    write-host 'Setting the service...' $Single_Service_to_Disable_2.name 'to disabled' -ForegroundColor 'green'
                    $Single_Service_to_Disable_2 | select-object Name, PathName, __RELPATH, __PATH, Caption, Description, Displayname, Path

                    

                    write-host 'configuring' $Single_Service_to_Disable_2.name -ForegroundColor 'green'
                    #set service startup to disabled
                    & $SYS_ENV_SYSDIRECTORY\SC.exe config $Single_Service_to_Disable_2.name start= disabled error= normal
                    #set service recovery to none
                    & $SYS_ENV_SYSDIRECTORY\SC.exe failure $Single_Service_to_Disable_2.name  actions= ////// reset= 0


                    # $Single_Service_to_Disable_2  | Stop-Service -Force -PassThru
                    # }
                }

            }


            # Write-PSFScriptLogging -Level Important -Message 'Successfully ran logging info' -Tag 'Success'
        }
        catch {


            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red


            # Write-PSFScriptLogging -Level Warning -Message 'Error getting the service name.' -Tag 'Failure' -ErrorRecord $_
            
        }
        finally {


            $Vendor_Service_to_disable_Descriptor_2 = $null
            
        }
        
    }
    
    end {
        
    }
}


#usage example
# find-service_EXE -Name 'TeamViewer' -Logfile_Name "C:\CCI\Logs\My_Events.log"
# find-service_EXE -Name 'TeamViewer'

# Set-ServiceStartupDisabled -Service_Name_2 'TeamViewer'
