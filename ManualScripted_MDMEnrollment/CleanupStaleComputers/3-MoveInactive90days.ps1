# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Start transcript
$logPath = "C:\Code\Intune\ManualScripted_MDMEnrollment\CleanupStaleComputers\logs\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')\"
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath | Out-Null
}
$logFile = "${logPath}Move_Computers.log"
Start-Transcript -Path $logFile

# Get the root domain distinguished name
$rootDomain = (Get-ADDomain).DistinguishedName

# Define the target container's distinguished name
$targetContainer = "CN=Disabled Computers,$rootDomain"

# Import the CSV file
$csvFile = "C:\Code\Intune\ManualScripted_MDMEnrollment\CleanupStaleComputers\Exports\2023-05-09\inactive_computers.csv"
$computers = Import-Csv $csvFile

# Get the total number of computers before the move
# $computersBefore = (Get-ADComputer -Filter *).Count
# $computersInOUBefore = (Get-ADComputer -Filter * -SearchBase $workstationsOU.DistinguishedName).Count

# Move the computers listed in the CSV file to the target container and count moved computers
$movedCount = 0
foreach ($computer in $computers) {
    try {
        $computerName = $computer.Name
        $computerObject = Get-ADComputer $computerName
        Move-ADObject -Identity $computerObject -TargetPath $targetContainer

        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Moved $computerName to Disabled Computers container." -ForegroundColor Green
        $movedCount++
    } catch {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to move $computerName. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Get the total number of computers after the move
# $computersAfter = (Get-ADComputer -Filter *).Count

# $computersInOUAfter = (Get-ADComputer -Filter * -SearchBase $workstationsOU.DistinguishedName).Count

# Output summary to the console
Write-Host "`nSummary:" -ForegroundColor Yellow
# Write-Host "Total computers in OU before move: $computersInOUBefore" -ForegroundColor Cyan
Write-Host "Total computers moved: $movedCount" -ForegroundColor Green
# Write-Host "Total computers in OU after move: $computersInOUAfter" -ForegroundColor Cyan


# Stop transcript
Stop-Transcript
