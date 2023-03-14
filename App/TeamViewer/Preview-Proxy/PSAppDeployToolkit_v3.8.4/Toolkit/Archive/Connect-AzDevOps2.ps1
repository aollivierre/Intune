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
    param( 
        # [Parameter(Mandatory = $true)] 
        # [string] $GitFilePath,
        # [Parameter(Mandatory = $true)] 
        # [string] $OutFilePath,
        # [Parameter(Mandatory = $true)] 
        # [string] $RepoName,
        # [string] $token,
        # [string] $orgUrl,
        # [string] $teamProject
    )
    
    begin {


        # https://dev.azure.com/
        # CanadaComputingInc/
        # edb7565a-620a-4960-89ae-96e7765b9202/
        # _apis/
        # git/
        # repositories/
        # 4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/
        # items?path=/
        # Preview/
        # Install-TeamViewer/
        # PSAppDeployToolkit_v3.8.4/
        # Toolkit.zip&
        # versionDescriptor%
        # 5BversionOptions%
        # 5D=0&
        # versionDescriptor%
        # 5BversionType%
        # 5D=0&
        # versionDescriptor%
        # 5Bversion%
        # 5D=master&
        # resolveLfs=true&%
        # 24format=octetStream&
        # api-version=5.0&download=true


        # https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?path=/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true



        # https://dev.azure.com/CanadaComputingInc/Canada%20Computing%20-%20Public%20Repos/_git/CCIPublicRepos

        # Repo Information
        # $organization = "CanadaComputingInc"
        # $orgUrl = "CanadaComputingInc"
        $orgUrl = "https://dev.azure.com/CanadaComputingInc"
        # $projectName = "Canada%20Computing%20-%20Public%20Repos"
        # $projectName = "Canada Computing -Public Repos"
        # $projectName = "edb7565a-620a-4960-89ae-96e7765b9202"
        $teamProject = "edb7565a-620a-4960-89ae-96e7765b9202"
        # $repoName = "CCIPublicRepos"
        $repoName = "4e3325c7-0dba-4f5c-9c3f-0e6b96208c22"
        $GitFilePath = "/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip"
        # $filePath = "/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip"
        $token = "d36lhpn4wyfrvswmqfms5dbawrizdh5uqgxrmbi5h3shajii5yfa"


        # Encode the Personal Access Token (PAT) to Base64 String
        # $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $token)))


        # Construct the download URL
        # $URL = $null
        # $url = "https://dev.azure.com/$organization/$projectName/_apis/git/repositories/$repoName/items?path=$filePath&download=true&api-version=5.0"
        # $url = "https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?path=/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"

        
    }
    
    process {

        try {


            $OutfilePath = $null
            $OutfilePath = "C:\cci\scripts\Toolkit6.zip"
            # $OutfilePath = "C:\cci\scripts\Toolkit.zip"

            # # Download the file
            # $result = $null
            # $result = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/text" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } | Out-File $OutfilePath
            # # $result = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/text" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }

         

            if ([String]::IsNullOrEmpty($token)) {
                if ($env:SYSTEM_ACCESSTOKEN -eq $null) {
                    Write-Error "you must either pass the -token parameter or use the BUILD_TOKEN environment variable"
                    exit 1;
                }
                else {
                    $token = $env:SYSTEM_ACCESSTOKEN;
                }
            }


            if ([string]::IsNullOrEmpty($teamProject)) {
                if ($env:SYSTEM_TEAMPROJECT -eq $null) {
                    Write-Error "you must either pass the -teampProject parameter or use the SYSTEM_TEAMPROJECT environment variable"
                    exit 1;
                }
                else {
                    $teamProject = $env:SYSTEM_TEAMPROJECT
                }
            }

            if ([string]::IsNullOrEmpty($orgUrl)) {
                if ($env:SYSTEM_COLLECTIONURI -eq $null) {
                    Write-Error "you must either pass the -orgUrl parameter or use the SYSTEM_COLLECTIONURI environment variable"
                    exit 1;
                }
                else {
                    $teamProject = $env:SYSTEM_COLLECTIONURI
                }
            }

            # Base64-encodes the Personal Access Token (PAT) appropriately  
            $User = 'Admin-PowerShell@canadacomputing.ca' 
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $token)));  
            $header = @{Authorization = ("Basic {0}" -f $base64AuthInfo) };  
            #---------------------------------------------------------------------- 

            Write-Host "Download file" $GitFilePath "to" $OutFilePath
     

            $uriGetFile = $null
            # $uriGetFile = "$orgUrl/$teamProject/_apis/git/repositories/$repoName/items?scopePath=$GitFilePath&download=true&api-version=6.1-preview.1"
            $uriGetFile = "$orgUrl/$teamProject/_apis/git/repositories/$repoName/items?scopePath=$GitFilePath&download=true&api-version=5.0"
            # $uriGetFile = "https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?path=/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    
            Write-Host "Url:" $uriGetFile
    
            $filecontent = Invoke-RestMethod -ContentType "application/json" -UseBasicParsing -Headers $header -Uri $uriGetFile
            $filecontent | Out-File -Encoding utf8 $OutFilePath
            # $filecontent | Out-File $OutFilePath


            
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

        # $result
        
    }
}



# $Token = $null
# $Token = "d36lhpn4wyfrvswmqfms5dbawrizdh5uqgxrmbi5h3shajii5yfa"

# $URL = $null
# $URL = 

# Connect-AzDevOps -URL $URL -Token $Token

Connect-AzDevOps
