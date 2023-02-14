$ScriptRoot_1001 = $null
$ScriptRoot_1001 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}


$ScriptRoot_DIR_1001 = $null
$ScriptRoot_DIR_1001 = $ScriptRoot_1001.Replace("Public", "")

function Install-TeamViewer {
    [CmdletBinding()]
    param (
        
    )
    
    begin {

        $date_9 = $null
        $date_9 = [System.DateTime]::Now.ToString("yyyy-MM-dd_HH_mm_ss")

        $TargetMachineName_9 = $null
        $TargetMachineName_9 = [System.Environment]::MachineName


        $CUSTOMCONFIG_ID_1 = $null
        $CUSTOMCONFIG_ID_1 = 'he26pyq'

        $API_TOKEN_1 = $null
        $API_TOKEN_1 = '7757967-7qRfr5r4Voq9MRxS7UKZ'

        $SETTINGSFILE_1 = $null
        $SETTINGSFILE_1 = "$ScriptRoot_DIR_1001\Settings\teamviewer_settings_export.tvopt"

        $Options_1 = $null
        $cmdArgs_1 = $null


        $MSI_FILE_HOST_PATH_1 = $null
        $MSI_FILE_HOST_PATH_1 = "$ScriptRoot_DIR_1001\msi\TeamViewerMSI\Host\TeamViewer_Host.msi"
        # $MSI_FILE_HOST_PATH_1 = "$ScriptRoot_1001\msi\TeamViewerMSI\Full\TeamViewer_Full.msi"

        # $MSI_FULL_FILE_PATH_1 = $null
        # $MSI_FULL_FILE_PATH_1 = "$ScriptRoot_1001\msi\TeamViewerMSI\Full\TeamViewer_Full.msi"
        
        $Log_File_9 = $null
        $Log_File_9 = "$($log_dir_1)\INSTALLER_MSI_$($date_9)_$($TargetMachineName_9).log"

  
        $options_1 = @(
            '/i'
            "$MSI_FILE_HOST_PATH_1"
            '/qn'
            "CUSTOMCONFIGID=$CUSTOMCONFIG_ID_1"
            "APITOKEN=$API_TOKEN_1"
            "/L*V"
            "$Log_File_9"
            '/promptrestart'
            'ASSIGNMENTOPTIONS="--reassign"'
            'ASSIGNMENTOPTIONS="--group-id=""g176322730"""' ##!Change this - This group ID belongs to a group call Venus   
            "SETTINGSFILE=$SETTINGSFILE_1"
        )

        $cmdArgs_1 = @(
            $options_1
        )

        $Script:SYS_ENV_SYSDIRECTORY = $null
        $Script:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory
        
    }
    
    process {

        try {

            Write-Host 'calling msi exec'
            & $SYS_ENV_SYSDIRECTORY\msiexec.exe @cmdArgs_1
            # & "C:\Windows\SysWOW64\msiexec.exe" @cmdArgs_1
            Write-Host 'Installing TeamViewer'
            start-sleep 60

            Write-host "Starting TeamViewer"
           
            
            $TeamViewer_exe_X86_1 = $null
            $TeamViewer_exe_X86_1 = "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
          
            if ((Test-Path -Path $TeamViewer_exe_X86_1 )) { 
                & "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
            }
            
            
            $TeamViewer_exe_X64_1 = $null
            $TeamViewer_exe_X64_1 = "C:\Program Files\TeamViewer\TeamViewer.exe"
          
            if ((Test-Path -Path $TeamViewer_exe_X64_1 )) { 
                & "C:\Program Files\TeamViewer\TeamViewer.exe"
            }

            Start-Sleep 60
            
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


# Install-TeamViewer