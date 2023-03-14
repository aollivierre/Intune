$ErrorActionPreference = "SilentlyContinue"

function Check-Process($Process_1) {
	
	
	begin {

		# Param
		# (
		# 	[Parameter(Mandatory)]
		# 	[String]$Process_1
		# )
    

		# $All_Processes_1 = Get-Process | select-object -Property Path
		$All_Processes_1 = $null
		$All_Processes_1 = Get-Process
		# $Process_1Path = (Get-Process | Where-Object { $_.Path -like "*$Process_1*" } -ErrorAction SilentlyContinue)
    
		$Multiple_Processes_To_check_1 = foreach ($Single_Process_to_check_1 in ($All_Processes_1)) {
			if (
		
				$Single_Process_to_check_1.Name -like "*$Process_1*" -or
				$Single_Process_to_check_1.Path -like "*$Process_1*" -or
				$Single_Process_to_check_1.Company -like "*$Process_1*" -or
				$Single_Process_to_check_1.Description -like "*$Process_1*" -or
				$Single_Process_to_check_1.Product -like "*$Process_1*" -or	
				$Single_Process_to_check_1.MainModule -like "*$Process_1*" -or
				# $Single_Process_to_check_1.Modules -like "*$Process_1*" -or
				$Single_Process_to_check_1.ProcessName -like "*$Process_1*"
		
			) 
		
			{
				$Single_Process_to_check_1
			}
		}
	

		
	}
	
	process {
		
		try {

			foreach ($Single_Process_to_check_1 in ($Multiple_Processes_To_check_1))
			{
		
				#Stopping Process
				If ($Single_Process_to_check_1) 
				{
					# try gracefully first
					# $Single_Process_to_check_1.CloseMainWindow()
					# check after five seconds
					# Start-Sleep 5
					# If (!$Single_Process_to_check_1.HasExited) {
					write-host 'checking the process...' $Single_Process_to_check_1 -ForegroundColor 'green'
					$Single_Process_to_check_1 | select-object Name, Path, Company, Description, Product, MainModule, ProcessName
		
		
					# $Single_Process_to_check_1  | Stop-Process -Force -PassThru
					# }
				}
		
			}
			
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