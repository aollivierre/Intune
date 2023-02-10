$registryPath =  "HKLM:\Software\Policies\Microsoft\Windows\System"
$Name = "DefaultCredentialProvider"
$value = "{C5D7540A-CD51-453B-B22B-05305BA03F07}"
IF(!(Test-Path $registryPath))
{
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $name -Value $value `
-Force | Out-Null}
ELSE {

New-ItemProperty -Path $registryPath -Name $name -Value $value `
-Force | Out-Null}