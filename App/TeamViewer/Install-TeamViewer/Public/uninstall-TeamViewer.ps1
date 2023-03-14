# Set ScripRoot variable to the path which the script is executed from
$ScriptRoot4 = $null
$ScriptRoot4 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}



function uninstall-teamviewer {
    [CmdletBinding()]
    param (
        
    )
    
    begin {

        $ScriptRoot4Dir = $null
        $ScriptRoot4Dir = $ScriptRoot4.Replace("Public", "")

        $MSI_Folder_Dir_4 = $null
        $MSI_Folder_Dir_4 = $ScriptRoot4Dir + "msi"

        $logdir_4 = $null
        $logdir_4 = $ScriptRoot4Dir + "logs"
        if (!(Test-Path -Path $logdir_4 )) { 
            New-Item -Force -ItemType directory -Path $logdir_4
  
        }

        $TargetMachineName_2 = $null
        $TargetMachineName_2 = [System.Environment]::MachineName


        $MSI_FILE_HOST_PATH_2 = $null
        $MSI_FILE_HOST_PATH_2 = "$MSI_Folder_Dir_4\TeamViewerMSI\Host\TeamViewer_Host.msi"

        $MSI_FULL_FILE_PATH_2 = $null
        $MSI_FULL_FILE_PATH_2 = "$MSI_Folder_Dir_4\TeamViewerMSI\Full\TeamViewer_Full.msi"
        
        $date_2 = $null
        $date_2 = [System.DateTime]::Now.ToString("yyyy-MM-dd_HH_mm_ss")
        
        $Logfile_2 = $null
        $Logfile_2 = "$($logdir_4)\UNINSTALLER_MSI_$($date_2)_$($TargetMachineName_2).log"

        $Script:SYS_ENV_SYSDIRECTORY = $null
        $Script:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory


        
    }
    
    process {


        try {

            write-host "Uninstalling TeamViewer"
            & $SYS_ENV_SYSDIRECTORY\msiexec.exe /x $MSI_FILE_HOST_PATH_2  /qn /L*V $Logfile_2
            & $SYS_ENV_SYSDIRECTORY\msiexec.exe /x $MSI_FULL_FILE_PATH_2 /qn /L*V $Logfile_2
            & $SYS_ENV_SYSDIRECTORY\msiexec.exe /uninstall $MSI_FILE_HOST_PATH_2 /qn
            & $SYS_ENV_SYSDIRECTORY\msiexec.exe /uninstall $MSI_FULL_FILE_PATH_2 /qn

            Start-Sleep 60

            $TeamViewer_Uninstaller_X86_2 = $null
            $TeamViewer_Uninstaller_X86_2 = "C:\Program Files (x86)\TeamViewer\Uninstall.exe"

            if ((Test-Path -Path $TeamViewer_Uninstaller_X86_2 )) { 
                & "C:\Program Files (x86)\TeamViewer\Uninstall.exe" /S
            }

            $TeamViewer_Uninstaller_X64_2 = $null
            $TeamViewer_Uninstaller_X64_2 = "C:\Program Files\TeamViewer\Uninstall.exe"

            if ((Test-Path -Path $TeamViewer_Uninstaller_X64_2 )) {
                & "C:\Program Files\TeamViewer\Uninstall.exe" /S
            }

            $MULTIPLE_PATH_1 = $null
            $MULTIPLE_PATH_1 = @(
                'HKLM:\SOFTWARE\TeamViewer'
                'HKLM:\SOFTWARE\WOW6432Node\TeamViewer'
                'HKCU:\.DEFAULT\Software\Wow6432Node\TeamViewer'
                'HKCU:\.DEFAULT\Software\TeamViewer'
                'HKCU:\S-1-5-18\Software\TeamViewer'
                'HKCU:\S-1-5-18\Software\Wow6432Node\TeamViewer'
                'HKCU:\S-1-5-18\Software\TeamViewer'
    
                'C:\Program Files\Teamviewer'
                'c:\Program Files (x86)\TeamViewer'
                '%LOCALAPPDATA%\Temp\TeamViewer'

            )

            foreach ($SINGLE_PATH_1 in $MULTIPLE_PATH_1) {
                
                $TeamViewer_PATH_to_UNINSTALL_EXIST_1 = $null
                $TeamViewer_PATH_to_UNINSTALL_EXIST_1 = Test-Path $SINGLE_PATH_1

                if ($TeamViewer_PATH_to_UNINSTALL_EXIST_1) {
                    Remove-Item -Path $SINGLE_PATH_1 -Force -Recurse
                }

            }

            
        }
        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
            
            
            $ErrorMessage_7 = $_.Exception.Message
            write-host $ErrorMessage_7  -ForegroundColor Red
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

# uninstall-teamviewer
  