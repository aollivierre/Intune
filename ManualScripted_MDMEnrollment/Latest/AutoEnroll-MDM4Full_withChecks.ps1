$RegKey ="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\"
$RegKey1 ="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"

if (-not (Test-Path $RegKey1)) {
    New-Item -Path $RegKey -Name MDM
}

$AutoEnrollMDMPropertyName = "AutoEnrollMDM"
if (-not (Get-ItemProperty -Path $RegKey1 -Name $AutoEnrollMDMPropertyName -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $RegKey1 -Name $AutoEnrollMDMPropertyName -Value 1
}

$DeviceEnrollerPath = "$env:windir\system32\deviceenroller.exe"
$DeviceEnrollerArgs = "/c /AutoEnrollMDM"

Start-Process -FilePath $DeviceEnrollerPath -ArgumentList $DeviceEnrollerArgs -NoNewWindow