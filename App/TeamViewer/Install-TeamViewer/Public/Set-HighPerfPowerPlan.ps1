function Set-HighPerfPowerPlan {
    # [CmdletBinding()]
    # param (
        
    # )
    
    begin {


        $Script:SYS_ENV_SYSDIRECTORY = $null
        $Script:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory


        #in case there is not a plan for HighPerformance then set the current plan any ways to start with
        & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -disk-timeout-ac 0 #Plugged In
        & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -disk-timeout-dc 0 #On Battery

        & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -hibernate-timeout-ac 0 #Plugged In
        & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -hibernate-timeout-dc 0 #On Battery

        & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -standby-timeout-ac 0 #Plugged In
        & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -standby-timeout-dc 0 #On Battery


        function Set-PowerPlan ($powerPlan = "balanced") {
            try {
                #     $powerPlan = $powerPlan.toLower()
                #     $perf = & $SYS_ENV_SYSDIRECTORY\powercfg.exe -l | ForEach-Object { if ($_.toLower().contains($powerPlan)) { $_.split()[3] } }
                #     $currentPlan = $(powercfg -getactivescheme).split()[3]

                #     if ($currentPlan -ne $perf) {
                #         & $SYS_ENV_SYSDIRECTORY\powercfg.exe -setactive $perf
                #     }
            }
            catch {
                Write-Warning -Message "Unabled to set power plan to $powerPlan"
            }
        }

        function Set-PowerSaver {
            Set-PowerPlan("power saver")
        }

        function Set-PowerHighPerformance {
            Set-PowerPlan("high performance")

            & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -disk-timeout-ac 0 #Plugged In
            & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -disk-timeout-dc 0 #On Battery

            & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -hibernate-timeout-ac 0 #Plugged In
            & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -hibernate-timeout-dc 0 #On Battery

            & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -standby-timeout-ac 0 #Plugged In
            & $SYS_ENV_SYSDIRECTORY\powercfg.exe -x -standby-timeout-dc 0 #On Battery
        }

        function Set-PowerBalanced {
            Set-PowerPlan("balanced")
        }


        
    }
    
    process {

        try {

            Set-PowerHighPerformance
            
        }
        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
            
            
            $ErrorMessage_6 = $_.Exception.Message
            write-host $ErrorMessage_6  -ForegroundColor Red
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


# Set-HighPerfPowerPlan
