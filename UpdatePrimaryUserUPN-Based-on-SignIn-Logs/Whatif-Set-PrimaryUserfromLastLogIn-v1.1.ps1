
<#
.Synopsis
   Get whatif primary user UPN data for intune managed devices.
.DESCRIPTION
    For a given Intune device name (or file name of device names) connects to MS Graph and:
      validates the input if single or multiple devices in txt file.
      Read through th each device and connect to graph to fetch the current user and expected user.
      Thanks to the original author of the script https://github.com/svdbusse/IntuneScripts/blob/master/PrimaryUser/Set-PrimaryUserfromLastLogIn.ps1
      Updated by: Eswar Koneti (@eskonr)
      Dated: 28-Jun-2023
      
#>


####################################################

param
(
  [Parameter(Mandatory = $false)]
  $DeviceName,
  [Parameter(Mandatory = $false)]
  $UserPrincipalName

)

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
#Get the script execution date                  
$date = (Get-Date -f ddMMyyyy_hhmmss)
$o_ScriptLaunchTime = Get-Date
$s_Year = [string]($o_ScriptLaunchTime.Year)
$s_Month = [string]($o_ScriptLaunchTime.Month)
if ($s_Month.Length -eq 1) { $s_Month = "0$s_Month" }
$s_Day = [string]($o_ScriptLaunchTime.Day)
if ($s_Day.Length -eq 1) { $s_Day = "0$s_Day" }



####################################################################################
####################################################################################
####################################################################################
$connectionParams = @{
  clientId     = "xxxxxxxxxxxxxxxxxxxx-4eb1d0b50e92"
  tenantID     = "xxxxxxxxxxxxxxxx89f13"
  ClientSecret = "xxxxxxxxxxxxxxxxxxxxx"  # Replace with your actual Client Secret
}
# $refreshToken = '0.Axxxxxxxxxxxxxxxxxxxxxxxxxxxx'

####################################################################################
####################################################################################
####################################################################################



$AOscriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    
function Initialize-ScriptAndLogging {
  $ErrorActionPreference = 'SilentlyContinue'
  $deploymentName = "IntuneWin32DeployerCustomlog" # Replace this with your actual deployment name
  $scriptPath = "C:\code\$deploymentName"
  # $hadError = $false
    
  try {
    if (-not (Test-Path -Path $scriptPath)) {
      New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
      Write-Host "Created directory: $scriptPath"
    }
    
    $computerName = $env:COMPUTERNAME
    $Filename = "IntuneWin32DeployerCustomlog"
    $logDir = Join-Path -Path $scriptPath -ChildPath "exports\Logs\$computerName"
    $logPath = Join-Path -Path $logDir -ChildPath "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
            
    if (!(Test-Path $logPath)) {
      Write-Host "Did not find log file at $logPath" -ForegroundColor Yellow
      Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
      $createdLogDir = New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop
      Write-Host "Created log file at $logPath" -ForegroundColor Green
    }
            
    $logFile = Join-Path -Path $logPath -ChildPath "$Filename-Transcript.log"
    Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null
    
    $CSVDir = Join-Path -Path $scriptPath -ChildPath "exports\CSV"
    $CSVFilePath = Join-Path -Path $CSVDir -ChildPath "$computerName"
            
    if (!(Test-Path $CSVFilePath)) {
      Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
      Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
      $createdCSVDir = New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop
      Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Green
    }
    
    return @{
      ScriptPath  = $scriptPath
      Filename    = $Filename
      LogPath     = $logPath
      LogFile     = $logFile
      CSVFilePath = $CSVFilePath
    }
    
  }
  catch {
    Write-Error "An error occurred while initializing script and logging: $_"
  }
}
$initializationInfo = Initialize-ScriptAndLogging
    
    
    
# Script Execution and Variable Assignment
# After the function Initialize-ScriptAndLogging is called, its return values (in the form of a hashtable) are stored in the variable $initializationInfo.
    
# Then, individual elements of this hashtable are extracted into separate variables for ease of use:
    
