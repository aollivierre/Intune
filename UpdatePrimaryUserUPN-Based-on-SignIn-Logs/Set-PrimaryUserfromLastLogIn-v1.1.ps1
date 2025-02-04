
<#
.Synopsis
   Get primary user UPN if not matches to current user, update the primary user for intune managed devices.
.DESCRIPTION
    For a given Intune device name (or file name of device names) connects to MS Graph and:
      validates the input if single or multiple devices in txt file.
      Read through th each device and connect to graph to fetch the current user and expected user and set the primary user.
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

####################################################

function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

  [CmdletBinding()]

  param
  (
    [Parameter(Mandatory = $true)]
    $User
  )

  $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

  $tenant = $userUpn.Host

  Write-Host "Checking for AzureAD module..."

  $AadModule = Get-Module -Name "AzureAD" -ListAvailable

  if ($AadModule -eq $null) {

    Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
    $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

  }

  if ($AadModule -eq $null) {
    Write-Host
    Write-Host "AzureAD Powershell module not installed..." -f Red
    Write-Host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
    Write-Host "Script can't continue..." -f Red
    Write-Host
    exit
  }

  # Getting path to ActiveDirectory Assemblies
  # If the module count is greater than 1 find the latest version

  if ($AadModule.count -gt 1) {

    $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]

    $aadModule = $AadModule | Where-Object { $_.Version -eq $Latest_Version.Version }

    # Checking if there are multiple versions of the same module found

    if ($AadModule.count -gt 1) {

      $aadModule = $AadModule | Select-Object -Unique

    }

    $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

  }

  else {

    $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

  }

  [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

  [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

  $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

  $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

  $resourceAppIdURI = "https://graph.microsoft.com"

  $authority = "https://login.microsoftonline.com/$Tenant"

  try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User,"OptionalDisplayableId")

    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

    # If the accesstoken is valid then create the authentication header

    if ($authResult.AccessToken) {

      # Creating header for Authorization token

      $authHeader = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer " + $authResult.AccessToken
        'ExpiresOn' = $authResult.ExpiresOn
      }

      return $authHeader

    }

    else {

      Write-Host
      Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
      Write-Host
      break

    }

  }

  catch {

    Write-Host $_.Exception.Message -f Red
    Write-Host $_.Exception.ItemName -f Red
    Write-Host
    break

  }

}

####################################################

