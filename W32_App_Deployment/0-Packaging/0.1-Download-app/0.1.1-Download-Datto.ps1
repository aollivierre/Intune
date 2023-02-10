<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>



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
        [Alias("PSPath")]
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
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SiteID
        
    )
    
    begin {


        # First check if Agent is installed and instantly exit if so
        If (Get-Service CagService -ErrorAction SilentlyContinue) { Write-Output "Datto RMM Agent already installed on this device" ; exit } 



        # Download the Agent
        $AgentURL = "https://$Platform.centrastage.net/csm/profile/downloadAgent/$SiteID" 
        $DownloadStart = Get-Date 
        
        Write-Output "Starting Agent download at $(Get-Date -Format HH:mm) from $AgentURL"
        try { [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072) }
        catch { Write-Output "Cannot download Agent due to invalid security protocol. The`r`nfollowing security protocols are installed and available:`r`n$([enum]::GetNames([Net.SecurityProtocolType]))`r`nAgent download requires at least TLS 1.2 to succeed.`r`nPlease install TLS 1.2 and rerun the script." ; exit 1 }
        
        
        try { (New-Object System.Net.WebClient).DownloadFile($AgentURL, "$env:TEMP\DRMMSetup.exe") } 
        catch { $host.ui.WriteErrorLine("Agent installer download failed. Exit message:`r`n$_") ; exit 1 } 
        Write-Output "Agent download completed in $((Get-Date).Subtract($DownloadStart).Seconds) seconds`r`n`r`n" 
        
    }
    
    process {

        try {
            <# 
Datto RMM Agent deploy by MS Azure Intune 
Designed and written by Jon North, Datto, March 2020 
Download the Agent installer, run it, wait for it to finish, delete it 
#> 
            # Install the Agent
            $InstallStart = Get-Date 
            Write-Output "Starting Agent install to target site at $(Get-Date -Format HH:mm)..." 
            & "$env:TEMP\DRMMSetup.exe" | Out-Null 
            Write-Output "Agent install completed at $(Get-Date -Format HH:mm) in $((Get-Date).Subtract($InstallStart).Seconds) seconds."
           
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
        
    }
    
    end {

        Remove-Item "$env:TEMP\DRMMSetup.exe" -Force
        Exit
        
    }
}



$Platform = 'zinfandel'
$SiteID = 'a4ebb808-023a-4469-bca2-da440e08adbc'
$downloadDattoWin32AppSplat = @{
    Platform = $Platform
    SiteID = $SiteID
}
Download-DattoWin32App @downloadDattoWin32AppSplat