# $ScriptPath: The path of the script's main directory.
# $Filename: The base name used for log files.
# $logPath: The full path of the directory where logs are stored.
# $logFile: The full path of the transcript log file.
# $CSVFilePath: The path of the directory where CSV files are stored.
# This structure allows the script to have a clear organization regarding where logs and other files are stored, making it easier to manage and maintain, especially for logging purposes. It also encapsulates the setup logic in a function, making the main script cleaner and more focused on its primary tasks.
    
    
$ScriptPath = $initializationInfo['ScriptPath']
$Filename = $initializationInfo['Filename']
$logPath = $initializationInfo['LogPath']
$logFile = $initializationInfo['LogFile']
$CSVFilePath = $initializationInfo['CSVFilePath']
    
    
    
    
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
    
    
    
function CreateEventSourceAndLog {
  param (
    [string]$LogName,
    [string]$EventSource
  )
    
    
  # Validate parameters
  if (-not $LogName) {
    Write-Warning "LogName is required."
    return
  }
  if (-not $EventSource) {
    Write-Warning "Source is required."
    return
  }
    
  # Function to create event log and source
  function CreateEventLogSource($logName, $EventSource) {
    try {
      if ($PSVersionTable.PSVersion.Major -lt 6) {
        New-EventLog -LogName $logName -Source $EventSource
      }
      else {
        [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $logName)
      }
      Write-Host "Event source '$EventSource' created in log '$logName'" -ForegroundColor Green
    }
    catch {
      Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
    }
  }
    
  # Check if the event log exists
  if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
    # CreateEventLogSource $LogName $EventSource
  }
  # Check if the event source exists
  elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
    # Unregister the source if it's registered with a different log
    $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName
    if ($existingLogName -ne $LogName) {
      Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
    }
    # CreateEventLogSource $LogName $EventSource
  }
  else {
    Write-Host "Event source '$EventSource' already exists in log '$LogName'" -ForegroundColor Yellow
  }
}
    
$LogName = (Get-Date -Format "HHmmss") + "_IntuneWin32DeployerCustomlog"
$EventSource = (Get-Date -Format "HHmmss") + "_IntuneWin32DeployerCustomlog"
    
# Call the Create-EventSourceAndLog function
CreateEventSourceAndLog -LogName $LogName -EventSource $EventSource
    
# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'
    
    
    
    
function Write-EventLogMessage {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
    
    [string]$LogName = 'IntuneWin32DeployerCustomlog',
    [string]$EventSource,
    
    [int]$EventID = 1000  # Default event ID
  )
    
  $ErrorActionPreference = 'SilentlyContinue'
  $hadError = $false
    
  try {
    if (-not $EventSource) {
      throw "EventSource is required."
    }
    
    if ($PSVersionTable.PSVersion.Major -lt 6) {
      # PowerShell version is less than 6, use Write-EventLog
      Write-EventLog -LogName $logName -Source $EventSource -EntryType Information -EventId $EventID -Message $Message
    }
    else {
      # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
      $eventLog = New-Object System.Diagnostics.EventLog($logName)
      $eventLog.Source = $EventSource
      $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $EventID)
    }
    
    # Write-host "Event log entry created: $Message" 
  }
  catch {
    Write-host "Error creating event log entry: $_" 
    $hadError = $true
  }
    
  if (-not $hadError) {
    # Write-host "Event log message writing completed successfully."
  }
}
    
    
    
    
function Write-EnhancedLog {
  param (
    [string]$Message,
    [string]$Level = 'INFO',
    [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
    [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
    [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
    [switch]$UseModule = $false,
    [string]$Caller = (Get-PSCallStack)[0].Command
  )
    
  # Add timestamp, computer name, and log level to the message
  $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Level] [$Caller] $Message"
    
  # Set foreground color based on log level
  switch ($Level) {
    'INFO' { $ForegroundColor = [ConsoleColor]::Green }
    'WARNING' { $ForegroundColor = [ConsoleColor]::Yellow }
    'ERROR' { $ForegroundColor = [ConsoleColor]::Red }
  }
    
  # Write the message with the specified colors
  $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $ForegroundColor
  # Write-output $formattedMessage
  Write-host $formattedMessage
  $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    
  # Append to CSV file
  AppendCSVLog -Message $formattedMessage -CSVFilePath $CSVFilePath
  AppendCSVLog -Message $formattedMessage -CSVFilePath $CentralCSVFilePath
    
  # Write to event log (optional)
  # Write-CustomEventLog -EventMessage $formattedMessage -Level $Level

    
  # Adjust this line in your script where you call the function
  # Write-EventLogMessage -LogName $LogName -EventSource $EventSource -Message $formattedMessage -EventID 1001
    
}
    
function Export-EventLog {
  param (
    [Parameter(Mandatory = $true)]
    [string]$LogName,
    [Parameter(Mandatory = $true)]
    [string]$ExportPath
  )
    
  try {
    wevtutil epl $LogName $ExportPath
    
    if (Test-Path $ExportPath) {
      Write-EnhancedLog -Message "Event log '$LogName' exported to '$ExportPath'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }
    else {
      Write-EnhancedLog -Message "Event log '$LogName' not exported: File does not exist at '$ExportPath'" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    }
  }
  catch {
    Write-EnhancedLog -Message "Error exporting event log '$LogName': $($_.Exception.Message)" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
  }
}
    
    
    
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################
    
    
    
Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)



#################################################################################################################################
################################################# END LOGGING CHECK #############################################################
#################################################################################################################################





# function Get-AuthToken {

#   <#
# .SYNOPSIS
# This function is used to authenticate with the Graph API REST interface
# .DESCRIPTION
# The function authenticate with the Graph API Interface with the tenant name
# .EXAMPLE
# Get-AuthToken
# Authenticates you with the Graph API interface
# .NOTES
# NAME: Get-AuthToken
# #>

#   [CmdletBinding()]

#   param
#   (
#     [Parameter(Mandatory = $true)]
#     $User
#   )

#   $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

#   $tenant = $userUpn.Host

#   Write-Host "Checking for AzureAD module..."

#   $AadModule = Get-Module -Name "AzureAD" -ListAvailable

#   if ($AadModule -eq $null) {

#     Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
#     $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

#   }

#   if ($AadModule -eq $null) {
#     Write-Host
#     Write-Host "AzureAD Powershell module not installed..." -f Red
#     Write-Host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
#     Write-Host "Script can't continue..." -f Red
#     Write-Host
#     exit
#   }

#   # Getting path to ActiveDirectory Assemblies
#   # If the module count is greater than 1 find the latest version

#   if ($AadModule.count -gt 1) {

#     $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]

#     $aadModule = $AadModule | Where-Object { $_.Version -eq $Latest_Version.Version }

#     # Checking if there are multiple versions of the same module found

#     if ($AadModule.count -gt 1) {

#       $aadModule = $AadModule | Select-Object -Unique

#     }

#     $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
#     $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

#   }

#   else {

#     $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
#     $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

#   }

#   [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

#   [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

#   $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

#   $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

#   $resourceAppIdURI = "https://graph.microsoft.com"

#   $authority = "https://login.microsoftonline.com/$Tenant"

#   try {

#     $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

#     # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
#     # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

#     $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

#     $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

#     $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result

#     # If the accesstoken is valid then create the authentication header

#     if ($authResult.AccessToken) {

#       # Creating header for Authorization token

#       $authHeader = @{
#         'Content-Type'  = 'application/json'
#         'Authorization' = "Bearer " + $authResult.AccessToken
#         'ExpiresOn'     = $authResult.ExpiresOn
#       }

#       return $authHeader

#     }

#     else {

#       Write-Host
#       Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
#       Write-Host
#       break

#     }

#   }

#   catch {

#     Write-Host $_.Exception.Message -f Red
#     Write-Host $_.Exception.ItemName -f Red
#     Write-Host
#     break

#   }

# }







Connect-MSIntuneGraph @connectionParams


# Convert the Client Secret to a SecureString
# $SecureClientSecret = ConvertTo-SecureString $connectionParams.ClientSecret -AsPlainText -Force

# Create a PSCredential object with the Client ID as the user and the Client Secret as the password
# $ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($connectionParams.ClientId, $SecureClientSecret)

# Connect to Microsoft Graph
# Connect-MgGraph -TenantId $connectionParams.TenantId -ClientSecretCredential $ClientSecretCredential

Connect-MgGraph



$clientId = $connectionParams.ClientId
# $tenantName = "bellwoodscentres.onmicrosoft.com"
$tenantID = $connectionParams.TenantId
    
# $RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
    
    
    
    
    
# # Token endpoint
# $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    
# # Prepare the request body. Exclude 'client_secret' if your app is a public client.
# $body = @{
#     client_id     = $clientId
#     grant_type    = "refresh_token"
#     refresh_token = $refreshToken
#     # Uncomment the next line if your application is a confidential client
#     scope         = "https://graph.microsoft.com/.default"  # Adjust this scope according to your needs
# }
    
# # Make the POST request
# $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    
# # Output the new access token and refresh token
# # Write-Host "New Access Token: $($response.access_token)" #uncomment for debugging
# # Some authorization servers might not return a new refresh token every time you refresh an access token
# if ($response.refresh_token) {
#     # Write-Host "New Refresh Token: $($response.refresh_token)" #uncomment for debugging
# }
    
    
# $AccessToken = $response.access_token

# # $authToken = $AccessToken
    
    
# # $AccessToken | clip.exe
    
# # $DBG
    
# # Set up headers for API requests
# $headers = @{
#     "Authorization" = "Bearer $($AccessToken)"
#     "Content-Type"  = "application/json"
# }

# $authToken = $headers



# Adjusted script parts for client credentials flow

# Token endpoint
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Prepare the request body for client credentials flow
$body = @{
  client_id     = $clientId
  scope         = "https://graph.microsoft.com/.default" # Ensure this scope is consistent with what your application requires
  grant_type    = "client_credentials" # Use client_credentials for the grant type
  client_secret = $connectionParams.ClientSecret # Your client secret
}

# Make the POST request to get the access token
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

$AccessToken = $response.access_token

# Prepare headers for subsequent API requests
$headers = @{
  "Authorization" = "Bearer $($AccessToken)"
  "Content-Type"  = "application/json"
}

$global:authToken = $headers

# Now you can use $headers for making API requests


Write-EnhancedLog -Message "built authtoken as a header $authToken" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


####################################################

# function Get-Win10IntuneManagedDevice {

#   <#
# .SYNOPSIS
# This gets information on Intune managed devices
# .DESCRIPTION
# This gets information on Intune managed devices
# .EXAMPLE
# Get-Win10IntuneManagedDevice
# .NOTES
# NAME: Get-Win10IntuneManagedDevice
# #>

#   #[cmdletbinding()]


#   <#

# param
# (
# [parameter(Mandatory=$false)]
# [ValidateNotNullOrEmpty()]
# [string]$deviceName
# )

# #>
#   # Write-Host "To search Intune for assigned objects, enter either the full name of an Azure AD device or a filename (e.g. 'Somedevices.txt') in this script's folder containing multiple Azure AD devices: " -ForegroundColor Yellow
#   # $DeviceName = Read-Host
#   $DeviceName = "somedevices.txt"
#   #What was provided?
#   if ($DeviceName.EndsWith(".txt", "CurrentCultureIgnoreCase")) {
#     #It's a file
#     #Confirm the file exists
#     if (!(Test-Path -Path "$Dir\$DeviceName")) {
#       #File does not exist
#       Write-Host ""
#       Write-Host "Provided filename of devices cannot be found.  Try again." -ForegroundColor Red
#       Write-Host ""
#       #Wait for the user...
#       Read-Host -Prompt "When ready, press 'Enter' to exit..."
#       exit
#     }
#     else {
#       #File exists - get data into an array
#       $a_DeviceNames = Get-Content "$Dir\$DeviceName"
#       if ($a_DeviceNames.count -eq 0) {
#         #No data in file
#         Write-Host ""
#         Write-Host "Provided filename of devices is empty.  Try again." -ForegroundColor Red
#         Write-Host ""
#         #Wait for the user...
#         Read-Host -Prompt "When ready, press 'Enter' to exit..."
#         exit
#       }
#       elseif ($a_DeviceNames.count -eq 1) {
#         #It's a single device
#         #No need to pause
#         $b_Pause = $false
#       }
#     }
#   }
#   else {
#     #It's a single device
#     $a_DeviceNames = @($DeviceName)

#     #No need to pause
#     $b_Pause = $false
#   }
#   # Write-Host ""

#   # Clear-Host
#   # Write-Host "Data validation is in progress ..." -ForegroundColor Green
#   # $i_TotalDevices = $a_DeviceNames.count
#   # Write-Host ""
#   # Write-Host "Total devices found : $i_TotalDevices . Press 'Enter' to report on all objects, or type 'n' then press 'Enter' to exit the script: " -ForegroundColor Yellow -NoNewline
#   # $Scope = Read-Host
#   # Write-Host "Input is recieved, Script execution is in progress..." -ForegroundColor green

#   if ($Scope -ieq "n") {
#     $b_ScopeAll = $false
#   }
#   else {
#     $b_ScopeAll = $true
#   }
#   # Write-Host ""

#   #Continue to report the data for all device objects
#   if ($b_ScopeAll) {

#     foreach ($DeviceName in $a_DeviceNames) {

#       $graphApiVersion = "beta"

#       try {

#         if ($deviceName) {

#           $Resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$deviceName'"
#           $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"



#           # Write-Host "calling Invoke-RestMethod for https://graph.microsoft.com/$graphApiVersion/$($Resource) "
#           # Write-EnhancedLog -Message "calling Invoke-RestMethod for https://graph.microsoft.com/$graphApiVersion/$($Resource) " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
          
#           (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

#         }

#         else {

#           $Resource = "deviceManagement/managedDevices?`$filter=(((deviceType%20eq%20%27desktop%27)%20or%20(deviceType%20eq%20%27windowsRT%27)%20or%20(deviceType%20eq%20%27winEmbedded%27)%20or%20(deviceType%20eq%20%27surfaceHub%27)))"
#           $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

#           (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

#         }

#       }
#       catch {
#         $ex = $_.Exception
#         $errorResponse = $ex.Response.GetResponseStream()
#         $reader = New-Object System.IO.StreamReader ($errorResponse)
#         $reader.BaseStream.Position = 0
#         $reader.DiscardBufferedData()
#         $responseBody = $reader.ReadToEnd();
#         Write-Host "Response content:`n$responseBody" -f Red
#         Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
#         throw "Get-IntuneManagedDevices error"
#       }

#     }

#   }

#   else {
#     Write-Host "User has stopped the script due to revalidation of the input objects.." -ForegroundColor Red
#     exit
#   }

# }









function Get-Win10IntuneManagedDevice {

  <#
  .SYNOPSIS
  Gets information on all Windows 10 Intune managed devices.
  .DESCRIPTION
  Utilizes the Microsoft Graph PowerShell SDK to retrieve information on all Windows 10 Intune managed devices.
  .EXAMPLE
  Get-Win10IntuneManagedDevice
  .NOTES
  NAME: Get-Win10IntuneManagedDevice
  REQUIRES: Microsoft.Graph.Intune, Microsoft.Graph.Authentication
  #>

  [CmdletBinding()]
  param ()

  try {
      # Ensure you are connected to Microsoft Graph with Connect-MgGraph prior to executing this function
      # Filtering devices by deviceType might require specific adjustments based on available properties and your requirements
      $devices = Get-MgDeviceManagementManagedDevice -All

      # Filter for Windows 10 devices. Adjust the filter criteria based on your specific needs and the properties of the devices
      # $win10Devices = $devices | Where-Object { $_.OperatingSystem -eq "Windows" -and $_.OsVersion -like "10.*" }

      # Output the filtered list of Windows 10 devices
      # return $win10Devices
      return $devices

  } catch {
      Write-Host "An error occurred: $_" -ForegroundColor Red
      # Optionally, rethrow or handle the exception as needed
  }
}







Write-EnhancedLog -Message "calling Invoke-RestMethod for all devices " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

####################################################

function Get-AADUser () {

  <#
.SYNOPSIS
This function is used to get AAD Users from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any users registered with AAD
.EXAMPLE
Get-AADUser
Returns all users registered with Azure AD
.EXAMPLE
Get-AADUser -userPrincipleName user@domain.com
Returns specific user by UserPrincipalName registered with Azure AD
.NOTES
NAME: Get-AADUser
#>

  [CmdletBinding()]

  param
  (
    $userPrincipalName,
    $Property

  )

  # Defining Variables
  $graphApiVersion = "v1.0"
  $User_resource = "users"

  try {

    if ($userPrincipalName -eq "" -or $userPrincipalName -eq $null) {

      $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
      (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ErrorAction SilentlyContinue).Value

    }

    else {

      if ($Property -eq "" -or $Property -eq $null) {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName"
        Write-Verbose $uri
        try {
          Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ErrorAction SilentlyContinue
        }
        catch {
          #Write-Warning "Unable to find the UPN $userPrincipalName"
        }
      }

      else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
        Write-Verbose $uri

        try {
          (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ErrorAction SilentlyContinue).Value
        }
        catch {
          #Write-Warning "Unable to find the UPN $userPrincipalName"
        }
      }

    }

  }

  catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader ($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    Write-Host
    break

  }

}

####################################################

# function Get-IntuneDevicePrimaryUser {

#   <#
# .SYNOPSIS
# This lists the Intune device primary user
# .DESCRIPTION
# This lists the Intune device primary user
# .EXAMPLE
# Get-IntuneDevicePrimaryUser
# .NOTES
# NAME: Get-IntuneDevicePrimaryUser
# #>

#   [CmdletBinding()]

#   param
#   (
#     [Parameter(Mandatory = $true)]
#     [string]$deviceId
#   )
#   $graphApiVersion = "beta"
#   $Resource = "deviceManagement/managedDevices"
#   $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" + "/" + $deviceId + "/users"

#   try {

#     $primaryUser = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

#     return $primaryUser.Value. "id"

#   }
#   catch {
#     $ex = $_.Exception
#     $errorResponse = $ex.Response.GetResponseStream()
#     $reader = New-Object System.IO.StreamReader ($errorResponse)
#     $reader.BaseStream.Position = 0
#     $reader.DiscardBufferedData()
#     $responseBody = $reader.ReadToEnd();
#     Write-Host "Response content:`n$responseBody" -f Red
#     Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

#     #throw "Get-IntuneDevicePrimaryUser error"
#   }
# }




##############################################################


# function Get-IntuneDevicePrimaryUser {

#   <#
#   .SYNOPSIS
#   This lists the Intune device primary user.
#   .DESCRIPTION
#   This function utilizes the Microsoft Graph PowerShell SDK to list the primary user of an Intune device.
#   .EXAMPLE
#   Get-IntuneDevicePrimaryUser -deviceId "your_device_id_here"
#   .NOTES
#   NAME: Get-IntuneDevicePrimaryUser
#   REQUIRES: Microsoft.Graph.Intune, Microsoft.Graph.Authentication
#   #>

#   [CmdletBinding()]
#   param (
#     [Parameter(Mandatory = $true)]
#     [string]$deviceId
#   )

#   try {
#     # Ensure you are connected to Microsoft Graph with Connect-MgGraph prior to executing this function
#     $primaryUser = Get-MgDeviceManagementManagedDeviceUser -DeviceId $deviceId

#     if ($null -ne $primaryUser -and $primaryUser.Count -gt 0) {
#       # Assuming the primary user is always the first one listed
#       return $primaryUser[0].Id
#     }
#     else {
#       Write-Output "No primary user found for device ID: $deviceId"
#     }
#   }
#   catch {
#     Write-Host "An error occurred: $_" -ForegroundColor Red
#     # Optionally, rethrow or handle the exception as needed
#   }
# }

##############################################################



function Get-IntuneDevicePrimaryUser {

  <#
  .SYNOPSIS
  This lists the Intune device primary user.
  .DESCRIPTION
  This function utilizes the Microsoft Graph PowerShell SDK to list the primary user of an Intune device.
  .EXAMPLE
  Get-IntuneDevicePrimaryUser -ManagedDeviceId "your_device_id_here"
  .NOTES
  NAME: Get-IntuneDevicePrimaryUser
  REQUIRES: Microsoft.Graph.Intune, Microsoft.Graph.Authentication
  #>

  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [string]$ManagedDeviceId
  )

  try {
      # Ensure you are connected to Microsoft Graph with Connect-MgGraph prior to executing this function
      $primaryUser = Get-MgDeviceManagementManagedDeviceUser -ManagedDeviceId $ManagedDeviceId

      if ($null -ne $primaryUser -and $primaryUser.Count -gt 0) {
          # Assuming the primary user is always the first one listed
          return $primaryUser[0].Id
      } else {
          Write-Output "No primary user found for managed device ID: $ManagedDeviceId"
      }
  } catch {
      Write-Host "An error occurred: $_" -ForegroundColor Red
      # Optionally, rethrow or handle the exception as needed
  }
}




