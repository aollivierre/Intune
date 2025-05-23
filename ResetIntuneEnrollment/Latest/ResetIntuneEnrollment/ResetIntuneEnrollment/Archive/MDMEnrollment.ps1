if (-not $PSVersionTable.PSVersion -or $PSVersionTable.PSVersion.Major -lt 3) {
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
else {
    $scriptPath = $PSScriptRoot
}


#Export Details for the Service Manager and the Windows Update Settings
$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv"
if (!(Test-Path $CSVFilePath)) {
    New-Item -ItemType Directory -Path $CSVFilePath -Force | Out-Null
}

function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath
        # [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv"
    )

    $csvData = [PSCustomObject]@{
        TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        ComputerName = $env:COMPUTERNAME
        Message      = $Message
    }

    $csvData | Export-Csv -Path $CSVFilePath -Append -NoTypeInformation -Force
}

function Write-EventLogMessage {
    param (
        [string]$Message,
        [string]$LogName = 'PowerShellScriptLog'
    )

    # $source = 'PowerShell Script'
    # if (-not (Get-WinEvent -LogName $LogName -ErrorAction SilentlyContinue)) {
    #     New-EventLog -LogName $LogName -Source $source
    # }


    $source = "PowerShell Script"
    # $logName = "MyCustomLog"

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use New-EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            New-EventLog -LogName $logName -Source $source
            Write-Host "Event source '$source' created in log '$logName'"
        }
        else {
            Write-Host "Event source '$source' already exists"
        }
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
            Write-Host "Event source '$source' created in log '$logName'"
        }
        else {
            Write-Host "Event source '$source' already exists"
        }
    }

    # Write-EventLog -LogName $LogName -Source $source -EntryType Information -EventId 1 -Message $Message


    # $source = "MyCustomSource"
    # $logName = "MyCustomLog"
    $eventID = 1000
    # $eventMessage = "This is a test event log entry."

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use Write-EventLog
        Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId $eventID -Message $Message
        # Write-EventLog -LogName $LogName -Source $source -EntryType Information -EventId 1 -Message $Message
        Write-Host "Event log entry written using Write-EventLog"
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        $eventLog = New-Object System.Diagnostics.EventLog($logName)
        $eventLog.Source = $source
        $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $eventID)
        Write-Host "Event log entry written using System.Diagnostics.EventLog"
    }


}

function Write-Log {
    param (
        [string]$Message,
        # [string]$CSVFilePath = "C:\logs\$(Get-Date -Format 'yyyy-MM-dd')-$($env:COMPUTERNAME)-Log.csv"
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv"
    )

    Write-Output $Message
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    Write-EventLogMessage -Message $Message
}


# ... (rest of the script)

# Replace all Write-Output statements with Write-Log, for example:
# Write-Log -Message "$installedproduct $installedversion installed." -CSVFilePath $csvLogFile
# Do this for all Write-Output statements

# ... (rest of the script)



$computerName = $env:COMPUTERNAME
$logPath = "$scriptPath\exports\Logs\$computerName\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')\"
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}
$logFile = "${logPath}MDMEnrollment.log"
Start-Transcript -Path $logFile




# $key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'
# $keyinfo = Get-Item "HKLM:\$key"
# $url = $keyinfo.name
# $url = $url.Split("\")[-1]
# $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"

# New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force -ea SilentlyContinue;
# New-ItemProperty -LiteralPath $path  -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force -ea SilentlyContinue;
# New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force -ea SilentlyContinue;

# C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDM



# $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"
# New-Item -Path $registryPath

# $Name = "AutoEnrollMDM"
# $Name2 = "UseAADCredentialType"
# $value = "1"

# new-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
# new-ItemProperty -Path $registryPath -Name $name2 -Value $value -PropertyType DWORD -Force | Out-Null
# gpupdate /force


$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"

if (-not (Test-Path $registryPath)) {
    Write-Log -Message "Creating registry path: $registryPath"
    New-Item -Path $registryPath
} else {
    Write-Log -Message "Registry path already exists: $registryPath"
}

$Name = "AutoEnrollMDM"
$Name2 = "UseAADCredentialType"
$value = "1"

$commonRegistryParams = @{
    Path = $registryPath
    Value = $value
    PropertyType = 'DWORD'
    Force = $true
}

$autoEnrollMDMParams = @{
    Name = $Name
} + $commonRegistryParams

$useAADCredentialTypeParams = @{
    Name = $Name2
} + $commonRegistryParams

Write-Log -Message "Creating AutoEnrollMDM registry key"
New-ItemProperty @autoEnrollMDMParams | Out-Null

Write-Log -Message "Creating UseAADCredentialType registry key"
New-ItemProperty @useAADCredentialTypeParams | Out-Null




$key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'
$keyinfo = Get-Item "HKLM:\$key"
$url = $keyinfo.name
$url = $url.Split("\")[-1]
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"

$commonParams = @{
    LiteralPath = $path
    Force = $true
    ErrorAction = 'SilentlyContinue'
}

$mdmEnrollmentUrlParams = @{
    Name = 'MdmEnrollmentUrl'
    Value = 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc'
    PropertyType = 'String'
} + $commonParams

$mdmTermsOfUseUrlParams = @{
    Name = 'MdmTermsOfUseUrl'
    Value = 'https://portal.manage.microsoft.com/TermsofUse.aspx'
    PropertyType = 'String'
} + $commonParams

$mdmComplianceUrlParams = @{
    Name = 'MdmComplianceUrl'
    Value = 'https://portal.manage.microsoft.com/?portalAction=Compliance'
    PropertyType = 'String'
} + $commonParams

Write-Log -Message "Setting MdmEnrollmentUrl"
New-ItemProperty @mdmEnrollmentUrlParams

Write-Log -Message "Setting MdmTermsOfUseUrl"
New-ItemProperty @mdmTermsOfUseUrlParams

Write-Log -Message "Setting MdmComplianceUrl"
New-ItemProperty @mdmComplianceUrlParams

Write-Log -Message "Running deviceenroller.exe for MDM auto-enrollment"
C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDM





# Stop transcript
Stop-Transcript