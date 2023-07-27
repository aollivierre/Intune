function Export-IntuneDevices {
    [CmdletBinding()]
    param (
        [string]$OutputPath = (Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath 'IntuneDevices.csv')
    )

    Begin {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting the Intune device export process..." -ForegroundColor Yellow
        $devices = @()
    }

    Process {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Retrieving devices from Intune..." -ForegroundColor Cyan

        try {
            $devices = Get-MgDeviceManagementManagedDevice -All
        }
        catch {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to retrieve devices. Check your Graph permissions and try again." -ForegroundColor Red
            return
        }

        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Successfully retrieved $($devices.Count) devices. Exporting to CSV..." -ForegroundColor Green

        try {
            # $devices | Select-Object Id, DisplayName, Manufacturer, Model, OperatingSystem, OperatingSystemVersion, SerialNumber, Imei, Meid, PhoneNumber, IsSupervised, IsCompliant | Export-Csv -Path $OutputPath -NoTypeInformation -Force
            $devices | Export-Csv -Path $OutputPath -NoTypeInformation -Force
        }
        catch {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Failed to export devices to CSV. Check the output path and try again." -ForegroundColor Red
            return
        }
    }

    End {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Intune device export completed successfully. Devices exported to: $OutputPath" -ForegroundColor Green
    }
}


# Export-IntuneDevices
# Or
Export-IntuneDevices -OutputPath "C:\Code\CB\Intune\Exports\LHC_Detailed_IntuneManagedDevices.csv"
