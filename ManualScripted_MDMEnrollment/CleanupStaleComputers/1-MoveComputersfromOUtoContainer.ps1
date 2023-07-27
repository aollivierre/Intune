# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Define the source OU and target container
$SourceOU = "OU=cpha disabled computers,DC=CPHA,DC=local"
$TargetContainer = "CN=Disabled Computers,DC=CPHA,DC=local"

# Count computer objects in the source OU and target container before the move
$SourceCountBefore = (Get-ADComputer -Filter * -SearchBase $SourceOU).Count
$TargetCountBefore = (Get-ADComputer -Filter * -SearchBase $TargetContainer).Count

# Display counts before the move
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $($SourceOU): $SourceCountBefore computers" -ForegroundColor Yellow
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $($TargetContainer): $TargetCountBefore computers" -ForegroundColor Yellow

# Get all computers in the source OU and move them to the target container
$Computers = Get-ADComputer -Filter * -SearchBase $SourceOU
foreach ($Computer in $Computers) {
    Move-ADObject -Identity $Computer.ObjectGUID -TargetPath $TargetContainer
    Write-Host "Moved $($Computer.Name) to $TargetContainer"
}

# Count computer objects in the source OU and target container after the move
$SourceCountAfter = (Get-ADComputer -Filter * -SearchBase $SourceOU).Count
$TargetCountAfter = (Get-ADComputer -Filter * -SearchBase $TargetContainer).Count

# Display counts after the move
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $($SourceOU): $SourceCountAfter computers" -ForegroundColor Green
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $($TargetContainer): $TargetCountAfter computers" -ForegroundColor Green
