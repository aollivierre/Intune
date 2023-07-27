# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Define the input CSV file path and target OU
$CsvFilePath = "C:\Code\Intune\ManualScripted_MDMEnrollment\MoveADObjects\CPHA_UnEnrolled_In_Intune_22_Devices_AD_Import.csv"
$TargetOU = "OU=PendingIntuneEnrollment,OU=CPHA-Computers,OU=CPHA Managed,DC=CPHA,DC=local"

# Read the CSV file and move the computers to the target OU
$Computers = Import-Csv -Path $CsvFilePath
foreach ($Computer in $Computers) {
    $ComputerName = $Computer.ComputerName
    $ADComputer = Get-ADComputer -Identity $ComputerName -ErrorAction SilentlyContinue
    if ($ADComputer) {
        Move-ADObject -Identity $ADComputer.ObjectGUID -TargetPath $TargetOU
        Write-Host "Moved $ComputerName to $TargetOU"
    } else {
        Write-Warning "Computer $ComputerName not found in Active Directory"
    }
}