function Write-Log {
    param (
        [string]$Message
    )
    $logFile = "ScriptLog.txt"
    $timeStamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    Add-Content -Path $logFile -Value "[$timeStamp] $Message"
}

function CheckEventLog {
    param (
        [string]$Log,
        [int]$EventId
    )
    Get-WinEvent -LogName $Log -FilterXPath "*[System[EventID=$EventId]]"
}

# Check dsregcmd /status
Write-Log "Dsregcmd /status output:"
$dsregStatus = dsregcmd /status
Write-Log $dsregStatus

# Check Event Logs
# Write-Log "Checking Event Logs..."
# $beforeScript = CheckEventLog -Log "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" -EventId 0x801800264

# Run the rest of your script here

# Check Event Logs after the script
# $afterScript = CheckEventLog -Log "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" -EventId 0x801800264



Write-Log "Checking Event Logs..."
$errorCodes = @{
    0x80190026 = "Error when a device was previously enrolled with SCCM"
    0x80180026 = "Error when the scheduled task is executed"
    0x8018002A = "Error when the scheduled task is executed"
    0x8018002B = "Error when the scheduled task is executed"
    0x80180001 = "Error when the scheduled task is executed"
    0x80192EE2 = "Error when the scheduled task is executed"
    0x82AA0008 = "Error when the scheduled task is executed"
}

$decimalErrorCodes = $errorCodes.Keys | ForEach-Object {
    [int]::Parse($_, [System.Globalization.NumberStyles]::HexNumber)
}

$eventLogPath = "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"

foreach ($errorCode in $errorCodes.Keys) {
    $decimalErrorCode = [int]::Parse($errorCode, [System.Globalization.NumberStyles]::HexNumber)
    $events = Get-WinEvent -FilterHashTable @{ LogName = $eventLogPath; EventId = $decimalErrorCode } -ErrorAction SilentlyContinue
    if ($events) {
        Write-Host "Found events with error code: $($errorCode.ToString('X')) - $($errorCodes[$errorCode])"
        foreach ($event in $events) {
            Write-Host $event.Message
        }
    }
}





if ($beforeScript -or $afterScript) {
    Write-Log "Error Code 0x80180026 detected. Ensure your device is hybrid Azure AD joined and the Disable MDM enrollment policy is not preventing your MDM enrollment."
}

$eventID75 = CheckEventLog -Log "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" -EventId 75
$eventID76 = CheckEventLog -Log "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" -EventId 76

if ($eventID75) {
    Write-Log "Event ID 75 found. Auto-enrollment completed successfully."
} elseif ($eventID76) {
    Write-Log "Event ID 76 found. Auto-enrollment failed."
} else {
    Write-Log "Neither Event ID 75 nor 76 found. Auto-enrollment did not trigger at all."
}

# Check Task Scheduler
Write-Log "Checking Task Scheduler..."
$taskPath = "\Microsoft\Windows\EnterpriseMgmt"
$taskExists = Get-ScheduledTask -TaskPath $taskPath | Where-Object { $_.TaskName -eq 'MDM' }

if ($taskExists) {
    Write-Log "Enable Automatic MDM enrollment using default Azure AD credentials group policy has been successfully deployed."
} else {
    Write-Log "Enable Automatic MDM enrollment using default Azure AD credentials group policy has not been successfully deployed."
}

$eventID107 = CheckEventLog -Log "Microsoft-Windows-TaskScheduler/Operational" -EventId 107
$eventID102 = CheckEventLog -Log "Microsoft-Windows-TaskScheduler/Operational" -EventId 102

if ($eventID107) {
    Write-Log "Event ID 107 found. Auto-enrollment task was triggered."
} else {
    Write-Log "Event ID 107 not found. Auto-enrollment task was not triggered."
}

if ($eventID102) {
    Write-Log "Event ID 102 found. Auto-enrollment task was completed."
} else {
    Write-Log "Event ID 102 not found. Auto-enrollment task was not completed."
}
