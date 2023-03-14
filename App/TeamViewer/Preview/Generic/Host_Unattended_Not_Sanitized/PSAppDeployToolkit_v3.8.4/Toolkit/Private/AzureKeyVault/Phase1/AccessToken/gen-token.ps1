function gen-token {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        
    }
    
    process {



        try {


            $ClientCertificate = Get-Item Cert:\CurrentUser\My\165bf610fcb4e7bcfe6dcfee33a000eddd2cb03d
            
            $MsalClientApplication = Get-MsalClientApplication -ClientId '4d80ad41-b02b-4465-9e60-a83e24fcd64f' -ClientCertificate $ClientCertificate -TenantId 'dc3227a4-53ba-48f1-b54b-89936cd5ca53'

            
            $AccessToken_001 = $null
            $AccessToken_001 = ($MsalClientApplication | Get-MsalToken -Scope 'https://graph.microsoft.com/.default').AccessToken
            $AccessToken_001 | clip.exe
            $AccessToken_001
                
        }
        catch [Exception] {
                    
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
                
                
            $ErrorMessage_4 = $_.Exception.Message
            write-host $ErrorMessage_4  -ForegroundColor Red
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

        $AccessToken_001
        
    }
}


gen-token