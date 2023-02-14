function Get-AzKeyVaultSecretREST {
    [CmdletBinding()]
    param (
    
    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
    # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
    # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
    # characters as escape sequences.
    [Parameter(Mandatory=$true,
               Position=0,
               ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $VaultName,

    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
    # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
    # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
    # characters as escape sequences.
    [Parameter(Mandatory=$true,
               Position=0,
               ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $SecretName
        
    )
    
    begin {

        $VaultName = $null
        $SecretName = $null
        $httpResponse = $null
        
    }
    
    process {

        try {
            

       

            $httpResponse = Invoke-WebRequest -Uri "https://$VaultName.vault.azure.net/secrets/$SecretName/?api-version=7.3" -Headers @{ 'Authorization' = "Bearer $($proxyAppToken)" } -UseBasicParsing:$true

            $httpresponsecontent = $httpResponse.Content | ConvertFrom-Json
            $httpresponsevalue = ($httpresponsecontent).value
            


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
        
    }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
        
    }
    
    end {


        return $httpresponsevalue
        
    }
}


$secret1 = Get-AzKeyVaultSecretREST -VaultName "AKV001-TeamViewer" -Name "001-TeamViewerTeamsWebhook"
$secret2 = Get-AzKeyVaultSecretREST -VaultName "AKV001-TeamViewer" -Name "002-TeamViewerAPITOKEN"
$secret3 = Get-AzKeyVaultSecretREST -VaultName "AKV001-TeamViewer" -Name "003-TeamViewerCUSTOMCONFIGID"
$secret4 = Get-AzKeyVaultSecretREST -VaultName "AKV001-TeamViewer" -Name "004-TeamViewerSettings"

# $secret1
# $secret2
# $secret3
# $secret4


# $ResponseContent = ($httpResponse.Content).value
# return $ResponseContent | ConvertFrom-Json