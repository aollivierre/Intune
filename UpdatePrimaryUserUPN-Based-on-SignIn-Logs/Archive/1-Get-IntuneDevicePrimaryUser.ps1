# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "AuditLog.Read.All", "User.Read.All"

function Get-IntuneDevicesWithPrimaryUserAndSignInLogs {
    # Retrieve all Intune-managed devices
    $devices = Get-MgDeviceManagementManagedDevice -All

    $deviceUserSignIns = @()

    foreach ($device in $devices) {
        $deviceDetails = "" | Select-Object DeviceId, DeviceName, PrimaryUserId, PrimaryUserDisplayName, LastSignInUserId, LastSignInTime

        $deviceDetails.DeviceId = $device.Id
        $deviceDetails.DeviceName = $device.DeviceName

        # Get primary user of the device
        $primaryUser = Get-MgDeviceManagementManagedDeviceUser -ManagedDeviceId $device.Id
        if ($primaryUser -and $primaryUser.Count -gt 0) {
            $primaryUserId = $primaryUser[0].Id
            $deviceDetails.PrimaryUserId = $primaryUserId

            # Get primary user details
            $userDetails = Get-MgUser -UserId $primaryUserId
            $deviceDetails.PrimaryUserDisplayName = $userDetails.DisplayName

            # Get the latest sign-in log for the primary user
            $signInLogs = Get-MgAuditLogSignIn -Filter "userId eq '$primaryUserId'" -Top 1 -Orderby "createdDateTime desc"
            if ($signInLogs -and $signInLogs.Count -gt 0) {
                $deviceDetails.LastSignInUserId = $signInLogs[0].UserId
                $deviceDetails.LastSignInTime = $signInLogs[0].CreatedDateTime
            }
        }

        $deviceUserSignIns += $deviceDetails
    }

    return $deviceUserSignIns
}

# Execute the function and display the results
$deviceUserSignIns = Get-IntuneDevicesWithPrimaryUserAndSignInLogs
$deviceUserSignIns | Format-Table -AutoSize
