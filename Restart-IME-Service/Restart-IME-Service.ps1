# CAN: PowerShell script to restart the Intune Management Extension service

# Define the service name
$serviceName = "IntuneManagementExtension"

# Check if the service exists
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {

    # Output service status to the console
    Write-Output "Service [$serviceName] found. Attempting to restart..."

    try {
        # Attempt to restart the service
        Restart-Service -Name $serviceName -Force -ErrorAction Stop
        Write-Output "Service [$serviceName] has been restarted successfully!"
    } catch {
        # Handle any errors that may occur during the restart
        Write-Error "Failed to restart the service [$serviceName]. Error: $_"
    }
    
} else {
    # Service not found
    Write-Error "Service [$serviceName] not found. Please ensure the service name is correct and it's installed."
}