function Get-Win10IntuneManagedDevice {

<#
.SYNOPSIS
This gets information on Intune managed devices
.DESCRIPTION
This gets information on Intune managed devices
.EXAMPLE
Get-Win10IntuneManagedDevice
.NOTES
NAME: Get-Win10IntuneManagedDevice
#>

  #[cmdletbinding()]


  <#

param
(
[parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
[string]$deviceName
)

#>
  Write-Host "To search Intune for assigned objects, enter either the full name of an Azure AD device or a filename (e.g. 'Somedevices.txt') in this script's folder containing multiple Azure AD devices: " -ForegroundColor Yellow
  $DeviceName = Read-Host
  #What was provided?
  if ($DeviceName.EndsWith(".txt","CurrentCultureIgnoreCase"))
  {
    #It's a file
    #Confirm the file exists
    if (!(Test-Path -Path "$Dir\$DeviceName"))
    {
      #File does not exist
      Write-Host ""
      Write-Host "Provided filename of devices cannot be found.  Try again." -ForegroundColor Red
      Write-Host ""
      #Wait for the user...
      Read-Host -Prompt "When ready, press 'Enter' to exit..."
      exit
    }
    else
    {
      #File exists - get data into an array
      $a_DeviceNames = Get-Content "$Dir\$DeviceName"
      if ($a_DeviceNames.count -eq 0)
      {
        #No data in file
        Write-Host ""
        Write-Host "Provided filename of devices is empty.  Try again." -ForegroundColor Red
        Write-Host ""
        #Wait for the user...
        Read-Host -Prompt "When ready, press 'Enter' to exit..."
        exit
      }
      elseif ($a_DeviceNames.count -eq 1)
      {
        #It's a single device
        #No need to pause
        $b_Pause = $false
      }
    }
  }
  else
  {
    #It's a single device
    $a_DeviceNames = @($DeviceName)

    #No need to pause
    $b_Pause = $false
  }
  Write-Host ""

  Clear-Host
  Write-Host "Data validation is in progress ..." -ForegroundColor Green
  $i_TotalDevices = $a_DeviceNames.count
  Write-Host ""
  Write-Host "Total devices found : $i_TotalDevices . Press 'Enter' to report on all objects, or type 'n' then press 'Enter' exit the script: " -ForegroundColor Yellow -NoNewline
  $Scope = Read-Host
  Write-Host "Script execution is in progress..." -ForegroundColor green
  if ($Scope -ieq "n")
  {
    $b_ScopeAll = $false
  }
  else
  {
    $b_ScopeAll = $true
  }
  Write-Host ""

  #Continue to report the data for all device objects
  if ($b_ScopeAll)
  {

    foreach ($DeviceName in $a_DeviceNames)
    {

      $graphApiVersion = "beta"

      try {

        if ($deviceName) {

          $Resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$deviceName'"
          $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

          (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        else {

          $Resource = "deviceManagement/managedDevices?`$filter=(((deviceType%20eq%20%27desktop%27)%20or%20(deviceType%20eq%20%27windowsRT%27)%20or%20(deviceType%20eq%20%27winEmbedded%27)%20or%20(deviceType%20eq%20%27surfaceHub%27)))"
          $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

          (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

      } catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader ($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        throw "Get-IntuneManagedDevices error"
      }

    }

  }

  else
  {
    Write-Host "User has stopped the script due to revalidation of the input objects.." -ForegroundColor Red
    exit
  }

}



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
        try
        {
          Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ErrorAction SilentlyContinue
        }
        catch { Write-Warning "Unable to find the UPN $userPrincipalName" }
      }

      else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
        Write-Verbose $uri

        try
        {
          (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ErrorAction SilentlyContinue).Value
        }
        catch { Write-Warning "Unable to find the UPN $userPrincipalName" }
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

function Get-IntuneDevicePrimaryUser {

<#
.SYNOPSIS
This lists the Intune device primary user
.DESCRIPTION
This lists the Intune device primary user
.EXAMPLE
Get-IntuneDevicePrimaryUser
.NOTES
NAME: Get-IntuneDevicePrimaryUser
#>

  [CmdletBinding()]

  param
  (
    [Parameter(Mandatory = $true)]
    [string]$deviceId
  )
  $graphApiVersion = "beta"
  $Resource = "deviceManagement/managedDevices"
  $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" + "/" + $deviceId + "/users"

  try {

    $primaryUser = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

    return $primaryUser.Value. "id"

  } catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader ($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    throw "Get-IntuneDevicePrimaryUser error"
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

  } catch {
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

#region Authentication

Write-Host

# Checking if authToken exists before running authentication
if ($global:authToken) {

  # Setting DateTime to Universal time to work in all timezones
  $DateTime = (Get-Date).ToUniversalTime()

  # If the authToken exists checking when it expires
  $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

  if ($TokenExpires -le 0) {

    Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
    Write-Host

    # Defining User Principal Name if not present

    if ($User -eq $null -or $User -eq "") {
      $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
      Write-Host
    }

    $global:authToken = Get-AuthToken -User $User
  }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

  if ($User -eq $null -or $User -eq "") {
    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host
  }

  # Getting the authorization token
  $global:authToken = Get-AuthToken -User $User
}

#endregion

####################################################

$date = (Get-Date -f ddMMyyyy_hhmmss)
$outlog = "$dir\Update_PrimaryUPN_$($date).csv"
#Get All Windows 10 Intune Managed Devices for the Tenant
$Devices = Get-Win10IntuneManagedDevice

foreach ($Device in $Devices) {


  # Write-Host "Device name:" $device."deviceName" -ForegroundColor Cyan
  $IntuneDevicePrimaryUser = Get-IntuneDevicePrimaryUser -DeviceId $Device.id
  $Deviceid = $Device.id

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

  if ($LastLoggedInUser)
  {

    #Using the objectID, get the user from the Microsoft Graph for logging purposes
    $User = Get-AADUser -UserPrincipalName $LastLoggedInUser -ErrorAction SilentlyContinue

    #Check if the current primary user of the device is the same as the last logged in user
    if ($IntuneDevicePrimaryUser -notmatch $User.id) {

      #If the user does not match, then set the last logged in user as the new Primary User

      try
      {
      $SetIntuneDevicePrimaryUser = Set-IntuneDevicePrimaryUser -IntuneDeviceId $Device.id -userId $User.id

      if ($SetIntuneDevicePrimaryUser -eq "") {

      #Write-Host "User"$User.displayName"set as Primary User for device '$($Device.deviceName)'..." -ForegroundColor Green
      $status="Success"
      }
      }
      catch
      {
      Write-Host "Filed to set User"$User.displayName" as Primary User for device '$($Device.deviceName)'..." -ForegroundColor red
      $status="Failure"
      }

      }

    else {
      #If the user is the same, then write to host that the primary user is already correct.
      #   Write-Host "The user '$($User.displayName)' is already the Primary User on the device..." -ForegroundColor Yellow

    }
  }

  $user = [pscustomobject]@{
    'Device Name' = $device.deviceName
    'Device ID' = $device.id
    'Current User' = $PrimaryAADUser.DisplayName
    'Changed to' = $User.DisplayName
    'Status'=$status
  }

  $user | Export-Csv $outlog -Append -NoTypeInformation -Force

}