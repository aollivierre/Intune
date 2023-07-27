function Reset-IntuneEnrollment {
    <#
    .SYNOPSIS
    Function for resetting device Intune management connection.

    .DESCRIPTION
    Function for resetting device Intune management connection.

    It will:
     - check actual Intune status on device
     - reset Hybrid AzureAD join
     - remove device records from Intune
     - remove Intune connection data and invoke re-enrollment

    .PARAMETER computerName
    (optional) Name of the computer.

    .EXAMPLE
    Reset-IntuneEnrollment

    .NOTES
    # How MDM (Intune) enrollment works https://techcommunity.microsoft.com/t5/intune-customer-success/support-tip-understanding-auto-enrollment-in-a-co-managed/ba-p/834780
    #>

    [CmdletBinding()]
    param (
        [string] $computerName = $env:COMPUTERNAME
    )

    $ErrorActionPreference = "Stop"



    function Invoke-MDMReenrollment {
        <#
        .SYNOPSIS
        Function for resetting device Intune management connection.

        .DESCRIPTION
        Force re-enrollment of Intune managed devices.

        It will:
        - remove Intune certificates
        - remove Intune scheduled tasks & registry keys
        - force re-enrollment via DeviceEnroller.exe

        .PARAMETER computerName
        (optional) Name of the remote computer, which you want to re-enroll.

        .PARAMETER asSystem
        Switch for invoking re-enroll as a SYSTEM instead of logged user.

        .EXAMPLE
        Invoke-MDMReenrollment

        Invoking re-enroll to Intune on local computer under logged user.

        .EXAMPLE
        Invoke-MDMReenrollment -computerName PC-01 -asSystem

        Invoking re-enroll to Intune on computer PC-01 under SYSTEM account.

        .NOTES
        https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/

        Based on work of MauriceDaly.
        #>

        [Alias("Invoke-IntuneReenrollment")]
        [CmdletBinding()]
        param (
            [string] $computerName,

            [switch] $asSystem
        )

        if ($computerName -and $computerName -notin "localhost", $env:COMPUTERNAME) {
            if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                throw "You don't have administrator rights"
            }
        }

 

        $scriptBlock = {
            param ($allFunctionDefs, $asSystem)

            try {
         

                # write-host "Checking for MDM certificate in computer certificate store"
                write-host "Checking for MDM certificate in computer certificate store"

                # Check&Delete MDM device certificate
                Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object Issuer -EQ "CN=Microsoft Intune MDM Device CA" | ForEach-Object {
                    # write-host " - Removing Intune certificate $($_.DnsNameList.Unicode)"
                    write-host " - Removing Intune certificate $($_.DnsNameList.Unicode)"
                    Remove-Item $_.PSPath
                }

                # Obtain current management GUID from Task Scheduler
                $EnrollmentGUID = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Microsoft*Windows*EnterpriseMgmt\*" } | Select-Object -ExpandProperty TaskPath -Unique | Where-Object { $_ -like "*-*-*" } | Split-Path -Leaf

                # Start cleanup process
                if (![string]::IsNullOrEmpty($EnrollmentGUID)) {
                    write-host "Current enrollment GUID detected as $([string]$EnrollmentGUID)"

                    # Stop Intune Management Exention Agent and CCM Agent services
                    write-host "Stopping MDM services"
                    if (Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue) {
                        write-host " - Stopping IntuneManagementExtension service..."
                        Stop-Service -Name IntuneManagementExtension
                    }
                    if (Get-Service -Name CCMExec -ErrorAction SilentlyContinue) {
                        write-host " - Stopping CCMExec service..."
                        Stop-Service -Name CCMExec
                    }

                    # Remove task scheduler entries
                    write-host "Removing task scheduler Enterprise Management entries for GUID - $([string]$EnrollmentGUID)"
                    Get-ScheduledTask | Where-Object { $_.Taskpath -match $EnrollmentGUID } | Unregister-ScheduledTask -Confirm:$false
                    # delete also parent folder
                    Remove-Item -Path "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmt\$EnrollmentGUID" -Force

                    $RegistryKeys = "HKLM:\SOFTWARE\Microsoft\Enrollments", "HKLM:\SOFTWARE\Microsoft\Enrollments\Status", "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked", "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled", "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions"
                    foreach ($Key in $RegistryKeys) {
                        write-host "Processing registry key $Key"
                        # Remove registry entries
                        if (Test-Path -Path $Key) {
                            # Search for and remove keys with matching GUID
                            write-host " - GUID entry found in $Key. Removing..."
                            Get-ChildItem -Path $Key | Where-Object { $_.Name -match $EnrollmentGUID } | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
                        }
                    }

                    # Start Intune Management Extension Agent service
                    write-host "Starting MDM services"
                    if (Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue) {
                        write-host " - Starting IntuneManagementExtension service..."
                        Start-Service -Name IntuneManagementExtension
                    }
                    if (Get-Service -Name CCMExec -ErrorAction SilentlyContinue) {
                        write-host " - Starting CCMExec service..."
                        Start-Service -Name CCMExec
                    }

                    # Sleep
                    write-host "Waiting for 30 seconds prior to running DeviceEnroller"
                    Start-Sleep -Seconds 30

                    # Start re-enrollment process
                    write-host "Calling: DeviceEnroller.exe /C /AutoenrollMDM"
                    if ($asSystem) {
                        Invoke-AsSystem -runAs SYSTEM -scriptBlock { Start-Process -FilePath "$env:WINDIR\System32\DeviceEnroller.exe" -ArgumentList "/C /AutoenrollMDM" -NoNewWindow -Wait -PassThru }
                    }
                    else {
                        Start-Process -FilePath "$env:WINDIR\System32\DeviceEnroller.exe" -ArgumentList "/C /AutoenrollMDM" -NoNewWindow -Wait -PassThru
                    }
                }
                else {
                    throw "Unable to obtain enrollment GUID value from task scheduler. Aborting"
                }
            }
            catch [System.Exception] {
                throw "Error message: $($_.Exception.Message)"
            }
        }

        $param = @{
            scriptBlock  = $scriptBlock
            argumentList = $allFunctionDefs, $asSystem
        }

        if ($computerName -and $computerName -notin "localhost", $env:COMPUTERNAME) {
            $param.computerName = $computerName
        }

        Invoke-Command @param
    }

    function Get-IntuneEnrollmentStatus {
        <#
        .SYNOPSIS
        Function for checking whether computer is managed by Intune (fulfill all requirements).

        .DESCRIPTION
        Function for checking whether computer is managed by Intune (fulfill all requirements).
        What is checked:
        - device is AAD joined
        - device is joined to Intune
        - device has valid Intune certificate
        - device has Intune sched. tasks
        - device has Intune registry keys
        - Intune service exists

        Returns true or false.

        .PARAMETER computerName
        (optional) name of the computer to check.

        .PARAMETER checkIntuneToo
        Switch for checking Intune part too (if device is listed there).

        .EXAMPLE
        Get-IntuneEnrollmentStatus

        Check Intune status on local computer.

        .EXAMPLE
        Get-IntuneEnrollmentStatus -computerName ae-50-pc

        Check Intune status on computer ae-50-pc.

        .EXAMPLE
        Get-IntuneEnrollmentStatus -computerName ae-50-pc -checkIntuneToo

        Check Intune status on computer ae-50-pc, plus connects to Intune and check whether ae-50-pc exists there.
        #>

        [CmdletBinding()]
        param (
            [string] $computerName,

            [switch] $checkIntuneToo
        )

        if (!$computerName) { $computerName = $env:COMPUTERNAME }


        $scriptBlock = {
            param ($checkIntuneToo, $intuneObj)

            #region dsregcmd checks
            $dsregcmd = dsregcmd.exe /status
            $azureAdJoined = $dsregcmd | Select-String "AzureAdJoined : YES"
            if (!$azureAdJoined) {
                ++$intuneNotJoined
                write-host "Device is NOT AAD joined"
            }

            $tenantName = $dsregcmd | Select-String "TenantName : .+"
            $MDMUrl = $dsregcmd | Select-String "MdmUrl : .+"
            if (!$tenantName -or !$MDMUrl) {
                ++$intuneNotJoined
                write-host "Device is NOT Intune joined"
            }
            #endregion dsregcmd checks

            #region certificate checks
            $MDMCert = Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object Issuer -EQ "CN=Microsoft Intune MDM Device CA"
            if (!$MDMCert) {
                ++$intuneNotJoined
                write-host "Intune certificate is missing"
            }
            elseif ($MDMCert.NotAfter -lt (Get-Date) -or $MDMCert.NotBefore -gt (Get-Date)) {
                ++$intuneNotJoined
                write-host "Intune certificate isn't valid"
            }
            #endregion certificate checks

            #region sched. task checks
            $MDMSchedTask = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Microsoft*Windows*EnterpriseMgmt\*" -and $_.TaskName -eq "PushLaunch" }
            $enrollmentGUID = $MDMSchedTask | Select-Object -ExpandProperty TaskPath -Unique | Where-Object { $_ -like "*-*-*" } | Split-Path -Leaf
            if (!$enrollmentGUID) {
                ++$intuneNotJoined
                write-host "Synchronization sched. task is missing"
            }
            #endregion sched. task checks

            #region registry checks
            if ($enrollmentGUID) {
                # $missingRegKey = @()
                $registryKeys = "HKLM:\SOFTWARE\Microsoft\Enrollments", "HKLM:\SOFTWARE\Microsoft\Enrollments\Status", "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked", "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled", "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions"
                foreach ($key in $registryKeys) {
                    if (!(Get-ChildItem -Path $key -ea SilentlyContinue | Where-Object { $_.Name -match $enrollmentGUID })) {
                        write-host "Registry key $key is missing"
                        ++$intuneNotJoined
                    }
                }
            }
            #endregion registry checks

            #region service checks
            $MDMService = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
            if (!$MDMService) {
                ++$intuneNotJoined
                write-host "Intune service IntuneManagementExtension is missing"
            }
            if ($MDMService -and $MDMService.Status -ne "Running") {
                write-host "Intune service IntuneManagementExtension is not running"
            }
            #endregion service checks

            if ($intuneNotJoined) {
                return $false
            }
            else {
                return $true
            }
        }

        $param = @{
            scriptBlock  = $scriptBlock
            argumentList = $checkIntuneToo, $intuneObj
        }
        if ($computerName -and $computerName -notin "localhost", $env:COMPUTERNAME) {
            $param.computerName = $computerName
        }

        Invoke-Command @param
    }
    #endregion helper functions


    write-host "Checking actual Intune connection status"
    if (Get-IntuneEnrollmentStatus -computerName $computerName) {
        $choice = ""
        while ($choice -notmatch "^[Y|N]$") {
            $choice = Read-Host "It seems device has working Intune connection. Continue? (Y|N)"
        }
        if ($choice -eq "N") {
            break
        }
    }

   
    write-host "Waiting"

    Start-Sleep 10


    # write-host "Invoking re-enrollment of Intune connection"
    write-host "Invoking re-enrollment of Intune connection"
    #******** Invoke-MDMReenrollment -computerName $computerName -asSystem

    # check certificates
    $i = 30
  
    write-host "Waiting for Intune certificate creation"
    write-host "two certificates should be created in Computer Personal cert. store (issuer: MS-Organization-Access, MS-Organization-P2P-Access"
    while (!(Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object { $_.Issuer -match "CN=Microsoft Intune MDM Device CA" }) -and $i -gt 0) {
        Start-Sleep 1
        --$i
        $i
    }

    if ($i -eq 0) {
        write-host "Intune certificate (issuer: Microsoft Intune MDM Device CA) isn't created (yet?)" -Level "WARNING"
    }
    else {
        write-host "DONE :)"
    }
}


Reset-IntuneEnrollment
write-host "Reset Intune Enrollment is now completed"