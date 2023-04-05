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


function Connect-AzDevOps {
    [CmdletBinding()]
    param (
    
        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        # [Parameter(Mandatory = $true,
        #     Position = 0,
        #     ParameterSetName = "LiteralPath",
        #     ValueFromPipelineByPropertyName = $true,
        #     HelpMessage = "Literal path to one or more locations.")]
        # [Alias("PSPath")]
        # [ValidateNotNullOrEmpty()]
        # [string[]]
        # $LiteralPath

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        $token,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        $uriGetFile,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        $OutfilePath


    )
    
    begin {


        $user = ""
        # $orgUrl = "CanadaComputingInc"
        # $orgname = "CanadaComputingInc"
        # $teamProject = "edb7565a-620a-4960-89ae-96e7765b9202"
        # $repoName = "4e3325c7-0dba-4f5c-9c3f-0e6b96208c22"
        # $GitFilePath = "/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip"
        # $token = "d36lhpn4wyfrvswmqfms5dbawrizdh5uqgxrmbi5h3shajii5yfa"


        # $OutfilePath = $null
        # $OutfilePath = "C:\cci\scripts\Toolkit11.zip"
        
    }
    
    process {

        try {


            # $user = ""
            # $token = $env:SYSTEM_ACCESSTOKEN
            # $teamProject = $env:SYSTEM_TEAMPROJECT
            # $orgUrl = $env:SYSTEM_COLLECTIONURI
            # $repoName = "REPO_NAME"

            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

        
            Write-Host "Download file" $GitFilePath "to" $OutFilePath
     
            # $uriGetFile = "https://dev.azure.com/$orgname/$teamProject/_apis/git/repositories/$repoName/items?scopePath=$GitFilePath&download=true&api-version=6.1-preview.1"
    
            Write-Host "Url:" $uriGetFile
    

            Write-Output "Starting Agent download at $(Get-Date -Format HH:mm) from $uriGetFile"
            try { [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072) }
            catch { Write-Output "Cannot download Agent due to invalid security protocol. The`r`nfollowing security protocols are installed and available:`r`n$([enum]::GetNames([Net.SecurityProtocolType]))`r`nAgent download requires at least TLS 1.2 to succeed.`r`nPlease install TLS 1.2 and rerun the script." ; exit 1 }


            $wc = New-Object System.Net.WebClient
            $wc.Headers["Authorization"] = "Basic {0}" -f $base64AuthInfo
            $wc.Headers["Content-Type"] = "application/json";
            $wc.DownloadFile($uriGetFile, $OutFilePath)
            
        }
        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
                    
                    
            $ErrorMessage_3 = $_.Exception.Message
            write-host $ErrorMessage_3  -ForegroundColor Red
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
            $PSCmdlet.WriteError($_)
                


        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
        
    }
    
    end {
        
    }
}


#PAT
# $token = "d36lhpn4wyfrvswmqfms5dbawrizdh5uqgxrmbi5h3shajii5yfa"

#Azure AD MSAL Token
# $token = "Your Access Token"

# $uriGetFile = "https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?scopePath=/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip&download=true&api-version=6.1-preview.1"

# $OutfilePath = "C:\cci\scripts\Toolkit13.zip"

# Connect-AzDevOps -token $token -uriGetFile $uriGetFile -OutfilePath $OutfilePath