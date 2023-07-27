# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Set variables for the stale duration
$daysInactive = 90

# Calculate the cutoff date
$currentDate = Get-Date
$cutoffDate = $currentDate.AddDays(-$daysInactive)

# Retrieve computers from the entire domain
$computers = Get-ADComputer -Filter * -Properties LastLogonDate, LastLogon, OperatingSystem, DistinguishedName | Where-Object { $_.Name -ne "AZUREADSSOACC" }

# Filter computers based on LastLogon and LastLogonDate
$inactiveComputers = $computers | Where-Object { (-not $_.LastLogonDate -or $_.LastLogonDate -lt $cutoffDate) -and (-not $_.LastLogon -or [DateTime]::FromFileTime($_.LastLogon) -lt $cutoffDate) }

# Set the dynamic export path and create it if it does not exist
$exportPath = "C:\Code\Intune\ManualScripted_MDMEnrollment\CleanupStaleComputers\Exports\$(Get-Date -Format 'yyyy-MM-dd')\"
if (!(Test-Path $exportPath)) {
    New-Item -ItemType Directory -Path $exportPath | Out-Null
}

# Export inactive computers to a CSV file
$inactiveComputers | Sort-Object LastLogonDate | Select-Object Name, LastLogonDate, @{Name='LastLogon';Expression={[DateTime]::FromFileTime($_.LastLogon)}}, OperatingSystem, DistinguishedName | Export-Csv "${exportPath}inactive_computers.csv" -NoTypeInformation

# Output the count of computers in the domain and the count of inactive computers to the console
Write-Host "Total number of computers in the domain: $($computers.Count)" -ForegroundColor Yellow
Write-Host "Total number of computers that have not logged in for more than $daysInactive days: $($inactiveComputers.Count)" -ForegroundColor Red
