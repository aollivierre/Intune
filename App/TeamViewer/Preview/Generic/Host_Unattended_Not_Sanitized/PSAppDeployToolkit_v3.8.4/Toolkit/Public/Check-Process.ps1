$ErrorActionPreference = "Continue"

function check-Process($Process_1) {
	
	
    begin {

               	
    }
	
    process {
		
        try {

		
            # $DBG
            #Stopping Process
            # If (($Multiple_Processes_To_check_1.Length -eq '0')) {
                # try gracefully first
                # $Single_Process_to_check_1.CloseMainWindow()
                # check after five seconds
                # Start-Sleep 5
                # If (!$Single_Process_to_check_1.HasExited) {

                        
                        
                write-host 'checking the process...' $Single_Process_to_check_1 -ForegroundColor 'green'
                $Single_Process_to_check_1 | select-object Name, Path, Company, Description, Product, MainModule, ProcessName
            
                # $processID_1001 = $Single_Process_to_check_1.Id


                # do {
        
                #     Write-host 'waiting until TeamViewer is running' -ForegroundColor Yellow
                #     # $uninstallteamviewermslogfolderpath = Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer -eq $true -and $_.Name -match "logs" }
                #     $count = $processID_1001.count
                #     Start-Sleep -Milliseconds 600
        
                # } until ($count -eq 1)

    
            # }
              

            # elseif ($processID_1001) {
    
    
                write-host 'TeamViewer with process' $processID_1001 'is running'
    
            # }

                    

            # Stop-Process -Id $processID_1001 -Force -PassThru
            # Wait-Process -Id $processID_1001
		
            # $Single_Process_to_check_1  | Stop-Process -Force -PassThru
            # }
                


            # else {


                    
                # foreach ($Single_Process_to_check_1 in ($Multiple_Processes_To_check_1)) {
                #     write-host "The process" $Single_Process_to_check_1 "is found"

                #     $Single_Process_to_check_1 | select-object Name, Path, Company, Description, Product, MainModule, ProcessName
            
                #     $processID_1001 = $Single_Process_to_check_1.Id
                # }

    
            # }
                    

            # do {

            #     Write-host 'waiting until TeamViewer is running' -ForegroundColor Yellow
            #     # $uninstallteamviewermslogfolderpath = Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer -eq $true -and $_.Name -match "logs" }
            #     $count = $Single_Process_to_check_1.count
            #     Start-Sleep -Milliseconds 600

            # } until ($count -eq 1)


            


		
            
			
        }
        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
            
            
            $ErrorMessage_5 = $_.Exception.Message
            write-host $ErrorMessage_5  -ForegroundColor Red
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
			
        }

    }
	
    end {
		
    }
}

#USAGE Example: check-process -Process "*mmc*"

# check-process -Process "notepad"
# Start-Sleep 20


# check-process -Process_1 'msiexec'






    # Param
    # (
    # 	[Parameter(Mandatory)]
    # 	[String]$Process_1
    # )


    # $All_Processes_1 = Get-Process | select-object -Property Path
    $All_Processes_1 = $null
    $All_Processes_1 = Get-Process



    $Single_Process_to_check_1 = $null
    $Multiple_Processes_To_check_1 = $null

    # $Process_1Path = (Get-Process | Where-Object { $_.Path -like "*$Process_1*" } -ErrorAction SilentlyContinue)


    $Multiple_Processes_To_check_1 = foreach ($Single_Process_to_check_1 in ($All_Processes_1)) {
        if (

            # write-host 'empty' -ForegroundColor Yellow
    
            $Single_Process_to_check_1.Name -like "*$Process_1*" -or
            $Single_Process_to_check_1.Path -like "*$Process_1*" -or
            $Single_Process_to_check_1.Company -like "*$Process_1*" -or
            $Single_Process_to_check_1.Description -like "*$Process_1*" -or
            $Single_Process_to_check_1.Product -like "*$Process_1*" -or	
            $Single_Process_to_check_1.MainModule -like "*$Process_1*" -or
           
            $Single_Process_to_check_1.ProcessName -like "*$Process_1*"
    
        ) 
        
        {

            $Single_Process_to_check_1
        }



        # else {
        #     <# Action when all if and elseif conditions are false #>


        #     $Single_Process_to_check_1 = $null
        # }

    }


    Get-Process -Name TeamViewer, tv_x64, tv_x32

# write-host "checking TeamViewer"
check-process -Process_1 "TeamViewer"
check-process -Process_1 "tv_x64"
check-process -Process_1 "tv_x32"
