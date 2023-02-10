# function Add-StartupApp {
    function Add-StartupApp($APP_NAME_3, $APP_EXE_3) {
    # [CmdletBinding()]
    # param (
        
    #     [Parameter(Mandatory = $true, Position = 0)]
    #     [String] $APP_NAME_3,
    #     [Parameter(Mandatory = $false, Position = 1)]
    #     [string] $APP_EXE_3


    # )
    
    begin {


        $USER_PRFOILES_PATH_MAIN_3 = $null
        $USER_PRFOILES_PATH_MAIN_3 = 'C:\Users'

        $USER_PRFOILES_3 = $null
        $USER_PRFOILES_3 = Get-ChildItem $USER_PRFOILES_PATH_MAIN_3

        $DBG


        # $Public_Folder_To_Exclude = $Null
        # $Public_Folder_To_Exclude = "C:\users\Public"

        $profiles_3 = $null
        $profiles_3 = foreach ($USER_PRFOILE in $USER_PRFOILES_3) {

            # $NTUSER_DAT_EXIST = Test-path C:\Users\$USER_PRFOILE\NTUSER.DAT

            # if (!($USER_PRFOILE.FullName -eq $Public_Folder_To_Exclude)) {

                $USER_PRFOILE.name
            # }
    
        }

        # $DBG

        
    }
    
    process {

        try {

            
            foreach ($profile in $profiles_3) {

                $USER_PROFILE_PATH_3 = $null
                $USER_PROFILE_PATH_3 = "C:\Users\$profile"

                $StartUp_Destination_3 = $null
                # $StartUp = "$Env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
                $StartUp_Destination_3 = "$USER_PROFILE_PATH_3\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

                if ((Test-Path $StartUp_Destination_3)) {
    
                    # $DBG


                    $STARTUP_APP_Full_NAME_3 = $null
                    $STARTUP_APP_Full_NAME_3 = $APP_NAME_3

                    $Startup_APP_LINK_3 = $null
                    $Startup_APP_LINK_3 = "$STARTUP_APP_Full_NAME_3.lnk"



                    $Startup_APP_EXE_PATH_3 = $null
                    $Startup_APP_EXE_PATH_3 = $APP_EXE_3



                    $final_startup_destination_1 = $null
                    $final_startup_destination_1 = "$StartUp_Destination_3\$($Startup_APP_LINK_3)"

                    # $DBG

                    # New-Item -ItemType SymbolicLink -Path "$StartUp" -Name "$Startup_APP_LINK_3" -Value "$Startup_APP_EXE_PATH_3"


                    # param ( [string]$Startup_APP_EXE_PATH_3, [string]$StartUp_Destination_3 )


                    if (!(Test-Path -Path "$final_startup_destination_1" )) {
                        write-host 'creating Shortcut for' $APP_NAME_3 'of' $APP_EXE_3 'in' $final_startup_destination_1 -ForegroundColor 'Yellow'
                        $WshShell_3 = New-Object -comObject WScript.Shell
                        $Shortcut = $WshShell_3.CreateShortcut($final_startup_destination_1)
                        $Shortcut.TargetPath = $Startup_APP_EXE_PATH_3
                        $Shortcut.Save()
                    }
            
            
                    else {
                
                
                        write-host 'The Shortcut' "$final_startup_destination_1" 'already exists' -ForegroundColor Green
                
                    }

                }
       




            }
            
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
            
        }
        
        finally {
            
        }
        
    }
    
    end {

        # if (!(Test-Path -Path "$final_startup_destination_1" )) {
        #     write-host 'The Shortcut' "$final_startup_destination_1" 'was not created' -ForegroundColor Red
        # }
	
	
        # else {
		
		
        #     write-host 'The Shortcut' "$final_startup_destination_1" 'was created' -ForegroundColor Green
		
        # }
        
    }
}

# Add-StartupApp -APP_NAME 'TeamViewer' -APP_EXE "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"



