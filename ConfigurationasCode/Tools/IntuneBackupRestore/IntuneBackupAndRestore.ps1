function Install-RequiredModules {

    # $requiredModules = @("Microsoft.Graph", "Microsoft.Graph.Authentication")
    $requiredModules = @("Microsoft.Graph.Intune", "IntuneBackupAndRestore")

    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {

            write-host "Installing module: $module"
            Install-Module -Name $module -Force
            write-host "Module: $module has been installed"
        }
        else {
            write-host "Module $module is already installed"
        }
    }


    # $ImportedModules = @("Microsoft.Graph.Identity.DirectoryManagement", "Microsoft.Graph.Authentication")
    $ImportedModules = @("Microsoft.Graph.Intune", "IntuneBackupAndRestore")
    
    foreach ($Importedmodule in $ImportedModules) {
        if ((Get-Module -ListAvailable -Name $Importedmodule)) {
            write-host "Importing module: $Importedmodule"
            Import-Module -Name $Importedmodule
            write-host "Module: $Importedmodule has been Imported"
        }
    }
}
# Call the function to install the required modules and dependencies
Install-RequiredModules
write-host "All modules installed"


# Install IntuneBackupAndRestore from the PowerShell Gallery
# Install-Module -Name IntuneBackupAndRestore

# 1. Connect to Microsoft Graph
# Connect-MSGraph

# 2. Retrieve the tenant name and details using Get-Organization
$orgInfo = Get-Organization
$tenantName = $orgInfo | Select-Object -ExpandProperty DisplayName

# Save org info to orginfo.txt
# $orgInfo | Out-File -Path "C:\Code\CB\Intune\ConfigurationasCode\Backups\orginfo.txt"

# If tenant name is null or empty, provide an error and exit
if ([string]::IsNullOrEmpty($tenantName)) {
    Write-Host "$(Get-Date -Format "HH:mm:ss"): Unable to retrieve tenant name." -ForegroundColor Red
    exit
}

# Sanitize the tenant name by removing spaces
$cleanTenantName = $tenantName -replace ' ', ''

# Define the datetime format you want
$datetime = Get-Date -Format "yyyy-MM-dd_HHmmss"

# Build the backup path dynamically using the sanitized tenant name
$backupPath = "C:\Code\CB\Intune\ConfigurationasCode\Backups\$cleanTenantName\$datetime"

# Check if the folder exists, if not, create it
if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath
    # Provide feedback
    Write-Host "$(Get-Date -Format "HH:mm:ss"): Created directory for tenant $cleanTenantName at $backupPath" -ForegroundColor Green
} else {
    # Provide feedback
    Write-Host "$(Get-Date -Format "HH:mm:ss"): Directory for tenant $cleanTenantName already exists at $backupPath" -ForegroundColor Yellow
}


# Save org info to orginfo.txt
$orgInfo | Out-File -filePath "$backupPath\orginfo.txt"

# 3. Start the Intune Backup
# Start-IntuneBackup -Path $backupPath