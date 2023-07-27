function Get-ScriptPath {
    if (-not $PSVersionTable.PSVersion -or $PSVersionTable.PSVersion.Major -lt 3) {
        $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    }
    else {
        $scriptPath = $PSScriptRoot
    }
    return $scriptPath
}
$scriptPath = Get-ScriptPath

function Initialize-Logging {
    try {
        $scriptPath = $PSScriptRoot
        $computerName = $env:COMPUTERNAME
        $Filename = "ResetIntuneEnrollment"
        $logPath = Join-Path $scriptPath "exports\Logs\$computerName\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
        
        if (!(Test-Path $logPath)) {
            New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop | Out-Null
        }
        
        $logFile = Join-Path $logPath "$Filename-Transcript.log"
        Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null

        $CSVFilePath = Join-Path $scriptPath "exports\CSV\$computerName"
        
        if (!(Test-Path $CSVFilePath)) {
            New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop | Out-Null
        }

        return @{
            Filename    = $Filename
            LogPath     = $logPath
            LogFile     = $logFile
            CSVFilePath = $CSVFilePath
        }


        $script:Filename = $Filename
        $script:LogPath = $logPath
        $script:LogFile = $logFile
        $script:CSVFilePath = $CSVFilePath
    }
    catch {
        Write-Error "An error occurred while initializing logging: $_"
    }
}
$loggingInfo = Initialize-Logging

# $DBG


$Filename = $loggingInfo['Filename']
$logPath = $loggingInfo['LogPath']
$logFile = $loggingInfo['LogFile']
$CSVFilePath = $loggingInfo['CSVFilePath']

$DBG


function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath
       
    )

    $csvData = [PSCustomObject]@{
        TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        ComputerName = $env:COMPUTERNAME
        Message      = $Message
    }

    $csvData | Export-Csv -Path $CSVFilePath -Append -NoTypeInformation -Force
}


function CreateEventLogSource {
    param (
       
        [string]$LogName = 'ResetIntuneEnrollmentLog'
    )

 


    $source = "ResetIntuneEnrollment"
 

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use New-EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            New-EventLog -LogName $logName -Source $source
            Write-Host "Event source '$source' created in log '$logName'" -ForegroundColor Green
            
        }
        else {
            Write-Host "Event source '$source' already exists" -ForegroundColor Yellow
         
        }
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
        
            Write-EnhancedLog -Message "Event source '$source' created in log '$logName'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
        else {
           
            Write-EnhancedLog -Message "Event source '$source' already exists" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }


}
CreateEventLogSource

function Write-EventLogMessage {
    param (
        [string]$Message,
        [string]$LogName = 'ResetIntuneEnrollmentLog'
    )

  

    $source = "ResetIntuneEnrollment"
    $eventID = 1000


    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use Write-EventLog
        Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId $eventID -Message $Message
      
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        $eventLog = New-Object System.Diagnostics.EventLog($logName)
        $eventLog.Source = $source
        $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $eventID)
     
    }


}

function Write-BasicLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO',
        [string]$Caller = (Get-PSCallStack)[0].Command
    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"

    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    $Host.UI.RawUI.BackgroundColor = $BackgroundColor
    # Write-Output $formattedMessage
    Write-output $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor

    # Log the message using the PowerShell Logging Module
    # Write-Log -Level $Level -Message $Message

    # Append to CSV file
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    Write-EventLogMessage -Message $formattedMessage
}


function Install-LoggingModules {
    # Set up security protocol
    # [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Check if NuGet package provider is installed
    $NuGetProvider = Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue

    # Install NuGet package provider if not installed
    if (-not $NuGetProvider) {
        $Message = "NuGet package provider not found. Installing..."
        Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Yellow)
        Install-PackageProvider -Name "NuGet" -Force
    }
    else {
        $Message = "NuGet package provider is already installed."
        Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)
    }

    # Install PowerShellGet module if not installed
    $PowerShellGetModule = Get-Module -Name "PowerShellGet" -ListAvailable
    if (-not $PowerShellGetModule) {
        $Message = "Installing PowerShellGet"
        Write-BasicLog -Message $Message
        Install-Module -Name "PowerShellGet" -AllowClobber -Force
        
    }
    else {
        $Message = "PowerShellGet is already installed."
        Write-BasicLog -Message $Message
    }
    

    $requiredModules = @("Logging")

    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            $Message = "Installing module: $module"
            Write-BasicLog -Message $Message
            Install-Module -Name $module -Force
            $Message = "Module: $module has been installed"
            Write-BasicLog -Message $Message

        }
        else {
            $Message = "Module $module is already installed"
            Write-BasicLog -Message $Message
        }
    }


    $ImportedModules = @("Logging")
    
    foreach ($Importedmodule in $ImportedModules) {
        if ((Get-Module -ListAvailable -Name $Importedmodule)) {

            $Message = "Importing module: $Importedmodule"
            Write-BasicLog -Message $Message
            Import-Module -Name $Importedmodule
            $Message = "Module: $Importedmodule has been Imported"
            Write-BasicLog -Message $Message
        }
    }

}
# Call the function to install the required modules and dependencies
# Install-LoggingModules

$Message = "Finished Imorting Modules"
Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)


#################################################################################################################################
################################################# START LOGGING ###################################################################
#################################################################################################################################


function Initialize-EnhancedLogging {
    param (
        [string]$logFile
    )

    Set-LoggingDefaultLevel -Level 'WARNING'
    Add-LoggingTarget -Name Console
    Add-LoggingTarget -Name File -Configuration @{Path = $logFile }
}
$logFilePath = $logFile
Initialize-EnhancedLogging -logFile $logFilePath


function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO',
        [switch]$UseModule = $false,
        # [string]$Caller = (Get-PSCallStack)[1].FunctionName
        # [string]$Caller = (Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
        [string]$Caller = (Get-PSCallStack)[0].Command

    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"


    # $formattedMessage = "[$Caller] $Message"

    

    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    $Host.UI.RawUI.BackgroundColor = $BackgroundColor
    # Write-Output $formattedMessage
    Write-output $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor

    # Log the message using the PowerShell Logging Module
    $UseModule = $true
    if ($UseModule) {
        Write-Log -Level $Level -Message $formattedMessage
    } else {
        Write-Output $formattedMessage -ForegroundColor $ForegroundColor
    }

    # Append to CSV file
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    Write-EventLogMessage -Message $formattedMessage
}

#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################

