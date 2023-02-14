<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.


            Datto RMM Agent deploy by MS Azure Intune 
            Designed and written by Jon North, Datto, March 2020 
            Download the Agent installer, run it, wait for it to finish, delete it 
     

.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'

Starting Agent download at 23:42 from https://zinfandel.centrastage.net/csm/profile/downloadAgent/a4ebb808-023a-4469-bca2-da440e08adbc
Agent download completed in 7 seconds


Starting Agent install to target site at 23:42...
Agent install completed at 23:42 in 11 seconds.

.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.

    https://rmm.datto.com/help/en/Content/4WEBPORTAL/Devices/ServersLaptopsDesktops/Windows/MicrosoftEndpointManagerDeploy.htm
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

$ScriptRoot2 = $null
$ScriptRoot2 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}


function Download-DattoWin32App {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = "ParameterSetName",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("RMMPlatform")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Platform,

        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = "ParameterSetName",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("RMMSiteID")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SiteID
        
    )
    
    begin {

        # Download the Agent
        $AgentURL = "https://$Platform.centrastage.net/csm/profile/downloadAgent/$SiteID" 
        $DownloadStart = Get-Date 
        
        Write-Output "Starting Agent download at $(Get-Date -Format HH:mm) from $AgentURL"
        try { [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072) }
        catch { Write-Output "Cannot download Agent due to invalid security protocol. The`r`nfollowing security protocols are installed and available:`r`n$([enum]::GetNames([Net.SecurityProtocolType]))`r`nAgent download requires at least TLS 1.2 to succeed.`r`nPlease install TLS 1.2 and rerun the script." ; exit 1 }
        
        
    
        
    }
    
    process {

        try {


            $splitpath2 = Split-Path -Path $ScriptRoot2
            $desiredpath2 = "$splitpath2\files"

            try { (New-Object System.Net.WebClient).DownloadFile($AgentURL, "$desiredpath2\DRMMSetup.exe") } 
            catch { $host.ui.WriteErrorLine("Agent installer download failed. Exit message:`r`n$_") ; exit 1 } 
            Write-Output "Agent download completed in $((Get-Date).Subtract($DownloadStart).Seconds) seconds`r`n`r`n" 
      
            # Install the Agent (commented out as it will be handled by PSADT)
            # $InstallStart = Get-Date 
            # Write-Output "Starting Agent install to target site at $(Get-Date -Format HH:mm)..." 
            # & "$env:TEMP\DRMMSetup.exe" | Out-Null 
            # Write-Output "Agent install completed at $(Get-Date -Format HH:mm) in $((Get-Date).Subtract($InstallStart).Seconds) seconds."
           
        }
    
        <#Do this if a terminating exception happens#>

        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
                
                
            $ErrorMessage_1 = $_.Exception.Message
            write-host $ErrorMessage_1  -ForegroundColor Red
            Write-Output "Ran into an issue: $PSItem"
            Write-host "Ran into an issue: $PSItem" -ForegroundColor Red
            throw "Ran into an issue: $PSItem"
            throw "I am the catch"
            throw "Ran into an issue: $PSItem"
            $PSItem | Write-host -ForegroundColor
            $PSItem | Select-Object *
            $PSCmdlet.ThrowTerminatingError($PSitem)
            throw
            throw "Something went wrong"
            Write-Log $PSItem.ToString()
                
        }
            
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
        
    }
    
    end {

        # Remove-Item "$env:TEMP\DRMMSetup.exe" -Force
        # Exit
        
    }
}


# Copy the platform name of your Datto RMM account and paste it between the quotes of the $Platform="<Paste your platform name here>" line. The platform name is at the start of the URL; it will be Pinotage or Merlot (EMEA), Concord or Zinfandel (NA), or Syrah (APAC). https://rmm.datto.com/help/en/Content/Resources/Images/4WEBPORTALImages/Devices/WinMacLinux/Deploy/MSIntune1.png
# $Platform = 'zinfandel'

# Copy the target site ID and paste it between the quotes of the $SiteID="<paste your Site ID here>" line. You can get this from the site list by clicking the Sites tab https://rmm.datto.com/help/en/Content/Resources/Images/4WEBPORTALImages/Devices/WinMacLinux/Deploy/MSIntune2.png
# $SiteID = 'a4ebb808-023a-4469-bca2-da440e08adbc'


# $downloadDattoWin32AppSplat = @{
#     Platform = $Platform
#     SiteID   = $SiteID
# }
# Download-DattoWin32App @downloadDattoWin32AppSplat