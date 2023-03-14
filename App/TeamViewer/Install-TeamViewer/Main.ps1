$ErrorActionPreference = "SilentlyContinue"
# Set ScripRoot variable to the path which the script is executed from
$ScriptRoot1 = $null
$ScriptRoot1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}

$log_dir_1 = $null
$log_dir_1 = "$ScriptRoot1\logs"


#cleanup logs folder
# if ((Test-Path -Path $log_dir_1 )) { 
#     Remove-Item -Path $log_dir_1 -Force -Recurse
# }

# start-sleep 5

if (!(Test-Path -Path $log_dir_1 )) { 
    New-Item -Force -ItemType directory -Path $log_dir_1
}

# write-host 'current root is ' $ScriptRoot1

."$ScriptRoot1\Public\Kill-Process.ps1"
."$ScriptRoot1\Public\Add-StartupApp.ps1"
."$ScriptRoot1\Public\Set-HighPerfPowerPlan.ps1"
."$ScriptRoot1\Public\Send-Email.ps1"
."$ScriptRoot1\Public\uninstall-teamviewer.ps1"
."$ScriptRoot1\Public\kill-service.ps1"
."$ScriptRoot1\Public\Set-ServiceStartupDisabled.ps1"
."$ScriptRoot1\Public\Install-TeamViewer.ps1"

function Invoke-Main {
    [CmdletBinding()]
    param (
        
    )
    
    begin {

        $date_1 = $null
        $date_1 = [System.DateTime]::Now.ToString("yyyy-MM-dd_HH_mm_ss")

        try { Stop-Transcript | Out-Null } catch { }

        $sitename_1 = $null
        $sitename_1 = (Get-WmiObject -query "SELECT DESCRIPTION FROM win32_operatingsystem").DESCRIPTION

        $Domainname_1 = $null
        $Domainname_1 = (Get-WmiObject -query "SELECT DOMAIN FROM win32_computersystem").DOMAIN

        $TargetMachineName_1 = $null
        $TargetMachineName_1 = [System.Environment]::MachineName

        #Create log
        $log_1 = "$log_dir_1\Main_Script_$($Domainname_1)_$($sitename_1)_$($TargetMachineName_1)_PS_$($date_1).log"
        try { Start-Transcript -path $log_1 | Out-Null } catch { }
        Write-Host "Start Date and Time is $((Get-Date -Format G))"
        #Get the current Path of the script for dynamic reference in your script

        Write-Host "The Current Directory where PowerShell script is Running : ${ScriptRoot1}"

 

        Set-HighPerfPowerPlan

        $Script:SYS_ENV_SYSDIRECTORY = $null
        $Script:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory
        
    }
    
    process {


        try {

            Set-ServiceStartupDisabled -Service_Name_2 "TeamViewer"
            Start-Sleep 10

            write-host "Stopping TeamViewer"
            Kill-Process -Process_1 "TeamViewer"
            Kill-Process -Process_1 "tv_x64"
            Kill-Process -Process_1 "tv_x32"
            Start-Sleep 20

            

            kill-service -Service_Name_1 "TeamViewer"
            Start-Sleep 20

            uninstall-teamviewer
            start-sleep 60

            Install-TeamViewer

            Write-host "Adding TeamViewer to Startup Programs"
            Add-StartupApp -APP_NAME_3 'TeamViewer' -APP_EXE_3 "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"

            #Region To Get TeamViewer Client ID in Decimal format from Registry using native PowerShell cmdlet

        

            $MULTIPLE_PATH_2 = $null
            $MULTIPLE_PATH_2 = @(
                'HKLM:\SOFTWARE\Wow6432Node\TeamViewer'

            )

            foreach ($SINGLE_PATH_2 in $MULTIPLE_PATH_2) {
                
                $TeamViewer_Cliend_ID_REG_PATH_TO_CHECK_2 = $null
                $TeamViewer_Cliend_ID_REG_PATH_TO_CHECK_2 = Test-Path $SINGLE_PATH_2

                if ($TeamViewer_Cliend_ID_REG_PATH_TO_CHECK_2) {
                    $TeamViewer_Client_ID_1 = $null
                    $TeamViewer_Client_ID_1 = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\TeamViewer').ClientID
                }

            }

            #endRegion To Get TeamViewer Client ID in Decimal format from Registry using native PowerShell cmdlet

            Set-HighPerfPowerPlan

            #! if the computer is already added to team viewer ensure that you delete the computer before running this script again


            Write-Host "End Date and Time is $((Get-Date -Format G))"
            try { Stop-Transcript | Out-Null } catch { }


            Write-host "Emaling the TeamViewer ID"
            Send-Email -emailbody_2 "$TeamViewer_Client_ID_1" -log_2 "$log_1"
            
        }
        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
            
            
            $ErrorMessage_1 = $_.Exception.Message
            write-host $ErrorMessage_1  -ForegroundColor Red
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


Invoke-Main