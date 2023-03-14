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
# $token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IjJaUXBKM1VwYmpBWVhZR2FYRUpsOGxWMFRPSSIsImtpZCI6IjJaUXBKM1VwYmpBWVhZR2FYRUpsOGxWMFRPSSJ9.eyJhdWQiOiI0OTliODRhYy0xMzIxLTQyN2YtYWExNy0yNjdjYTY5NzU3OTgiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9kYzMyMjdhNC01M2JhLTQ4ZjEtYjU0Yi04OTkzNmNkNWNhNTMvIiwiaWF0IjoxNjYxNjU1NTg5LCJuYmYiOjE2NjE2NTU1ODksImV4cCI6MTY2MTY1OTc4NywiYWNyIjoiMSIsImFpbyI6IkFWUUFxLzhUQUFBQVJvZk1NSHFZbmY5aW5WTjZwZ3BWZUoveVcvdGdTRFpxOVRVMzZab2Q2SDU3bjFkWm50N1g2VVphaWcveVZYSDUrTFpVaXpydGN5MG4rK2V0NjlaRVhOeFp3U3JtTHk1NDJURFYwSmlGRWUwPSIsImFtciI6WyJwd2QiLCJtZmEiXSwiYXBwaWQiOiI0ZDgwYWQ0MS1iMDJiLTQ0NjUtOWU2MC1hODNlMjRmY2Q2NGYiLCJhcHBpZGFjciI6IjAiLCJnaXZlbl9uYW1lIjoiQWRtaW4tUG93ZXJTaGVsbCIsImlwYWRkciI6IjIwOC44MS40Ljk4IiwibmFtZSI6IkFkbWluLVBvd2VyU2hlbGwiLCJvaWQiOiJjNzQwYjI4NC1mYzBhLTQ2MWEtODEwNC1kNGZlYjg1MGI1YWQiLCJwdWlkIjoiMTAwMzIwMDIyMkI1M0Q2NCIsInJoIjoiMC5BUmNBcENjeTNMcFQ4VWkxUzRtVGJOWEtVNnlFbTBraEUzOUNxaGNtZkthWFY1Z1hBTXMuIiwic2NwIjoidXNlcl9pbXBlcnNvbmF0aW9uIiwic3ViIjoiVTcyd0Vxb3hDUGVobGRMLVR4T0RSOS1hRXd5SmJic1k1NWhJZ0pwVzFnRSIsInRpZCI6ImRjMzIyN2E0LTUzYmEtNDhmMS1iNTRiLTg5OTM2Y2Q1Y2E1MyIsInVuaXF1ZV9uYW1lIjoiQWRtaW4tUG93ZXJTaGVsbEBjYW5hZGFjb21wdXRpbmcuY2EiLCJ1cG4iOiJBZG1pbi1Qb3dlclNoZWxsQGNhbmFkYWNvbXB1dGluZy5jYSIsInV0aSI6IlRrMXliMGxlZmtlb3VGMHZRb1VrQUEiLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdfQ.oDctOtiNmkAW0Hi506nI0zuf_FM14CmflobHAACMBJEffsqrX2x2qn6gKZwaPhzvZTluX1n6MjUcQokKVtn3pb1RzggUjWQNq3jeVaD7ntPkEpVi4M_UpnNh30oFc1-b1HSS1ZnlVRshah_DnX-20Vf76hkb3sSvV7jTrwLo9LNYTizfXttUUgB7y6XZCBvToPYgdw9hh1wHQgK-iDOCC3hKb8v8ASO1tJ5t_uAIlMYHkyMV_Jk5a2UThmsazT8hKmf2F6o5cMlZO84G2dlsuIbR9UDSyhfRPxrvOgTgkOMTjeAH7wSDKyXraTDP4o-msuksO-0OYD-h7hKFj4qqwA"

# $uriGetFile = "https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?scopePath=/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip&download=true&api-version=6.1-preview.1"

# $OutfilePath = "C:\cci\scripts\Toolkit13.zip"

# Connect-AzDevOps -token $token -uriGetFile $uriGetFile -OutfilePath $OutfilePath