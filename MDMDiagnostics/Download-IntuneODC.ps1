mkdir C:\Temp
Set-Location C:\Temp
dsregcmd.exe /status
# wget https://aka.ms/intunexml -outfile Intune.xml
Invoke-WebRequest https://aka.ms/intunexml -outfile C:\Code\CB\Intune\MDMDiagnostics\Intune.xml
# wget https://aka.ms/intuneps1 -outfile IntuneODCStandAlone.ps1
Invoke-WebRequest https://aka.ms/intuneps1 -outfile C:\Code\CB\Intune\MDMDiagnostics\IntuneODCStandAlone.ps1
powerShell -ExecutionPolicy Bypass -File .\IntuneODCStandAlone.ps1