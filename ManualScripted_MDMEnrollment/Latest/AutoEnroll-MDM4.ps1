$RegKey ="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\"
$RegKey1 ="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"

New-Item -Path $RegKey -Name MDM
New-ItemProperty -Path $RegKey1 -Name AutoEnrollMDM -Value 1

$DeviceEnrollerPath = "$env:windir\system32\deviceenroller.exe"
$DeviceEnrollerArgs = "/c /AutoEnrollMDM"

Start-Process -FilePath $DeviceEnrollerPath -ArgumentList $DeviceEnrollerArgs -NoNewWindow