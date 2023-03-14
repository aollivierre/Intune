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

$ErrorActionPreference = "SilentlyContinue"
# Set ScripRoot variable to the path which the script is executed from
$RotatePATScriptRoot1 = $null
$RotatePATScriptRoot1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}


."$RotatePATScriptRoot1\0.1-Import-AppCert.ps1"


function Rotate-PAT {
    [CmdletBinding()]
    param (
    
        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        # [Parameter(Mandatory = $true,
        #     Position = 0,
        
        #     ValueFromPipelineByPropertyName = $true,
        #     HelpMessage = "Literal path to one or more locations.")]

        # [ValidateNotNullOrEmpty()]
        # [string[]]
        # $LiteralPath

    )
    
    begin {
        
    }
    
    process {

        try {

            Clear-MsalTokenCache
            $appID = '4d80ad41-b02b-4465-9e60-a83e24fcd64f'
            $certThumbprint = '165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d'
            $tenantID = 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

            # $kvScope = 'https://vault.azure.net/.default'
            # $AzDevopsScope = 'https://app.vssps.visualstudio.com/.default'
            $AzDevopsScope = '499b84ac-1321-427f-aa17-267ca6975798/.default'
            # $AzDevopsScope = 'https://app.vssps.visualstudio.com/user_impersonation'

            # Import client certificate
            # $clientCertificate = Import-AppCert -certThumbprint $certThumbprint

            ######################
            ##        MSAL      ##
            ######################
            Import-Module MSAL.PS
            # $msalToken = Get-MsalToken -Scope $AzDevopsScope -ClientId $appID -ClientCertificate $clientCertificate -TenantId $tenantID
            # $msalToken = Get-MsalToken -Scope $AzDevopsScope -ClientId $appID -ClientCertificate $clientCertificate -TenantId $tenantID
            $msalToken = Get-MsalToken -Scope $AzDevopsScope -ClientId $appID -TenantId $tenantID -Interactive -LoginHint "Admin-PowerShell@canadacomputing.ca"
            # $msalToken = Get-MsalToken -Silent -Scope $AzDevopsScope -ClientId $appID -TenantId $tenantID -LoginHint "Admin-PowerShell@canadacomputing.ca"
            # Get-MsalToken -Scope $AzDevopsScope -ClientId $appID -TenantId $tenantID -Interactive -LoginHint "Admin-PowerShell@canadacomputing.ca"
            # $msalToken = Get-MsalToken -ClientId $appID -TenantId $tenantID -Interactive
            # $msalToken = Get-MsalToken -Scope $AzDevopsScope -ClientId $appID -TenantId $tenantID -Interactive
            # $msalToken = Get-MsalToken -Scope $AzDevopsScope -Interactive
            # $msalToken = Get-MsalToken -Scope $AzDevopsScope -IntegratedWindowsAuth
            # $msalToken = Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId '00000000-0000-0000-0000-000000000000' -Interactive -Scope 'https://graph.microsoft.com/User.Read' -LoginHint user@domain.com
            Write-Output "[+] Got token using MSAL and client certificate: $($msalToken.AccessToken)"



            # $msalTokensilent = Get-MsalToken -Silent -Scope $AzDevopsScope -ClientId $appID -TenantId $tenantID -LoginHint "Admin-PowerShell@canadacomputing.ca"
            # $msalTokensilent.AccessToken
            

            # URL to keyvault
            # $kvURI = 'https://akv001-teamviewer.vault.azure.net'
            # $keyName = 'mytopcert'

            # The target audience for the token for Azure Keyvault is different than we'd normally use for MSGraph


            #####################################################
            ##        Get token for App-Proxy                   #
            #####################################################
            # $clientCert = Import-AppCert
            # $proxyAppToken = New-AccessToken -clientCertificate $clientCert -tenantID $tenantID -appID $proxyAppId -scope $kvScope 
            $proxyAppToken = ($msalToken).AccessToken

            #########################################################
            ##        Use App-Proxy token to enumerate key vault    #
            #########################################################
            # $AKVCertificate = Get-AKVCertificate -kvURI $kvURI -proxyAppToken $proxyAppToken -keyName $keyName


            # $AKVCertificate




            # $auth = "Bearer <Azure AD token>"
            $auth = "Bearer $proxyAppToken"
            $orgname = "CanadaComputingInc"

            $headers = @{
                'Authorization' = $auth
            }

            # Invoke-RestMethod -H $headers "https://vssps.dev.azure.com/$orgname/_apis/Tokens/Pats?api-version=6.1-preview"
            # Invoke-RestMethod -H $headers "https://vssps.dev.azure.com/$orgname/_apis/tokens/pats?api-version=7.1-preview.1"
            # Invoke-RestMethod -H $headers "https://vssps.dev.azure.com/$orgname/_apis/Tokens/Pats?api-version=6.1-preview" -UseBasicParsing


            # Invoke-RestMethod -H $headers -Method POST "https://vssps.dev.azure.com/$orgname/_apis/tokens/pats?api-version=7.1-preview.1"







            # $uri = "https://login.microsoftonline.com/$($tenantID)/oauth2/v2.0/token"
            # $uri = "https://vssps.dev.azure.com/$orgname/_apis/Tokens/Pats?api-version=6.1-preview"
            # $uri = "https://vssps.dev.azure.com/$orgname/_apis/tokens/pats?api-version=6.1-preview.1"
            $uri = "https://vssps.dev.azure.com/$orgname/_apis/tokens/pats?api-version=7.1-preview.1"
            $headers = @{
                
                'Content-Type'  = 'application/json' 
                'Authorization' = "Bearer $auth"
            
            }
            # $response = Invoke-RestMethod -Uri $uri -UseBasicParsing -Method POST -Headers $headers -Body ([ordered]@{
            #         # 'client_id'             = $appID
            #         # 'client_assertion'      = $signedJWT
            #         # 'client_assertion_type' = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
            #         # 'scope'                 = $scope
            #         # 'grant_type'            = 'client_credentials'

            #         'displayName' = '002_PAT_Created_VIA_API'
            #         'scope'       = 'vso.code'
            #         'validTo'     = '2022-09-30T23:46:23.319Z'
            #         'allOrgs'     = 'false'


            #     })
            
            # return $response






            
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


# Rotate-PAT