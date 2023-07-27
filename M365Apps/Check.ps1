# My detection script was literally
# Intune Detection Script
# Tests for the existence of either O365 Apps for Enterprise or O365 Apps for Business

$O365Apps = Get-Item HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.GetValue("DisplayName") -like "Microsoft 365 Apps*"}
    
If ($O365Apps) {
    Write-Host "O365 App Detected - $($O365Apps.PSChildName)"
    Exit 0
}
Else {
    Write-Host "O365 Apps not found"
    Exit 1
}






$RegistryKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$M365Apps = "Microsoft 365 Apps"
# $M365AppsCheck = $RegistryKeys | Where-Object { $_.GetValue("DisplayName") -match $M365Apps } // Commented out as issues found
$M365AppsCheck = $RegistryKeys | Get-ItemProperty | Where-Object { $_.DisplayName -match $M365Apps }
if ($M365AppsCheck) {
    # Write-LogEntry -Value "Microsoft 365 Apps detected OK" -Severity 1
    Write-Output "Microsoft 365 Apps Detected"
	Exit 0
   }else{
    # Write-LogEntry -Value "Microsoft 365 Apps not detected" -Severity 2
    Exit 1
}