####################################################

function Set-IntuneDevicePrimaryUser {

  <#
.SYNOPSIS
This updates the Intune device primary user
.DESCRIPTION
This updates the Intune device primary user
.EXAMPLE
Set-IntuneDevicePrimaryUser
.NOTES
NAME: Set-IntuneDevicePrimaryUser
#>

  [CmdletBinding()]

  param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $IntuneDeviceId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $userId
  )
  $graphApiVersion = "beta"
  $Resource = "deviceManagement/managedDevices('$IntuneDeviceId')/users/`$ref"

  try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

    $userUri = "https://graph.microsoft.com/$graphApiVersion/users/" + $userId

    $id = "@odata.id"
    $JSON = @{ $id = "$userUri" } | ConvertTo-Json -Compress

    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

  }
  catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader ($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    throw "Set-IntuneDevicePrimaryUser error"
  }

}

####################################################

# #region Authentication

# Write-Host

# # Checking if authToken exists before running authentication
# if ($global:authToken) {

#   # Setting DateTime to Universal time to work in all timezones
#   $DateTime = (Get-Date).ToUniversalTime()

#   # If the authToken exists checking when it expires
#   $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

#   if ($TokenExpires -le 0) {

#     Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
#     Write-Host

#     # Defining User Principal Name if not present

