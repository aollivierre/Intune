<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory = $false)]
	[ValidateSet('Install', 'Uninstall', 'Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory = $false)]
	[ValidateSet('Interactive', 'Silent', 'NonInteractive')]
	[string]$DeployMode = 'Silent',
	[Parameter(Mandatory = $false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory = $false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = ''
	[string]$appName = ''
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = 'XX/XX/20XX'
	[string]$appScriptAuthor = '<author name>'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.4'
	[string]$deployAppScriptDate = '26/01/2021'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0) { [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Installation tasks here>
		

		$ErrorActionPreference = "SilentlyContinue"
		# Set ScripRoot variable to the path which the script is executed from
		$ScriptRoot1 = $null
		$ScriptRoot1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
			Split-Path -Path $MyInvocation.MyCommand.Path
		}
		else {
			$PSScriptRoot
		}
		
		#Get public and private function definition files.
		$Public = "$ScriptRoot1\Public"
		$PSScripts_1 = @( Get-ChildItem -Path $Public\*.ps1 -Recurse -ErrorAction SilentlyContinue )
				
		#Dot source the files
		Foreach ($import in @($PSScripts_1)) {
			Try {
		
				Write-host "processing $import"
				#         $files = Get-ChildItem -Path $root -Filter *.ps1
				. $import.fullname
			}
			Catch {
				Write-Error -Message "Failed to import function $($import.fullname): $_"
			}
		}

		# Download-TeamViewer

		#Set Power Plan to High Performance
		Set-HighPerfPowerPlan

		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'



		#TeamViewer Parameters


		# $installteamviewersettingsfilepath = Get-ChildItem -Recurse -Include *.tvopt
		$installteamviewersettingsfilepath = @( Get-ChildItem -Path $Public\settings\*.tvopt -Recurse -ErrorAction SilentlyContinue )

		if ($installteamviewersettingsfilepath) {

			if ((Test-Path $installteamviewersettingsfilepath) -and ($installteamviewersettingsfilepath.count -eq '1')) {
				Write-host 'found only' $installteamviewersettingsfilepath.count 'number of setting files'
				Write-host ' settings file found in' $installteamviewersettingsfilepath.FullName
			}
			
			elseif ((Test-Path $installteamviewersettingsfilepath) -and ($installteamviewersettingsfilepath.count -gt '1')) {
				
				Write-host 'found only' $installteamviewersettingsfilepath.count 'number of setting files'
				Write-host ' settings file found in' $installteamviewersettingsfilepath.FullName
				Throw 'Ensure ONLY 1 setting file is there'
			}
			
		   
		
			
		}
		
		else
		#
		
		{ Throw 'settings file not found' }

		$options_1 = $null
		$cmdArgs_1 = $null

		$CUSTOMCONFIG_ID_1 = $null
		$CUSTOMCONFIG_ID_1 = 'he26pyq'

		$API_TOKEN_1 = $null
		$API_TOKEN_1 = '7757967-7qRfr5r4Voq9MRxS7UKZ'

		
		$options_1 = @(
			"CUSTOMCONFIGID=$CUSTOMCONFIG_ID_1"
			"APITOKEN=$API_TOKEN_1"
			'ASSIGNMENTOPTIONS="--grant-easy-access"'
			# 'ASSIGNMENTOPTIONS="--reassign"'
			# 'ASSIGNMENTOPTIONS="--group-id=""g176322730"""' ##!Change this - This group ID belongs to a group call Venus   
			'ASSIGNMENTOPTIONS="--group-id=""g269785848"""' ##!Change this - This group ID belongs to a group call neptune   
			"SETTINGSFILE=$installteamviewersettingsfilepath"
		)

		$cmdArgs_1 = @(
			$options_1
		)

		If ($useDefaultMsi) {

			Write-Host 'using zero config' -ForegroundColor Magenta
			[hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Install'; Path = $defaultMsiFile; AddParameters = "$cmdArgs_1" ; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		# Install Publisher if required
		# If ($addPublisher) {
		Show-InstallationProgress -StatusMessage 'Installing TeamViewer Host. This may take some time. Please wait...'
		# Execute-Process -Path "$dirFiles\eea.msi" -WindowStyle Hidden
		# }

		## <Perform Installation tasks here>


		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>


		Write-host "Adding TeamViewer to Startup Programs"
		Add-StartupApp -APP_NAME_3 'TeamViewer' -APP_EXE_3 "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"


		# $options_2 = @(
        #     'assign'
  		# 	'--grant-easy-access'
        # )

        # $cmdArgs_2 = @(
        #     $options_2
        # )

		# & "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" @cmdArgs_2

		# Show-InstallationProgress -StatusMessage 'Launching ESET Endpoint AV for CCI. This may take some time. Please wait...'
		# Execute-Process -Path 'C:\Program Files (x86)\CentraStage\Gui.exe' -WindowStyle Hidden

		## Display a message at the end of the install
		If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall') {
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>


		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# <Perform Uninstallation tasks here>

		Show-InstallationProgress -StatusMessage 'UnInstalling ESET Endpoint AV for CCI. This may take some time. Please wait...'
		# Execute-Process -Path 'C:\Program Files (x86)\CentraStage\uninst.exe' -WindowStyle Hidden

		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>


		

	}
	ElseIf ($deploymentType -ieq 'Repair') {
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		# <Perform Repair tasks here>

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>


	}
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}