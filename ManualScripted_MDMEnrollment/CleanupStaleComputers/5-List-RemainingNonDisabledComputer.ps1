# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Set the LDAP path for the Disabled Computers container
$containerPath = "CN=Disabled Computers,DC=CPHA,DC=local"

# Retrieve computers from the Disabled Computers container that are not disabled
$enabledComputers = Get-ADComputer -Filter 'Enabled -eq $true' -SearchBase $containerPath -Properties Name, Enabled

# Output the list of enabled computers in the Disabled Computers container
Write-Host "List of enabled computers in the Disabled Computers container:"
$enabledComputers | Format-Table -Property Name, Enabled -AutoSize