function Install-RequiredModules {

    # Install SecretManagement.KeePass module if not installed or if the version is less than 0.9.2
    $KeePassModule = Get-Module -Name "SecretManagement.KeePass" -ListAvailable
    if (-not $KeePassModule -or ($KeePassModule.Version -lt [System.Version]::new(0, 9, 2))) {

        Write-EnhancedLog -Message "Installing SecretManagement.KeePass " -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        Install-Module -Name "SecretManagement.KeePass" -RequiredVersion 0.9.2 -Force:$true
    }
    else {
        # Write-Host "SecretManagement.KeePass is already installed." -ForegroundColor Green
        Write-EnhancedLog -Message "SecretManagement.KeePass is already installed." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }


    $requiredModules = @("Microsoft.Graph", "Microsoft.Graph.Authentication")

    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {

            Write-EnhancedLog -Message "Installing module: $module" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
            Install-Module -Name $module -Force
            Write-EnhancedLog -Message "Module: $module has been installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
        else {
            Write-EnhancedLog -Message "Module $module is already installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
    }


    $ImportedModules = @("Microsoft.Graph.Identity.DirectoryManagement", "Microsoft.Graph.Authentication")
    
    foreach ($Importedmodule in $ImportedModules) {
        if ((Get-Module -ListAvailable -Name $Importedmodule)) {
            Write-EnhancedLog -Message "Importing module: $Importedmodule" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
            Import-Module -Name $Importedmodule
            Write-EnhancedLog -Message "Module: $Importedmodule has been Imported" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
    }

    # Install Remote Server Administration Tools (RSAT) and import ActiveDirectory module
    if (!(Get-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online | Where-Object { $_.State -eq "Installed" })) {
        Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online
    }
    else {

        Write-EnhancedLog -Message "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 is already installed." -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    }

    Import-Module ActiveDirectory
}
# Call the function to install the required modules and dependencies
# Install-RequiredModules
Write-EnhancedLog -Message "All modules installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

# function TestFunction1 {
#     Write-EnhancedLog -Message "This is a message from TestFunction1"
# }

# function TestFunction2 {
#     Write-EnhancedLog -Message "This is a message from TestFunction2"
# }

# TestFunction1
# TestFunction2


function DeployOneTrace {
    param (
        [string]$ProgramName = "OneTrace",
        [string]$Path_local = "$Env:Programfiles\_MEM"
    )

    # Define colors for logging
    $infoColor = 'Green'
    $errorColor = 'Red'

    # Check if Deploy-Application.exe exists
   
    $deployApplicationPath = Join-Path -Path "$scriptPath\Install-$ProgramName\PSAppDeployToolkit_v3.9.2\Toolkit" -ChildPath "Deploy-Application.ps1"

    if (-not (Test-Path -Path $deployApplicationPath)) {
        Write-EnhancedLog -Message "Error: Deploy-Application.ps1 not found at $deployApplicationPath" -Level "ERROR" -ForegroundColor ([ConsoleColor]::$errorColor)
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

    Write-EnhancedLog -Message "Starting Deployment of : $ProgramName using PSADT" -Level "INFO" -ForegroundColor ([ConsoleColor]::$infoColor)

    try {
        & $deployApplicationPath
    }
    catch {
        Write-EnhancedLog -Message "Error executing Deploy-Application.ps1: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::$errorColor)
        Stop-Transcript
        return
    }

    Write-EnhancedLog -Message "Finished Deployment of : $ProgramName using PSADT" -Level "INFO" -ForegroundColor ([ConsoleColor]::$infoColor)

    # Stop transcript
    Stop-Transcript
}
# DeployOneTrace
Write-EnhancedLog -Message "OneTrace Installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


function DeployIntuneManagementExtension {
    param (
        [string]$ProgramName = "IntuneManagementExtension",
        [string]$Path_local = "$Env:Programfiles\_MEM"
    )

    # Define colors for logging
    $infoColor = 'Green'
    $errorColor = 'Red'

    # Check if Deploy-Application.exe exists
    $deployApplicationPath = Join-Path -Path "$scriptPath\Install-$ProgramName\PSAppDeployToolkit_v3.9.2\Toolkit" -ChildPath "Deploy-Application.ps1"

    if (-not (Test-Path -Path $deployApplicationPath)) {
        # Write-Host "Error: Deploy-Application.ps1 not found at $deployApplicationPath" -ForegroundColor $errorColor
        Write-EnhancedLog -Message "Error: Deploy-Application.ps1 not found at $deployApplicationPath" -Level "ERROR" -ForegroundColor ([ConsoleColor]::$errorColor)
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

    Write-EnhancedLog -Message "Starting Deployment of : $ProgramName using PSADT" -Level "INFO" -ForegroundColor ([ConsoleColor]::$infoColor)

    # Execute Deploy-Application.exe
    try {
        & $deployApplicationPath
    }
    catch {

        Write-EnhancedLog -Message "Error executing Deploy-Application.ps1: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::$errorColor)
        Stop-Transcript
        return
    }

    Write-EnhancedLog -Message "Finished Deployment of : $ProgramName using PSADT" -Level "INFO" -ForegroundColor ([ConsoleColor]::$infoColor)

    # Stop transcript
    Stop-Transcript
}
# DeployIntuneManagementExtension
Write-EnhancedLog -Message "IntuneManagementExtension Installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
 



$VaultName = "Database"
function Register-KeePassVault {
    # To securely store the KeePass database credentials, you'll need to register a KeePass vault:
    $VaultName = $VaultName

    $ExistingVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
    if ($ExistingVault) {
        Write-EnhancedLog -Message "Keepass $VaultName is already Registered..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        Unregister-SecretVault -Name $VaultName
        Register-KeePassSecretVault -Name $VaultName -Path $databaseKdbxPath -KeyPath $databaseKeyxPath
    } 
    else {
        Write-EnhancedLog -Message "Keepass $VaultName is NOT Registered... Registering" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        Unregister-SecretVault -Name $VaultName
        Register-KeePassSecretVault -Name $VaultName -Path $databaseKdbxPath -KeyPath $databaseKeyxPath
    }
    
}

Write-EnhancedLog -Message "Successfully Registered KeePass Vault" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)



function Get-KeePassDatabasePaths {

    $secretsPath = Join-Path $scriptPath "Secrets"
    $databaseKdbxPath = Join-Path $secretsPath "Database.kdbx"
    $databaseKeyxPath = Join-Path $secretsPath "Database.keyx"

    return @{

        DatabaseKdbxPath = $databaseKdbxPath
        DatabaseKeyxPath = $databaseKeyxPath
    }
}
$paths = Get-KeePassDatabasePaths
$databaseKdbxPath = $paths['DatabaseKdbxPath']
$databaseKeyxPath = $paths['DatabaseKeyxPath']


# $DBG

Write-EnhancedLog -Message "Successfully built Database Paths" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# $DBG


Register-KeePassVault
Write-EnhancedLog -Message "Finished Registering KeePass" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

function Get-SecretsFromKeePass {
    param (
        [string[]]$KeePassEntryNames
    )
    
    $Secrets = @{}
    
    foreach ($entryName in $KeePassEntryNames) {
        $PasswordSecret = Get-Secret -Name "${EntryName}_Password" -Vault "Database"

        # $DBG
        $SecurePassword = $PasswordSecret
                
        # Convert plain text password to SecureString
        $SecurePasswordString = ConvertTo-SecureString -String $SecurePassword -AsPlainText -Force

        # $DBG
        
        # Convert SecureString back to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSecret)
        $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        # $DBG
        
        $Secrets[$entryName] = @{
            "Username"       = $PasswordSecret.UserName
            "SecurePassword" = $SecurePasswordString
            "PlainText"      = $PlainText
        }
    }
    
    return $Secrets
}

$KeePassEntryNames = @("ClientId", "ClientSecret", "TenantID", "tenantname")
$Secrets = Get-SecretsFromKeePass -KeePassEntryNames $KeePassEntryNames

$clientId = $Secrets["ClientId"].PlainText
$clientSecret = $Secrets["ClientSecret"].PlainText
$tenantID = $Secrets["TenantID"].PlainText
$tenantname = $Secrets["tenantname"].PlainText
# $tenantname = "pharmacists.ca"
Write-EnhancedLog -Message "KeePass secrets are now available" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)



function RunMdmDiagnostics {
    param (
        [string]$OutputFolderPath = "$PSScriptRoot\$env:COMPUTERNAME\MDMDiag"
    )

    if (!(Test-Path $OutputFolderPath)) {
        New-Item -ItemType Directory -Path $OutputFolderPath -Force | Out-Null
    }

    # Usage1
    Write-EnhancedLog -Message "MdmDiagnosticsTool.exe outputting to a folder...: $OutputFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
    & 'C:\Windows\system32\MdmDiagnosticsTool.exe' -out $OutputFolderPath
    Write-EnhancedLog -Message "MdmDiagnosticsTool.exe outputted to a folder: $OutputFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # Usage2
    $areas = "Autopilot;DeviceProvisioning;DeviceEnrollment"
    $cabFilePath = Join-Path $OutputFolderPath "AutopilotDiag.cab"
    Write-EnhancedLog -Message "MdmDiagnosticsTool.exe outputting to a cab...: $cabFilePath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
    & 'C:\Windows\system32\MdmDiagnosticsTool.exe' -area $areas -cab $cabFilePath
    Write-EnhancedLog -Message "MdmDiagnosticsTool.exe outputted to a cab : $cabFilePath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # Usage3
    $zipFilePath = Join-Path $OutputFolderPath "AutopilotDiag.zip"
    Write-EnhancedLog -Message "MdmDiagnosticsTool.exe outputting to a zip...: $zipFilePath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)
    & 'C:\Windows\system32\MdmDiagnosticsTool.exe' -area $areas -zip $zipFilePath
    Write-EnhancedLog -Message "MdmDiagnosticsTool.exe outputted to a zip : $zipFilePath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # Usage4
    # $xmlFilePath = "Path\to\your\input.xml"
    # $server = "MDM_Server_URL"
    # & 'C:\Windows\system32\MdmDiagnosticsTool.exe' -xml $xmlFilePath -zip $zipFilePath -server $server


    # # Get all available areas
    # $areas = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\MdmDiagnostics\Area" | ForEach-Object { $_.Name.Split('\')[-1] }) -join ';'

    # # Usage2
    # $cabFilePath = Join-Path $OutputFolderPath "AllAreasDiag.cab"
    # & 'C:\Windows\system32\MdmDiagnosticsTool.exe' -area $areas -cab $cabFilePath

    # # Usage3
    # $zipFilePath = Join-Path $OutputFolderPath "AllAreasDiag.zip"
    # & 'C:\Windows\system32\MdmDiagnosticsTool.exe' -area $areas -zip $zipFilePath

    # Open MDMDiagReport.html
    $mdmDiagReportPath = Join-Path $OutputFolderPath "MDMDiagReport.html"
    if (Test-Path $mdmDiagReportPath) {
        Start-Process $mdmDiagReportPath
    } else {
        Write-Host "MDMDiagReport.html not found in the output folder." -ForegroundColor Red
    }

}
# RunMdmDiagnostics
# Write-EnhancedLog -Message "Done running RunMdmDiagnostics" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


function Get-IntuneLog {
    <#
    .SYNOPSIS
    Function for Intune policies debugging on client.
    - opens Intune logs
    - opens event viewer with Intune log
    - generates & open MDMDiagReport.html report

    .DESCRIPTION
    Function for Intune policies debugging on client.
    - opens Intune logs
    - opens event viewer with Intune log
    - generates & open MDMDiagReport.html report

    .PARAMETER computerName
    Name of remote computer.

    .EXAMPLE
    Get-IntuneLog
    #>

    [CmdletBinding()]
    param (
        [string] $computerName
    )

    if ($computerName -and $computerName -in "localhost", $env:COMPUTERNAME) {
        $computerName = $null
    }

    function _openLog {
        param (
            [string[]] $logs
        )

        if (!$logs) { return }

        # use best possible log viewer
        # $cmLogViewer = "C:\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\CMLogViewer.exe"
        # $cmLogViewer = "C:\Program Files (x86)\Configuration Manager Support Center\CMLogViewer.exe"
        $cmLogViewer = "C:\Program Files (x86)\Configuration Manager Support Center\CMPowerLogViewer.exe"
        $cmTrace = "$env:windir\CCM\CMTrace.exe"
        if (Test-Path $cmLogViewer) {
            $viewer = $cmLogViewer
        }
        elseif (Test-Path $cmTrace) {
            $viewer = $cmTrace
        }

        if ($viewer -and $viewer -match "CMPowerLogViewer\.exe$") {
            # open all logs in one CMLogViewer instance
            $quotedLog = ($logs | ForEach-Object {
                    "`"$_`""
                }) -join " "
            Write-EnhancedLog -Message "Opening CMPowerLogViewer.exe"
            Start-Process $viewer -ArgumentList $quotedLog
        }
        else {
            # cmtrace (or notepad) don't support opening multiple logs in one instance, so open each log in separate viewer process
            foreach ($log in $logs) {
                if (!(Test-Path $log -ErrorAction SilentlyContinue)) {
                    Write-EnhancedLog -Message "Log $log wasn't found"
                    continue
                }

                # Write-EnhancedLog -Message "Opening $log"
                Write-EnhancedLog -Message "Opening $log" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
                if ($viewer -and $viewer -match "CMTrace\.exe$") {
                    # in case CMTrace viewer exists, use it
                    Write-EnhancedLog -Message "Opening CMTrace.exe"
                    Start-Process $viewer -ArgumentList "`"$log`""
                }
                else {
                    # use associated viewer
                    & $log
                }
            }
        }
    }

    # open main Intune logs
    $log = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
    if ($computerName) {
        $log = "\\$computerName\" + ($log -replace ":", "$")
    }
    "opening logs in '$log'"
    _openLog (Get-ChildItem $log -File | Select-Object -exp fullname)

    # When a PowerShell script is run on the client from Intune, the scripts and the script output will be stored here, but only until execution is complete
    $log = "C:\Program files (x86)\Microsoft Intune Management Extension\Policies\Scripts"
    if ($computerName) {
        $log = "\\$computerName\" + ($log -replace ":", "$")
    }
    "opening logs in '$log'"
    _openLog (Get-ChildItem $log -File -ea SilentlyContinue | Select-Object -exp fullname)

    $log = "C:\Program files (x86)\Microsoft Intune Management Extension\Policies\Results"
    if ($computerName) {
        $log = "\\$computerName\" + ($log -replace ":", "$")
    }
    "opening logs in '$log'"
    _openLog (Get-ChildItem $log -File -ea SilentlyContinue | Select-Object -exp fullname)

    # open Event Viewer with Intune Log
    "opening event log 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'"
    if ($computerName) {
        Write-EnhancedLog -Message "Opening remote Event Viewer can take significant time!"
        mmc.exe eventvwr.msc /computer:$computerName /c:"Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"
    }
    else {
        mmc.exe eventvwr.msc /c:"Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"
    }


    # # generate & open MDMDiagReport
    Write-EnhancedLog -Message "running RunMdmDiagnostics... collecting logs" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    RunMdmDiagnostics

    # # generate & open MDMDiagReport
    # "generating & opening MDMDiagReport"
    # if ($computerName) {
    #     Write-EnhancedLog -Message "TODO (zatim delej tak, ze spustis tuto fci lokalne pod uzivatelem, jehoz vysledky chces zjistit"
    # }
    # else {
    #     Write-EnhancedLog -Message "starting MdmDiagnosticsTool.exe" -Level "INFO"
    #     Start-Process MdmDiagnosticsTool.exe -Wait -ArgumentList "-out $env:TEMP\MDMDiag" -NoNewWindow
    #     & "$env:TEMP\MDMDiag\MDMDiagReport.html"
    # }

    # vygeneruje spoustu bordelu do jednoho zip souboru vhodneho k poslani mailem (bacha muze mit vic jak 5MB)
    # Start-Process MdmDiagnosticsTool.exe -ArgumentList "-area Autopilot;DeviceEnrollment;DeviceProvisioning;TPM -zip C:\temp\aaa.zip" -Verb runas

    # show DM info
    $param = @{
        scriptBlock = { Get-ChildItem -Path HKLM:SOFTWARE\Microsoft\Enrollments -Recurse | Where-Object { $_.Property -like "*UPN*" } }
    }
    if ($computerName) {
        $param.computerName = $computerName
    }
    Invoke-Command @param | Format-Table

    # $regKey = "Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts"
    # if (!(Get-Process regedit)) {
    #     # set starting location for regedit
    #     Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit LastKey $regKey
    #     # open regedit
    # } else {
    #     "To check script last run time and result check $regKey in regedit or logs located in C:\Program files (x86)\Microsoft Intune Management Extension\Policies"
    # }
    # regedit.exe
}

function Reset-IntuneEnrollment {
    <#
    .SYNOPSIS
    Function for resetting device Intune management connection.

    .DESCRIPTION
    Function for resetting device Intune management connection.

    It will:
     - check actual Intune status on device
     - reset Hybrid AzureAD join
     - remove device records from Intune
     - remove Intune connection data and invoke re-enrollment

    .PARAMETER computerName
    (optional) Name of the computer.

    .EXAMPLE
    Reset-IntuneEnrollment

    .NOTES
    # How MDM (Intune) enrollment works https://techcommunity.microsoft.com/t5/intune-customer-success/support-tip-understanding-auto-enrollment-in-a-co-managed/ba-p/834780
    #>

    [CmdletBinding()]
    param (
        [string] $computerName = $env:COMPUTERNAME
    )

    $ErrorActionPreference = "Stop"

    #region helper functions


    # Write-EnhancedLog -Message 'retrieved secrets.... here are the secret values' -ForegroundColor Green
    Write-EnhancedLog -Message "retrieved secrets.... here are the secret values" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    Write-EnhancedLog -Message "$clientId"
    Write-EnhancedLog -Message "$clientSecret"
    Write-EnhancedLog -Message "$tenantID"
    Write-EnhancedLog -Message "$tenantname"



    function Get-MicrosoftGraphAccessToken {
        $tokenBody = @{
            Grant_Type    = 'client_credentials'  
            Scope         = 'https://graph.microsoft.com/.default'  
            Client_Id     = $clientId  
            Client_Secret = $clientSecret
        }  
    
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop
    
        return $tokenResponse.access_token
    }


    $accessToken = Get-MicrosoftGraphAccessToken
    Connect-MgGraph -AccessToken $accessToken
    Write-EnhancedLog -Message "Connected to MS Graph with Access Token!!!" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    Write-EnhancedLog -Message "here is the context" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    get-mgcontext


    function Invoke-MDMReenrollment {
        <#
        .SYNOPSIS
        Function for resetting device Intune management connection.

        .DESCRIPTION
        Force re-enrollment of Intune managed devices.

        It will:
        - remove Intune certificates
        - remove Intune scheduled tasks & registry keys
        - force re-enrollment via DeviceEnroller.exe

        .PARAMETER computerName
        (optional) Name of the remote computer, which you want to re-enroll.

        .PARAMETER asSystem
        Switch for invoking re-enroll as a SYSTEM instead of logged user.

        .EXAMPLE
        Invoke-MDMReenrollment

        Invoking re-enroll to Intune on local computer under logged user.

        .EXAMPLE
        Invoke-MDMReenrollment -computerName PC-01 -asSystem

        Invoking re-enroll to Intune on computer PC-01 under SYSTEM account.

        .NOTES
        https://www.maximerastello.com/manually-re-enroll-a-co-managed-or-hybrid-azure-ad-join-windows-10-pc-to-microsoft-intune-without-loosing-current-configuration/

        Based on work of MauriceDaly.
        #>

        [Alias("Invoke-IntuneReenrollment")]
        [CmdletBinding()]
        param (
            [string] $computerName,

            [switch] $asSystem
        )

        if ($computerName -and $computerName -notin "localhost", $env:COMPUTERNAME) {
            if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                throw "You don't have administrator rights"
            }
        }

        $allFunctionDefs = "function Invoke-AsSystem { ${function:Invoke-AsSystem} }"

        $scriptBlock = {
            param ($allFunctionDefs, $asSystem)

            try {
                foreach ($functionDef in $allFunctionDefs) {
                    . ([ScriptBlock]::Create($functionDef))
                }

                # Write-EnhancedLog -Message "Checking for MDM certificate in computer certificate store"
                Write-EnhancedLog -Message "Checking for MDM certificate in computer certificate store" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

                # Check&Delete MDM device certificate
                Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object Issuer -EQ "CN=Microsoft Intune MDM Device CA" | ForEach-Object {
                    # Write-EnhancedLog -Message " - Removing Intune certificate $($_.DnsNameList.Unicode)"
                    Write-EnhancedLog -Message " - Removing Intune certificate $($_.DnsNameList.Unicode)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
                    Remove-Item $_.PSPath
                }

                # Obtain current management GUID from Task Scheduler
                $EnrollmentGUID = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Microsoft*Windows*EnterpriseMgmt\*" } | Select-Object -ExpandProperty TaskPath -Unique | Where-Object { $_ -like "*-*-*" } | Split-Path -Leaf

                # Start cleanup process
                if (![string]::IsNullOrEmpty($EnrollmentGUID)) {
                    Write-EnhancedLog -Message "Current enrollment GUID detected as $([string]$EnrollmentGUID)"

                    # Stop Intune Management Exention Agent and CCM Agent services
                    Write-EnhancedLog -Message "Stopping MDM services"
                    if (Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue) {
                        Write-EnhancedLog -Message " - Stopping IntuneManagementExtension service..."
                        Stop-Service -Name IntuneManagementExtension
                    }
                    if (Get-Service -Name CCMExec -ErrorAction SilentlyContinue) {
                        Write-EnhancedLog -Message " - Stopping CCMExec service..."
                        Stop-Service -Name CCMExec
                    }

                    # Remove task scheduler entries
                    Write-EnhancedLog -Message "Removing task scheduler Enterprise Management entries for GUID - $([string]$EnrollmentGUID)"
                    Get-ScheduledTask | Where-Object { $_.Taskpath -match $EnrollmentGUID } | Unregister-ScheduledTask -Confirm:$false
                    # delete also parent folder
                    Remove-Item -Path "$env:WINDIR\System32\Tasks\Microsoft\Windows\EnterpriseMgmt\$EnrollmentGUID" -Force

                    $RegistryKeys = "HKLM:\SOFTWARE\Microsoft\Enrollments", "HKLM:\SOFTWARE\Microsoft\Enrollments\Status", "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked", "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled", "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions"
                    foreach ($Key in $RegistryKeys) {
                        Write-EnhancedLog -Message "Processing registry key $Key"
                        # Remove registry entries
                        if (Test-Path -Path $Key) {
                            # Search for and remove keys with matching GUID
                            Write-EnhancedLog -Message " - GUID entry found in $Key. Removing..."
                            Get-ChildItem -Path $Key | Where-Object { $_.Name -match $EnrollmentGUID } | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
                        }
                    }

                    # Start Intune Management Extension Agent service
                    Write-EnhancedLog -Message "Starting MDM services"
                    if (Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue) {
                        Write-EnhancedLog -Message " - Starting IntuneManagementExtension service..."
                        Start-Service -Name IntuneManagementExtension
                    }
                    if (Get-Service -Name CCMExec -ErrorAction SilentlyContinue) {
                        Write-EnhancedLog -Message " - Starting CCMExec service..."
                        Start-Service -Name CCMExec
                    }

                    # Sleep
                    Write-EnhancedLog -Message "Waiting for 30 seconds prior to running DeviceEnroller"
                    Start-Sleep -Seconds 30

                    # Start re-enrollment process
                    Write-EnhancedLog -Message "Calling: DeviceEnroller.exe /C /AutoenrollMDM"
                    if ($asSystem) {
                        Invoke-AsSystem -runAs SYSTEM -scriptBlock { Start-Process -FilePath "$env:WINDIR\System32\DeviceEnroller.exe" -ArgumentList "/C /AutoenrollMDM" -NoNewWindow -Wait -PassThru }
                    }
                    else {
                        Start-Process -FilePath "$env:WINDIR\System32\DeviceEnroller.exe" -ArgumentList "/C /AutoenrollMDM" -NoNewWindow -Wait -PassThru
                    }
                }
                else {
                    throw "Unable to obtain enrollment GUID value from task scheduler. Aborting"
                }
            }
            catch [System.Exception] {
                throw "Error message: $($_.Exception.Message)"
            }
        }

        $param = @{
            scriptBlock  = $scriptBlock
            argumentList = $allFunctionDefs, $asSystem
        }

        if ($computerName -and $computerName -notin "localhost", $env:COMPUTERNAME) {
            $param.computerName = $computerName
        }

        Invoke-Command @param
    }

    # function Get-IntuneLog {
    #     <#
    #     .SYNOPSIS
    #     Function for Intune policies debugging on client.
    #     - opens Intune logs
    #     - opens event viewer with Intune log
    #     - generates & open MDMDiagReport.html report

    #     .DESCRIPTION
    #     Function for Intune policies debugging on client.
    #     - opens Intune logs
    #     - opens event viewer with Intune log
    #     - generates & open MDMDiagReport.html report

    #     .PARAMETER computerName
    #     Name of remote computer.

    #     .EXAMPLE
    #     Get-IntuneLog
    #     #>

    #     [CmdletBinding()]
    #     param (
    #         [string] $computerName
    #     )

    #     if ($computerName -and $computerName -in "localhost", $env:COMPUTERNAME) {
    #         $computerName = $null
    #     }

    #     function _openLog {
    #         param (
    #             [string[]] $logs
    #         )

    #         if (!$logs) { return }

    #         # use best possible log viewer
    #         # $cmLogViewer = "C:\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\CMLogViewer.exe"
    #         # $cmLogViewer = "C:\Program Files (x86)\Configuration Manager Support Center\CMLogViewer.exe"
    #         $cmLogViewer = "C:\Program Files (x86)\Configuration Manager Support Center\CMPowerLogViewer.exe"
    #         $cmTrace = "$env:windir\CCM\CMTrace.exe"
    #         if (Test-Path $cmLogViewer) {
    #             $viewer = $cmLogViewer
    #         }
    #         elseif (Test-Path $cmTrace) {
    #             $viewer = $cmTrace
    #         }

    #         if ($viewer -and $viewer -match "CMPowerLogViewer\.exe$") {
    #             # open all logs in one CMLogViewer instance
    #             $quotedLog = ($logs | ForEach-Object {
    #                     "`"$_`""
    #                 }) -join " "
    #             Write-EnhancedLog -Message "Opening CMPowerLogViewer.exe"
    #             Start-Process $viewer -ArgumentList $quotedLog
    #         }
    #         else {
    #             # cmtrace (or notepad) don't support opening multiple logs in one instance, so open each log in separate viewer process
    #             foreach ($log in $logs) {
    #                 if (!(Test-Path $log -ErrorAction SilentlyContinue)) {
    #                     Write-EnhancedLog -Message "Log $log wasn't found"
    #                     continue
    #                 }

    #                 # Write-EnhancedLog -Message "Opening $log"
    #                 Write-EnhancedLog -Message "Opening $log" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    #                 if ($viewer -and $viewer -match "CMTrace\.exe$") {
    #                     # in case CMTrace viewer exists, use it
    #                     Write-EnhancedLog -Message "Opening CMTrace.exe"
    #                     Start-Process $viewer -ArgumentList "`"$log`""
    #                 }
    #                 else {
    #                     # use associated viewer
    #                     & $log
    #                 }
    #             }
    #         }
    #     }

    #     # open main Intune logs
    #     $log = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
    #     if ($computerName) {
    #         $log = "\\$computerName\" + ($log -replace ":", "$")
    #     }
    #     "opening logs in '$log'"
    #     _openLog (Get-ChildItem $log -File | Select-Object -exp fullname)

    #     # When a PowerShell script is run on the client from Intune, the scripts and the script output will be stored here, but only until execution is complete
    #     $log = "C:\Program files (x86)\Microsoft Intune Management Extension\Policies\Scripts"
    #     if ($computerName) {
    #         $log = "\\$computerName\" + ($log -replace ":", "$")
    #     }
    #     "opening logs in '$log'"
    #     _openLog (Get-ChildItem $log -File -ea SilentlyContinue | Select-Object -exp fullname)

    #     $log = "C:\Program files (x86)\Microsoft Intune Management Extension\Policies\Results"
    #     if ($computerName) {
    #         $log = "\\$computerName\" + ($log -replace ":", "$")
    #     }
    #     "opening logs in '$log'"
    #     _openLog (Get-ChildItem $log -File -ea SilentlyContinue | Select-Object -exp fullname)

    #     # open Event Viewer with Intune Log
    #     "opening event log 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'"
    #     if ($computerName) {
    #         Write-EnhancedLog -Message "Opening remote Event Viewer can take significant time!"
    #         mmc.exe eventvwr.msc /computer:$computerName /c:"Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"
    #     }
    #     else {
    #         mmc.exe eventvwr.msc /c:"Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"
    #     }

    #     # generate & open MDMDiagReport
    #     "generating & opening MDMDiagReport"
    #     if ($computerName) {
    #         Write-EnhancedLog -Message "TODO (zatim delej tak, ze spustis tuto fci lokalne pod uzivatelem, jehoz vysledky chces zjistit"
    #     }
    #     else {
    #         Start-Process MdmDiagnosticsTool.exe -Wait -ArgumentList "-out $env:TEMP\MDMDiag" -NoNewWindow
    #         & "$env:TEMP\MDMDiag\MDMDiagReport.html"
    #     }

    #     # vygeneruje spoustu bordelu do jednoho zip souboru vhodneho k poslani mailem (bacha muze mit vic jak 5MB)
    #     # Start-Process MdmDiagnosticsTool.exe -ArgumentList "-area Autopilot;DeviceEnrollment;DeviceProvisioning;TPM -zip C:\temp\aaa.zip" -Verb runas

    #     # show DM info
    #     $param = @{
    #         scriptBlock = { Get-ChildItem -Path HKLM:SOFTWARE\Microsoft\Enrollments -Recurse | Where-Object { $_.Property -like "*UPN*" } }
    #     }
    #     if ($computerName) {
    #         $param.computerName = $computerName
    #     }
    #     Invoke-Command @param | Format-Table

    #     # $regKey = "Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts"
    #     # if (!(Get-Process regedit)) {
    #     #     # set starting location for regedit
    #     #     Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit LastKey $regKey
    #     #     # open regedit
    #     # } else {
    #     #     "To check script last run time and result check $regKey in regedit or logs located in C:\Program files (x86)\Microsoft Intune Management Extension\Policies"
    #     # }
    #     # regedit.exe
    # }

    function Reset-HybridADJoin {
        <#
        .SYNOPSIS
        Function for resetting Hybrid AzureAD join connection.

        .DESCRIPTION
        Function for resetting Hybrid AzureAD join connection.
        It will:
        - un-join computer from AzureAD (using dsregcmd.exe)
        - remove leftover certificates
        - invoke rejoin (using sched. task 'Automatic-Device-Join')
        - inform user about the result

        .PARAMETER computerName
        (optional) name of the computer you want to rejoin.

        .EXAMPLE
        Reset-HybridADJoin

        Un-join and re-join this computer to AzureAD

        .NOTES
        https://www.maximerastello.com/manually-re-register-a-windows-10-or-windows-server-machine-in-hybrid-azure-ad-join/
        #>

        [CmdletBinding()]
        param (
            [string] $computerName
        )

        Write-EnhancedLog -Message "For join AzureAD process to work. Computer account has to exists in AzureAD already (should be synchronized via 'AzureAD Connect')!"

        #region helper functions
        function Invoke-AsSystem {
            <#
            .SYNOPSIS
            Function for running specified code under SYSTEM account.

            .DESCRIPTION
            Function for running specified code under SYSTEM account.

            Helper files and sched. tasks are automatically deleted.

            .PARAMETER scriptBlock
            Scriptblock that should be run under SYSTEM account.

            .PARAMETER computerName
            Name of computer, where to run this.

            .PARAMETER returnTranscript
            Add creating of transcript to specified scriptBlock and returns its output.

            .PARAMETER cacheToDisk
            Necessity for long scriptBlocks. Content will be saved to disk and run from there.

            .PARAMETER argument
            If you need to pass some variables to the scriptBlock.
            Hashtable where keys will be names of variables and values will be, well values :)

            Example:
            [hashtable]$Argument = @{
                name = "John"
                cities = "Boston", "Prague"
                hash = @{var1 = 'value1','value11'; var2 = @{ key ='value' }}
            }

            Will in beginning of the scriptBlock define variables:
            $name = 'John'
            $cities = 'Boston', 'Prague'
            $hash = @{var1 = 'value1','value11'; var2 = @{ key ='value' }

            ! ONLY STRING, ARRAY and HASHTABLE variables are supported !

            .PARAMETER runAs
            Let you change if scriptBlock should be running under SYSTEM, LOCALSERVICE or NETWORKSERVICE account.

            Default is SYSTEM.

            .EXAMPLE
            Invoke-AsSystem {New-Item $env:TEMP\abc}

            On local computer will call given scriptblock under SYSTEM account.

            .EXAMPLE
            Invoke-AsSystem {New-Item "$env:TEMP\$name"} -computerName PC-01 -ReturnTranscript -Argument @{name = 'someFolder'} -Verbose

            On computer PC-01 will call given scriptblock under SYSTEM account i.e. will create folder 'someFolder' in C:\Windows\Temp.
            Transcript will be outputted in console too.
            #>

            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [scriptblock] $scriptBlock,

                [string] $computerName,

                [switch] $returnTranscript,

                [hashtable] $argument,

                [ValidateSet('SYSTEM', 'NETWORKSERVICE', 'LOCALSERVICE')]
                [string] $runAs = "SYSTEM",

                [switch] $CacheToDisk
            )

            (Get-Variable runAs).Attributes.Clear()
            $runAs = "NT Authority\$runAs"

            #region prepare Invoke-Command parameters
            # export this function to remote session (so I am not dependant whether it exists there or not)
            $allFunctionDefs = "function Create-VariableTextDefinition { ${function:Create-VariableTextDefinition} }"

            $param = @{
                argumentList = $scriptBlock, $runAs, $CacheToDisk, $allFunctionDefs, $VerbosePreference, $ReturnTranscript, $Argument
            }

            if ($computerName -and $computerName -notmatch "localhost|$env:COMPUTERNAME") {
                $param.computerName = $computerName
            }
            else {
                if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                    throw "You don't have administrator rights"
                }
            }
            #endregion prepare Invoke-Command parameters

            Invoke-Command @param -ScriptBlock {
                param ($scriptBlock, $runAs, $CacheToDisk, $allFunctionDefs, $VerbosePreference, $ReturnTranscript, $Argument)

                foreach ($functionDef in $allFunctionDefs) {
                    . ([ScriptBlock]::Create($functionDef))
                }

                $TranscriptPath = "$ENV:TEMP\Invoke-AsSYSTEM_$(Get-Random).log"

                if ($Argument -or $ReturnTranscript) {
                    # define passed variables
                    if ($Argument) {
                        # convert hash to variables text definition
                        $VariableTextDef = Create-VariableTextDefinition $Argument
                    }

                    if ($ReturnTranscript) {
                        # modify scriptBlock to contain creation of transcript
                        $TranscriptStart = "Start-Transcript $TranscriptPath"
                        $TranscriptStop = 'Stop-Transcript'
                    }

                    $ScriptBlockContent = ($TranscriptStart + "`n`n" + $VariableTextDef + "`n`n" + $ScriptBlock.ToString() + "`n`n" + $TranscriptStop)
                    Write-EnhancedLog -Message "####### SCRIPTBLOCK TO RUN"
                    Write-EnhancedLog -Message $ScriptBlockContent
                    Write-EnhancedLog -Message "#######"
                    $scriptBlock = [Scriptblock]::Create($ScriptBlockContent)
                }

                if ($CacheToDisk) {
                    $ScriptGuid = New-Guid
                    $null = New-Item "$($ENV:TEMP)\$($ScriptGuid).ps1" -Value $ScriptBlock -Force
                    $pwshcommand = "-ExecutionPolicy Bypass -Window Hidden -noprofile -file `"$($ENV:TEMP)\$($ScriptGuid).ps1`""
                }
                else {
                    $encodedcommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptBlock))
                    $pwshcommand = "-ExecutionPolicy Bypass -Window Hidden -noprofile -EncodedCommand $($encodedcommand)"
                }

                $OSLevel = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentVersion
                if ($OSLevel -lt 6.2) { $MaxLength = 8190 } else { $MaxLength = 32767 }
                if ($encodedcommand.length -gt $MaxLength -and $CacheToDisk -eq $false) {
                    throw "The encoded script is longer than the command line parameter limit. Please execute the script with the -CacheToDisk option."
                }

                try {
                    #region create&run sched. task
                    $A = New-ScheduledTaskAction -Execute "$($ENV:windir)\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument $pwshcommand
                    if ($runAs -match "\$") {
                        # pod gMSA uctem
                        $P = New-ScheduledTaskPrincipal -UserId $runAs -LogonType Password
                    }
                    else {
                        # pod systemovym uctem
                        $P = New-ScheduledTaskPrincipal -UserId $runAs -LogonType ServiceAccount
                    }
                    $S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd
                    $taskName = "RunAsSystem_" + (Get-Random)
                    try {
                        $null = New-ScheduledTask -Action $A -Principal $P -Settings $S -ea Stop | Register-ScheduledTask -Force -TaskName $taskName -ea Stop
                    }
                    catch {
                        if ($_ -match "No mapping between account names and security IDs was done") {
                            throw "Account $runAs doesn't exist or cannot be used on $env:COMPUTERNAME"
                        }
                        else {
                            throw "Unable to create helper scheduled task. Error was:`n$_"
                        }
                    }

                    # run scheduled task
                    Start-Sleep -Milliseconds 200
                    Start-ScheduledTask $taskName

                    # wait for sched. task to end
                    Write-EnhancedLog -Message "waiting on sched. task end ..."
                    $i = 0
                    while (((Get-ScheduledTask $taskName -ErrorAction silentlyContinue).state -ne "Ready") -and $i -lt 500) {
                        ++$i
                        Start-Sleep -Milliseconds 200
                    }

                    # get sched. task result code
                    $result = (Get-ScheduledTaskInfo $taskName).LastTaskResult

                    # read & delete transcript
                    if ($ReturnTranscript) {
                        # return just interesting part of transcript
                        if (Test-Path $TranscriptPath) {
                            $transcriptContent = (Get-Content $TranscriptPath -Raw) -Split [regex]::escape('**********************')
                            # return command output
                            ($transcriptContent[2] -split "`n" | Select-Object -Skip 2 | Select-Object -SkipLast 3) -join "`n"

                            Remove-Item $TranscriptPath -Force
                        }
                        else {
                            Write-EnhancedLog -Message "There is no transcript, command probably failed!"
                        }
                    }

                    if ($CacheToDisk) { $null = Remove-Item "$($ENV:TEMP)\$($ScriptGuid).ps1" -Force }

                    try {
                        Unregister-ScheduledTask $taskName -Confirm:$false -ea Stop
                    }
                    catch {
                        throw "Unable to unregister sched. task $taskName. Please remove it manually"
                    }

                    if ($result -ne 0) {
                        throw "Command wasn't successfully ended ($result)"
                    }
                    #endregion create&run sched. task
                }
                catch {
                    throw $_.Exception
                }
            }
        }
        #endregion helper functions

        $allFunctionDefs = "function Invoke-AsSystem { ${function:Invoke-AsSystem} }"

        $param = @{
            scriptblock  = {
                param( $allFunctionDefs )

                $ErrorActionPreference = "Stop"

                foreach ($functionDef in $allFunctionDefs) {
                    . ([ScriptBlock]::Create($functionDef))
                }

                $dsreg = dsregcmd.exe /status
                if (($dsreg | Select-String "DomainJoined :") -match "NO") {
                    throw "Computer is NOT domain joined"
                }

                "Un-joining $env:COMPUTERNAME from Azure"
                Write-EnhancedLog -Message "by running: Invoke-AsSystem { dsregcmd.exe /leave /debug } -returnTranscript"
                Invoke-AsSystem { dsregcmd.exe /leave /debug } #-returnTranscript

                Start-Sleep 5
                Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object { $_.Issuer -match "MS-Organization-Access|MS-Organization-P2P-Access \[\d+\]" } | ForEach-Object {
                    Write-EnhancedLog -Message "Removing leftover Hybrid-Join certificate $($_.DnsNameList.Unicode)" -ForegroundColor Cyan
                    Remove-Item $_.PSPath
                }

                $dsreg = dsregcmd.exe /status
                if (!(($dsreg | Select-String "AzureAdJoined :") -match "NO")) {
                    throw "$env:COMPUTERNAME is still joined to Azure. Run again"
                }

                # join computer to Azure again
                "Joining $env:COMPUTERNAME to Azure"
                Write-EnhancedLog -Message "by running: Get-ScheduledTask -TaskName Automatic-Device-Join | Start-ScheduledTask"
                Get-ScheduledTask -TaskName "Automatic-Device-Join" | Start-ScheduledTask
                while ((Get-ScheduledTask "Automatic-Device-Join" -ErrorAction silentlyContinue).state -ne "Ready") {
                    Start-Sleep 1
                    "Waiting for sched. task 'Automatic-Device-Join' to complete"
                }
                if ((Get-ScheduledTask -TaskName "Automatic-Device-Join" | Get-ScheduledTaskInfo | Select-Object -exp LastTaskResult) -ne 0) {
                    throw "Sched. task Automatic-Device-Join failed. Is $env:COMPUTERNAME synchronized to AzureAD?"
                }

                # check certificates
                "Waiting for certificate creation"
                $i = 30
                Write-EnhancedLog -Message "two certificates should be created in Computer Personal cert. store (issuer: MS-Organization-Access, MS-Organization-P2P-Access [$(Get-Date -Format yyyy)]"

                Start-Sleep 3

                while (!($hybridJoinCert = Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object { $_.Issuer -match "MS-Organization-Access|MS-Organization-P2P-Access \[\d+\]" }) -and $i -gt 0) {
                    Start-Sleep 3
                    --$i
                    $i
                }

                # check AzureAd join status
                $dsreg = dsregcmd.exe /status
                if (($dsreg | Select-String "AzureAdJoined :") -match "YES") {
                    ++$AzureAdJoined
                }

                if ($hybridJoinCert -and $AzureAdJoined) {
                    "$env:COMPUTERNAME was successfully joined to AAD again."
                }
                else {
                    $problem = @()

                    if (!$AzureAdJoined) {
                        $problem += " - computer is not AzureAD joined"
                    }

                    if (!$hybridJoinCert) {
                        $problem += " - certificates weren't created"
                    }

                    # Write-Error "Join wasn't successful:`n$($problem -join "`n")"
                    Write-EnhancedLog -Message "Join wasn't successful:`n$($problem -join "`n")" -Level "Error" -ForegroundColor ([ConsoleColor]::Red)
                    Write-EnhancedLog -Message "Check if device $env:COMPUTERNAME exists in AAD"
                    Write-EnhancedLog -Message "Run:`ngpupdate /force /target:computer"
                    Write-EnhancedLog -Message "You can get failure reason via manual join by running: Invoke-AsSystem -scriptBlock {dsregcmd /join /debug} -returnTranscript"
                    throw 1
                }
            }
            argumentList = $allFunctionDefs
        }

        if ($computerName -and $computerName -notin "localhost", $env:COMPUTERNAME) {
            $param.computerName = $computerName
        }
        else {
            if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                throw "You don't have administrator rights"
            }
        }

        Invoke-Command @param
    }

    function Get-IntuneEnrollmentStatus {
        <#
        .SYNOPSIS
        Function for checking whether computer is managed by Intune (fulfill all requirements).

        .DESCRIPTION
        Function for checking whether computer is managed by Intune (fulfill all requirements).
        What is checked:
        - device is AAD joined
        - device is joined to Intune
        - device has valid Intune certificate
        - device has Intune sched. tasks
        - device has Intune registry keys
        - Intune service exists

        Returns true or false.

        .PARAMETER computerName
        (optional) name of the computer to check.

        .PARAMETER checkIntuneToo
        Switch for checking Intune part too (if device is listed there).

        .EXAMPLE
        Get-IntuneEnrollmentStatus

        Check Intune status on local computer.

        .EXAMPLE
        Get-IntuneEnrollmentStatus -computerName ae-50-pc

        Check Intune status on computer ae-50-pc.

        .EXAMPLE
        Get-IntuneEnrollmentStatus -computerName ae-50-pc -checkIntuneToo

        Check Intune status on computer ae-50-pc, plus connects to Intune and check whether ae-50-pc exists there.
        #>

        [CmdletBinding()]
        param (
            [string] $computerName,

            [switch] $checkIntuneToo
        )

        if (!$computerName) { $computerName = $env:COMPUTERNAME }

        #region get Intune data
        if ($checkIntuneToo) {
            $ErrActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "Stop"

            try {
                if (Get-Command Get-ADComputer -ErrorAction SilentlyContinue) {
                    $ADObj = Get-ADComputer -Filter "Name -eq '$computerName'" -Properties Name, ObjectGUID
                }
                else {
                    Write-EnhancedLog -Message "Get-ADComputer command is missing, unable to get device GUID"
                }

                # Connect-Graph

                Connect-MgGraph -AccessToken $accessToken
                # Write-EnhancedLog -Message 'connected to Ms Graph' -ForegroundColor Green
                # Write-EnhancedLog -Message 'here is the context'
                Write-EnhancedLog -Message "Connected to MS Graph with Access Token!!!" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                # Write-EnhancedLog -Message 'here is the context'
                Write-EnhancedLog -Message "here is the context" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
                get-mgcontext

                $intuneObj = @()

                # $intuneObj += Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$computerName'"
                $intuneObj += Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$computerName'"

                if ($ADObj.ObjectGUID) {
                    # because of bug? computer can be listed under guid_date name in cloud
                    $intuneObj += Get-MgDeviceManagementManagedDevice -Filter "azureADDeviceId eq '$($ADObj.ObjectGUID)'" | Where-Object DeviceName -NE $computerName
                }
            }
            catch {
                Write-EnhancedLog -Message "Unable to get information from Intune. $_"

                # to avoid errors that device is missing from Intune
                $intuneObj = 1
            }

            $ErrorActionPreference = $ErrActionPreference
        }
        #endregion get Intune data

        $scriptBlock = {
            param ($checkIntuneToo, $intuneObj)

            $intuneNotJoined = 0

            #region Intune checks
            if ($checkIntuneToo) {
                if (!$intuneObj) {
                    ++$intuneNotJoined
                    Write-EnhancedLog -Message "Device is missing from Intune!"
                }

                if ($intuneObj.count -gt 1) {
                    Write-EnhancedLog -Message "Device is listed $($intuneObj.count) times in Intune"
                }

                $wrongIntuneName = $intuneObj.DeviceName | Where-Object { $_ -ne $env:COMPUTERNAME }
                if ($wrongIntuneName) {
                    Write-EnhancedLog -Message "Device is named as $wrongIntuneName in Intune"
                }

                $correctIntuneName = $intuneObj.DeviceName | Where-Object { $_ -eq $env:COMPUTERNAME }
                if ($intuneObj -and !$correctIntuneName) {
                    ++$intuneNotJoined
                    Write-EnhancedLog -Message "Device has no record in Intune with correct device name"
                }
            }
            #endregion Intune checks

            #region dsregcmd checks
            $dsregcmd = dsregcmd.exe /status
            $azureAdJoined = $dsregcmd | Select-String "AzureAdJoined : YES"
            if (!$azureAdJoined) {
                ++$intuneNotJoined
                Write-EnhancedLog -Message "Device is NOT AAD joined"
            }

            $tenantName = $dsregcmd | Select-String "TenantName : .+"
            $MDMUrl = $dsregcmd | Select-String "MdmUrl : .+"
            if (!$tenantName -or !$MDMUrl) {
                ++$intuneNotJoined
                Write-EnhancedLog -Message "Device is NOT Intune joined"
            }
            #endregion dsregcmd checks

            #region certificate checks
            $MDMCert = Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object Issuer -EQ "CN=Microsoft Intune MDM Device CA"
            if (!$MDMCert) {
                ++$intuneNotJoined
                Write-EnhancedLog -Message "Intune certificate is missing"
            }
            elseif ($MDMCert.NotAfter -lt (Get-Date) -or $MDMCert.NotBefore -gt (Get-Date)) {
                ++$intuneNotJoined
                Write-EnhancedLog -Message "Intune certificate isn't valid"
            }
            #endregion certificate checks

            #region sched. task checks
            $MDMSchedTask = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Microsoft*Windows*EnterpriseMgmt\*" -and $_.TaskName -eq "PushLaunch" }
            $enrollmentGUID = $MDMSchedTask | Select-Object -ExpandProperty TaskPath -Unique | Where-Object { $_ -like "*-*-*" } | Split-Path -Leaf
            if (!$enrollmentGUID) {
                ++$intuneNotJoined
                Write-EnhancedLog -Message "Synchronization sched. task is missing"
            }
            #endregion sched. task checks

            #region registry checks
            if ($enrollmentGUID) {
                # $missingRegKey = @()
                $registryKeys = "HKLM:\SOFTWARE\Microsoft\Enrollments", "HKLM:\SOFTWARE\Microsoft\Enrollments\Status", "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked", "HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled", "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger", "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions"
                foreach ($key in $registryKeys) {
                    if (!(Get-ChildItem -Path $key -ea SilentlyContinue | Where-Object { $_.Name -match $enrollmentGUID })) {
                        Write-EnhancedLog -Message "Registry key $key is missing"
                        ++$intuneNotJoined
                    }
                }
            }
            #endregion registry checks

            #region service checks
            $MDMService = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
            if (!$MDMService) {
                ++$intuneNotJoined
                Write-EnhancedLog -Message "Intune service IntuneManagementExtension is missing"
            }
            if ($MDMService -and $MDMService.Status -ne "Running") {
                Write-EnhancedLog -Message "Intune service IntuneManagementExtension is not running"
            }
            #endregion service checks

            if ($intuneNotJoined) {
                return $false
            }
            else {
                return $true
            }
        }

        $param = @{
            scriptBlock  = $scriptBlock
            argumentList = $checkIntuneToo, $intuneObj
        }
        if ($computerName -and $computerName -notin "localhost", $env:COMPUTERNAME) {
            $param.computerName = $computerName
        }

        Invoke-Command @param
    }
    #endregion helper functions


    Write-EnhancedLog -Message "Checking actual Intune connection status" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    if (Get-IntuneEnrollmentStatus -computerName $computerName) {
        $choice = ""
        while ($choice -notmatch "^[Y|N]$") {
            $choice = Read-Host "It seems device has working Intune connection. Continue? (Y|N)"
        }
        if ($choice -eq "N") {
            break
        }
    }

  
    Write-EnhancedLog -Message "Resetting Hybrid AzureAD connection" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    #******** Reset-HybridADJoin -computerName $computerName

   
    Write-EnhancedLog -Message "Waiting" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

    Start-Sleep 10


    Write-EnhancedLog -Message "Removing $computerName records from Intune" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    # to discover cases when device is in Intune named as GUID_date
    if (Get-Command Get-ADComputer -ErrorAction SilentlyContinue) {
        $ADObj = Get-ADComputer -Filter "Name -eq '$computerName'" -Properties Name, ObjectGUID
    }
    else {
        Write-EnhancedLog -Message "AD module is missing, unable to obtain computer GUID" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    }

    #region get Intune data
    Connect-MgGraph -AccessToken $accessToken
    Write-EnhancedLog -Message "Connected to MS Graph with Access Token!!!" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    Write-EnhancedLog -Message "here is the context" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    get-mgcontext

    $IntuneObj = @()

    $IntuneObj += Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$computerName'"

    if ($ADObj.ObjectGUID) {
        # because of bug? computer can be listed under guid_date name in cloud
        $IntuneObj += Get-MgDeviceManagementManagedDevice -Filter "azureADDeviceId eq '$($ADObj.ObjectGUID)'" | Where-Object DeviceName -NE $computerName
    }
    #endregion get Intune data

    #region remove computer record in Intune
    if ($IntuneObj) {
        $IntuneObj | Where-Object { $_ } | ForEach-Object {
            
            Write-EnhancedLog -Message "Removing $($_.DeviceName) ($($_.id)) from Intune" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
     
            
            # Remove-MgDeviceManagementManagedDevice -DeviceId $deviceId
            #*************** Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $_.id
        }
    }
    else {
        # Write-EnhancedLog -Message "$computerName nor its guid exists in Intune. Skipping removal." -ForegroundColor DarkCyan
        Write-EnhancedLog -Message "$computerName nor its guid exists in Intune. Skipping removal." -Level "INFO" -ForegroundColor ([ConsoleColor]::DarkCyan)
    }
    #endregion remove computer record in Intune

    # Write-EnhancedLog -Message "Invoking re-enrollment of Intune connection" -ForegroundColor Cyan
    Write-EnhancedLog -Message "Invoking re-enrollment of Intune connection" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    #******** Invoke-MDMReenrollment -computerName $computerName -asSystem

    # check certificates
    $i = 30
  
    Write-EnhancedLog -Message "Waiting for Intune certificate creation" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    Write-EnhancedLog -Message "two certificates should be created in Computer Personal cert. store (issuer: MS-Organization-Access, MS-Organization-P2P-Access" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    while (!(Get-ChildItem 'Cert:\LocalMachine\My\' | Where-Object { $_.Issuer -match "CN=Microsoft Intune MDM Device CA" }) -and $i -gt 0) {
        Start-Sleep 1
        --$i
        $i
    }

    if ($i -eq 0) {
        Write-EnhancedLog -Message "Intune certificate (issuer: Microsoft Intune MDM Device CA) isn't created (yet?)" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Cyan)

        "Opening Intune logs"
        Get-IntuneLog -computerName $computerName
    }
    else {
        Write-EnhancedLog -Message "DONE :)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    }
}



Reset-IntuneEnrollment
Write-EnhancedLog -Message "Reset Intune Enrollment is now completed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


# Remove variables and clear secrets
Remove-Variable -Name clientId
Remove-Variable -Name clientsecret
Remove-Variable -Name tenantID
Remove-Variable -Name tenantname
# Remove-Variable -Name tenantName
# Remove-Variable -Name site_objectid
# Remove-Variable -Name webhook_url

$Secrets.Clear()
Remove-Variable -Name Secrets
Write-EnhancedLog -Message "Removed all secrets" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

Wait-Logging

Get-IntuneLog

Stop-Transcript