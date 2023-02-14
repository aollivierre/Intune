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
    $organization = "CanadaComputingInc"
    # $projectName = "Canada%20Computing%20-%20Public%20Repos"
    # $projectName = "Canada Computing -Public Repos"
    $projectName = "edb7565a-620a-4960-89ae-96e7765b9202"
    # $repoName = "CCIPublicRepos"
    $repoName = "4e3325c7-0dba-4f5c-9c3f-0e6b96208c22"
    $filePath = "/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip"
    $token = "d36lhpn4wyfrvswmqfms5dbawrizdh5uqgxrmbi5h3shajii5yfa"


    # Encode the Personal Access Token (PAT) to Base64 String
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $token)))


    # Construct the download URL
    $URL = $null
    $url = "https://dev.azure.com/$organization/$projectName/_apis/git/repositories/$repoName/items?path=$filePath&download=true&api-version=5.0"
    # $url = "https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?path=/Preview/Install-TeamViewer/PSAppDeployToolkit_v3.8.4/Toolkit.zip&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
        
    }
    
    process {


        try {

            $OutfilePath = $null
            # $OutfilePath = "C:\cci\scripts\Toolkit.zip"
            $OutfilePath = "C:\cci\scripts\Toolkit1.zip"
    
            # Download the file
            $result = $null
            $result = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/text" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } | Out-File $OutfilePath
            # $result = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/text" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
            
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
        
    }
    
    end {
        
    }
}



# $Token = $null
# $Token = "d36lhpn4wyfrvswmqfms5dbawrizdh5uqgxrmbi5h3shajii5yfa"

# $URL = $null
# $URL = 

# Connect-AzDevOps -URL $URL -Token $Token

# Connect-AzDevOps