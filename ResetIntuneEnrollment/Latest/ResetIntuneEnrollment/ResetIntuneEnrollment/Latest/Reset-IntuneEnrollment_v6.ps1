# Check if running as admin and if not, relaunch as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    # Relaunch as an admin
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# Placeholder for Install-RequireModules function

#MSI URLS
# https://github.com/MSEndpointMgr/IntuneDebugToolkit
# https://naprodimedatasec.azureedge.net/IntuneWindowsAgent.msi

# MSI Installer paths
$msiOneTrace = "path\to\OneTrace.msi"
$msiIntuneExtension = "path\to\IntuneExtension.msi"
$msiIntuneToolkit = "path\to\IntuneToolkit.msi"

# Install MSI Installers silently with no logging
Start-Process 'msiexec.exe' -ArgumentList "/i $msiOneTrace /qn /norestart" -NoNewWindow -Wait
Start-Process 'msiexec.exe' -ArgumentList "/i $msiIntuneExtension /qn /norestart" -NoNewWindow -Wait
Start-Process 'msiexec.exe' -ArgumentList "/i $msiIntuneToolkit /qn /norestart" -NoNewWindow -Wait

# Open IME Logs with OneTrace
# This assumes that you have a method to open logs with OneTrace.

# Placeholder to Open Intune Debug Toolkit (Real Time listener for logs) shortcut

# Function to Invoke Windows Provisioning Package
function Invoke-WindowsProvisioningPackage
{
    # Define the provisioning package path
    $packagePath = "path\to\package.ppkg"

    # Invoke the provisioning package
    # Add your code here
}

# Placeholder to copy the RunMdmDiagnostics function from v4 interactive
# Placeholder to copy the Get-IntuneLog function from v4 interactive
# Placeholder to copy the MG Graph and use the new Get-MG cmdlets

# Placeholder to replace the following in the Reset-IntuneEnrollment Script
# a. Replace CM Trace with OneTrace
# b. Replace Open-Intunelog with the function outside of that
# c. Placeholder to pause the script until the admin initiates a Start-AdSyncSynccycle after leaving dsregcmd /status

# Add logging with built in PowerShell Write-Host time stamped and color coded
# function LogWrite
# {
#     Param ([string]$logstring)

#     $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
#     $output = "$stamp - $logstring"
#     Write-Host $output -ForegroundColor Cyan
# }
