# Deploy Registry Settings with Intune

 

$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{60b78e88-ead8-445c-9cfd-0b87f74ea6cd}"

$Name = "Disabled"

$Value = "0" 

#0 meaning password proider is allowed/enabled
#1 meaning password proider is not allowed/disabled

 

If (!(Test-Path $Path))
{

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
}

Else {

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
}