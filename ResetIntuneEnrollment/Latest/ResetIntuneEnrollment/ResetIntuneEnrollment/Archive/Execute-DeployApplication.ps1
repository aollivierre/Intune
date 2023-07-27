$scriptPath2 = Split-Path -Parent $MyInvocation.MyCommand.Definition
function Execute-DeployApplication {
    param (
        [string]$ProgramName = "OneTrace",
        [string]$Path_local = "$Env:Programfiles\_MEM"
    )

    # Define colors for logging
    $infoColor = 'Green'
    $errorColor = 'Red'

    # Check if Deploy-Application.exe exists
   
    $deployApplicationPath = Join-Path -Path "$scriptPath2\Install-OneTrace\PSAppDeployToolkit_v3.9.2\Toolkit" -ChildPath "Deploy-Application.exe"

    if (-not (Test-Path -Path $deployApplicationPath)) {
        Write-Host "Error: Deploy-Application.exe not found at $deployApplicationPath" -ForegroundColor $errorColor
        return
    }

    # Create log directory if it doesn't exist
    $logDir = Join-Path -Path $Path_local -ChildPath "Log"
    if (-not (Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }

    # Start transcript
    $logFile = Join-Path -Path $logDir -ChildPath "$ProgramName-install.log"
    Start-Transcript -Path $logFile -Force -Append

    # Log start time
    $startTime = Get-Date
    Write-Host "[$startTime] Starting Deploy-Application.exe" -ForegroundColor $infoColor

    # Execute Deploy-Application.exe
    try {
        & $deployApplicationPath
    }
    catch {
        $endTime = Get-Date
        Write-Host "[$endTime] Error executing Deploy-Application.exe: $_" -ForegroundColor $errorColor
        Stop-Transcript
        return
    }

    # Log end time
    $endTime = Get-Date
    Write-Host "[$endTime] Finished Deploy-Application.exe" -ForegroundColor $infoColor

    # Stop transcript
    Stop-Transcript
}

# Call the function
# Execute-DeployApplication
