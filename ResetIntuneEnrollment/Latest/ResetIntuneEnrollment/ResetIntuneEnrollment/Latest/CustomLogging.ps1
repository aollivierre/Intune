if (-not $PSVersionTable.PSVersion -or $PSVersionTable.PSVersion.Major -lt 3) {
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
else {
    $scriptPath = $PSScriptRoot
}

$computerName = $env:COMPUTERNAME
$Filename = "ResetIntuneEnrollment"
$logPath = "$scriptPath\exports\Logs\$computerName\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')\"
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}
$logFile = "${logPath}$Filename-Transcript.log"
Start-Transcript -Path $logFile

$CSVFilePath = "$scriptPath\exports\CSV\$computerName"
if (!(Test-Path $CSVFilePath)) {
    New-Item -ItemType Directory -Path $CSVFilePath -Force | Out-Null
}

function Write-BasicLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO'
    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"

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
        # $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"
        # Write-Host $formattedMessage -ForegroundColor Green
        Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Yellow)
        Install-PackageProvider -Name "NuGet" -Force
    }
    else {
        $Message = "NuGet package provider is already installed."
        # $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"
        # Write-Host $formattedMessage -ForegroundColor Yellow
        Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)
    }

    # Install PowerShellGet module if not installed
    $PowerShellGetModule = Get-Module -Name "PowerShellGet" -ListAvailable
    if (-not $PowerShellGetModule) {
        $Message = "Installing PowerShellGet"
        # $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"
        # Write-Host $formattedMessage -ForegroundColor Green
        Write-BasicLog -Message $Message
        Install-Module -Name "PowerShellGet" -AllowClobber -Force
        
    }
    else {
        # Write-Host "PowerShellGet is already installed." -ForegroundColor Green

        $Message = "PowerShellGet is already installed."
        # $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"
        # Write-Host $formattedMessage -ForegroundColor Green
        Write-BasicLog -Message $Message
    }
    

    $requiredModules = @("Logging")

    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            # Write-Host "Installing module: $module" -ForegroundColor Yellow

            $Message = "Installing module: $module"
            # $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"
            # Write-Host $formattedMessage -ForegroundColor Yellow
            Write-BasicLog -Message $Message

            # Install-Module -Name $module -Force -Verbose
            Install-Module -Name $module -Force
            # Write-Host "Module: $module has been installed" -ForegroundColor Yellow

            $Message = "Module: $module has been installed"
            # $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"
            # Write-Host $formattedMessage -ForegroundColor Green
            Write-BasicLog -Message $Message

        }
        else {
            # Write-Host "Module $module is already installed" -ForegroundColor Green

            $Message = "Module $module is already installed"
            # $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"
            # Write-Host $formattedMessage -ForegroundColor Green
            Write-BasicLog -Message $Message
        }
    }


    $ImportedModules = @("Logging")
    
    foreach ($Importedmodule in $ImportedModules) {
        if ((Get-Module -ListAvailable -Name $Importedmodule)) {
            # Write-Host "Importing module: $Importedmodule" -ForegroundColor Yellow

            $Message = "Importing module: $Importedmodule"
            Write-BasicLog -Message $Message

            # Install-Module -Name $module -Force -Verbose
            Import-Module -Name $Importedmodule
            # Write-Host "Module: $Importedmodule has been Imported" -ForegroundColor Yellow

            $Message = "Module: $Importedmodule has been Imported"
            Write-BasicLog -Message $Message
        }
    }

}
# Call the function to install the required modules and dependencies
Install-LoggingModules

$Message = "Finished Imorting Modules"
Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)

#################################################################################################################################
################################################# START LOGGING ###################################################################
#################################################################################################################################



function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath
        # [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv"
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
        # [string]$Message,
        [string]$LogName = 'ResetIntuneEnrollmentLog'
    )

    # $source = 'PowerShell Script'
    # if (-not (Get-WinEvent -LogName $LogName -ErrorAction SilentlyContinue)) {
    #     New-EventLog -LogName $LogName -Source $source
    # }


    $source = "ResetIntuneEnrollment"
    # $logName = "MyCustomLog"

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use New-EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            New-EventLog -LogName $logName -Source $source
            # Write-Host "Event source '$source' created in log '$logName'"
            Write-EnhancedLog -Message "Event source '$source' created in log '$logName'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
        else {
            # Write-Host "Event source '$source' already exists"
            Write-EnhancedLog -Message "Event source '$source' already exists" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
            # Write-Host "Event source '$source' created in log '$logName'"
            Write-EnhancedLog -Message "Event source '$source' created in log '$logName'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
        else {
            # Write-Host "Event source '$source' already exists"
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

    # $source = 'PowerShell Script'
    # if (-not (Get-WinEvent -LogName $LogName -ErrorAction SilentlyContinue)) {
    #     New-EventLog -LogName $LogName -Source $source
    # }


    $source = "ResetIntuneEnrollment"
    # # $logName = "MyCustomLog"

    # if ($PSVersionTable.PSVersion.Major -lt 6) {
    #     # PowerShell version is less than 6, use New-EventLog
    #     if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
    #         New-EventLog -LogName $logName -Source $source
    #         Write-Host "Event source '$source' created in log '$logName'"
    #     }
    #     else {
    #         Write-Host "Event source '$source' already exists"
    #     }
    # }
    # else {
    #     # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
    #     if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
    #         [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
    #         Write-Host "Event source '$source' created in log '$logName'"
    #     }
    #     else {
    #         Write-Host "Event source '$source' already exists"
    #     }
    # }

    # Write-EventLog -LogName $LogName -Source $source -EntryType Information -EventId 1 -Message $Message


    # $source = "MyCustomSource"
    # $logName = "MyCustomLog"
    $eventID = 1000
    # $eventMessage = "This is a test event log entry."

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use Write-EventLog
        Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId $eventID -Message $Message
        # Write-EventLog -LogName $LogName -Source $source -EntryType Information -EventId 1 -Message $Message
        # Write-Host "Event log entry written using Write-EventLog"
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        $eventLog = New-Object System.Diagnostics.EventLog($logName)
        $eventLog.Source = $source
        $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $eventID)
        # Write-Host "Event log entry written using System.Diagnostics.EventLog"
    }


}

# Import-Module Logging
Set-LoggingDefaultLevel -Level 'WARNING'
Add-LoggingTarget -Name Console
Add-LoggingTarget -Name File -Configuration @{Path = $logFile }


function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO'
    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): $Message"

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
    Write-Log -Level $Level -Message $Message

    # Append to CSV file
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    Write-EventLogMessage -Message $formattedMessage
}