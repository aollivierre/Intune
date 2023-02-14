#Change Log
#V1.0 initial version for testing
#V2.0 Added all different properties of a service that could contain the $Vendor_Service_Descriptor_1
#V2.1 Added skeleton to the script

# Requires -Version 5.1
$ErrorActionPreference = "SilentlyContinue"

function Kill-Service($Service_Name_1) {
    # [CmdletBinding()]
    # param (

        # [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, Position = 0)][alias("ServiceName", "VendorDescription", "VendorName")] [String[]] $Name
        
    # )
    
    begin {


        $Vendor_Service_Descriptor_1 = $null
        $Vendor_Service_Descriptor_1 = $Service_Name_1


        
    }
    
    process {

        try {

 

            # $All_Servicees = Get-Service | select-object -Property Path
            # $All_Services_1 = Get-Service
            $All_Services_1 = $null
            $All_Services_1 = Get-WmiObject win32_service
            # $ServicePath = (Get-Service | Where-Object { $_.Path -like "*$Vendor_Service_Descriptor_1*" } -ErrorAction SilentlyContinue)
    
            $Multiple_Services_To_Kill_1 = foreach ($Single_Service_1 in ($All_Services_1)) {
                if (
		
                    $Single_Service_1.Name -like "*$Vendor_Service_Descriptor_1*" -or
                    $Single_Service_1.PathName -like "*$Vendor_Service_Descriptor_1*" -or
                    $Single_Service_1.__RELPATH -like "*$Vendor_Service_Descriptor_1*" -or
                    $Single_Service_1.__PATH -like "*$Vendor_Service_Descriptor_1*" -or
                    $Single_Service_1.Caption -like "*$Vendor_Service_Descriptor_1*" -or	
                    $Single_Service_1.Description -like "*$Vendor_Service_Descriptor_1*" -or
                    $Single_Service_1.Displayname -like "*$Vendor_Service_Descriptor_1*" -or
                    # $Single_Service_1.Modules -like "*$Vendor_Service_Descriptor_1*" -or
                    $Single_Service_1.Path -like "*$Vendor_Service_Descriptor_1*"
		
                ) 
		
                {
                    $Single_Service_1
                }
            }

            # $DBG
	
            foreach ($Single_Service_To_Kill_1 in ($Multiple_Services_To_Kill_1))
            {

                #Stopping Service
                If ($Single_Service_To_Kill_1) 
                {
                    # try gracefully first
                    # $Single_Service_To_Kill_1.CloseMainWindow()
                    # kill after five seconds
                    Start-Sleep 5
                    # If (!$Single_Service_To_Kill_1.HasExited) {
                    write-host 'force killing the Service...' $Single_Service_To_Kill_1.name
                    $Single_Service_To_Kill_1 | select-object Name, PathName, __RELPATH, __PATH, Caption, Description, Path


                    $Single_Service_To_Kill_1.name  | Stop-Service -Force -PassThru
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


            $Vendor_Service_Descriptor_1 = $null
            
        }
        
    }
    
    end {
        
    }
}


#usage example
# find-service_EXE -Name 'TeamViewer' -Logfile_Name "C:\CCI\Logs\My_Events.log"
# find-service_EXE -Name 'TeamViewer'

# Kill-Service -Service_Name_1 'TeamViewer'