#     if ($User -eq $null -or $User -eq "") {
#       $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
#       Write-Host
#     }

#     $global:authToken = Get-AuthToken -User $User
#   }
# }

# # Authentication doesn't exist, calling Get-AuthToken function

# else {

#   if ($User -eq $null -or $User -eq "") {
#     $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
#     Write-Host
#   }

#   # Getting the authorization token
#   $global:authToken = Get-AuthToken -User $User
# }

# #endregion

####################################################

$date = (Get-Date -f ddMMyyyy_hhmmss)
$outlog = "$dir\Whatif_SetPrimaryUPN_$($date).csv"
#Get All Windows 10 Intune Managed Devices for the Tenant

Write-EnhancedLog -Message "calling Get-Win10IntuneManagedDevice " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
$Devices = Get-Win10IntuneManagedDevice
Write-EnhancedLog -Message "calling Get-Win10IntuneManagedDevice - done " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


Write-EnhancedLog -Message "starting to iterate through all devices " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

foreach ($Device in $Devices) {


  # Write-Host "Device name:" $device."deviceName" -ForegroundColor Cyan

  $Deviceid = $Device.id

  Write-EnhancedLog -Message "calling Get-IntuneDevicePrimaryUser for Device $Device with Device ID $Deviceid " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
  # $IntuneDevicePrimaryUser = Get-IntuneDevicePrimaryUser -DeviceId $Device.id -ErrorAction SilentlyContinue
  $IntuneDevicePrimaryUser = Get-IntuneDevicePrimaryUser -ManagedDeviceId $Device.Id -ErrorAction SilentlyContinue
  

  Write-EnhancedLog -Message "calling Get-IntuneDevicePrimaryUser - done " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

  #Check if there is a Primary user set on the device already
  if ($IntuneDevicePrimaryUser -eq $null) {

    # Write-Host "No Intune Primary User Id set for Intune Managed Device" $Device."deviceName" -f Red 

  }

  else {
    try { $PrimaryAADUser = Get-AADUser -UserPrincipalName $IntuneDevicePrimaryUser }
    catch {
      $device.deviceName
      $device.id
      $PrimaryAADUser.DisplayName
    }
    # Write-Host "Intune Device Primary User:" $PrimaryAADUser.displayName
  }
  #Get the objectID of the last logged in user for the device, which is the last object in the list of usersLoggedOn
  $LastLoggedInUser = ($Device.usersLoggedOn[-1]).userId

  if ($LastLoggedInUser) {
    #Using the objectID, get the user from the Microsoft Graph for logging purposes
    $User = Get-AADUser -UserPrincipalName $LastLoggedInUser -ErrorAction SilentlyContinue
  }
  else {}

  #Arry 
  $user = [pscustomobject]@{
    'Device Name'   = $device.deviceName
    'Device ID'     = $device.id
    'Current User'  = $PrimaryAADUser.DisplayName
    'Expected User' = $User.DisplayName
  }

  $user | Export-Csv $outlog -Append -NoTypeInformation -Force

}
# Write-Host "script Execution is completed, please read the file located at $outlog" -ForegroundColor Green

Write-EnhancedLog -Message "script Execution is completed, please read the file located at $outlog " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

exit
