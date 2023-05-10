# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Get the root domain distinguished name
$rootDomain = (Get-ADDomain).DistinguishedName

# Find the distinguished name of the "Disabled" container
$disabledContainerDN = (Get-ADObject -Filter {Name -eq "Disabled" -and ObjectClass -eq "container"}).DistinguishedName

# Check if the "Disabled" container exists
if (!$disabledContainerDN) {
    Write-Host "The 'Disabled' container does not exist in the root domain. Creating it now..."
    # Create the new container called "Disabled" in the root domain
    New-ADObject -Type container -Name "Disabled" -Path $rootDomain

    # Get the distinguished name of the "Disabled" container
    $disabledContainerDN = (Get-ADObject -Filter {Name -eq "Disabled" -and ObjectClass -eq "container"}).DistinguishedName
}

# Check if the "Disabled Computers" sub-container exists
$disabledComputersDN = (Get-ADObject -Filter {Name -eq "Disabled Computers" -and ObjectClass -eq "container"} -SearchBase $disabledContainerDN).DistinguishedName
if (!$disabledComputersDN) {
    Write-Host "The 'Disabled Computers' sub-container does not exist. Creating it now..."
    # Create the new sub-container called "Disabled Computers" in the "Disabled" container
    New-ADObject -Type container -Name "Disabled Computers" -Path $disabledContainerDN
} else {
    Write-Host "The 'Disabled Computers' sub-container already exists."
}
