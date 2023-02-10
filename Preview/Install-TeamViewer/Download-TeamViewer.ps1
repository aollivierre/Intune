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


$ScriptRoot2 = $null
$ScriptRoot2 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}


function Download-TeamViewer {
    [CmdletBinding()]
    param (
        
    )
    
    begin {

        # Download the Agent
        # $AgentURL = "https://get.teamviewer.com/he26pyq"
        $AgentURL = "https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?path=/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=zip&api-version=5.0&download=true"
        $DownloadStart = Get-Date 
        
        Write-Output "Starting Agent download at $(Get-Date -Format HH:mm) from $AgentURL"
        try { [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072) }
        catch { Write-Output "Cannot download Agent due to invalid security protocol. The`r`nfollowing security protocols are installed and available:`r`n$([enum]::GetNames([Net.SecurityProtocolType]))`r`nAgent download requires at least TLS 1.2 to succeed.`r`nPlease install TLS 1.2 and rerun the script." ; exit 1 }
        
        
    
        
    }
    
    process {

        try {


            # $splitpath2 = Split-Path -Path $ScriptRoot2
            # $desiredpath2 = "$splitpath2\files"

            # try { (New-Object System.Net.WebClient).DownloadFile($AgentURL, "$desiredpath2\TeamViewer.zip") } 
            try { (New-Object System.Net.WebClient).DownloadFile($AgentURL, "c:\cci\scripts\Download-TeamViewer.zip") }
            catch { $host.ui.WriteErrorLine("Agent installer download failed. Exit message:`r`n$_") ; exit 1 } 


            # (New-Object System.Net.WebClient).DownloadFile("$AgentURL", "$desiredpath2\TeamViewer.zip")
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

        # Remove-Item "$env:TEMP\eea.msi" -Force
        # Exit
        
    }
}

Download-TeamViewer