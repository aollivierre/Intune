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


$Import_TeamViewerSecretStoreScriptRoot_1 = $null
$Import_TeamViewerSecretStoreScriptRoot_1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}



."$Import_TeamViewerSecretStoreScriptRoot_1\Decrypt-Secret.ps1"



function Import-TeamViewerSecretStore {
    [CmdletBinding()]
    param (
        # [Parameter(Mandatory = $true)]
        # [ValidateNotNullOrEmpty()]
        # [SecureString] $TeamViewerSecretStoreCred


        # [Parameter(Mandatory = $true)]
        # [ValidateNotNullOrEmpty()]
        # $TeamViewerSecretStorePath

        
    )
        
    begin {
        

    

    }
        
    process {


        try {


            # $pass = Import-CliXml 'C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Private\Secrets\SecretStore.vault.credential'
            # $pass = Import-CliXml "$TeamViewerSecretStorePath"
            # $UnlockSecretStorepass = Decrypt-Secret -Description 'SecretStoreCred'
 

            # $TeamViewerSecretStoreCred



            # $pass = Read-Host -AsSecureString -Prompt 'Enter the extension vault password'

            # $Secure2 = ConvertTo-SecureString -String $TeamViewerSecretStoreCred

            # $pass = $null
            # $pass = $TeamViewerSecretStoreCred


            # $passwordPath = $null
            # $passwordPath = Join-Path (Split-Path $profile) SecretStore.vault.credential

            # $Credential = Get-Credential
            # $Credential | Export-Clixml -Path $passwordPath
            # Get-Content $passwordPath

          
            # Uses the DPAPI to encrypt the password
            # $pass | Export-CliXml -Path $passwordPath
 
            # $pass = Import-CliXml $passwordPath

            # Unlock-SecretStore -Password $pass



            # $passwordPath = $null
            # $passwordPath = Join-Path (Split-Path $profile) SecretStore.vault.credential

            # $passwordPath = 'C:\code\TeamViewer\Preview\PSAppDeployToolkit_v3.8.4\Toolkit\Private\Secrets\SecretStore.vault.credential'

            # $TeamViewerSecretStorePath_1 = @( Get-ChildItem -Path $Private\secrets\*.credential -Recurse -ErrorAction SilentlyContinue )

            # $Credentials = Import-CliXml -Path ./cred_vault.xml
            # $Credentials = Import-CliXml -Path $TeamViewerSecretStorePath
            # Unlock-SecretStore -Password (ConvertTo-SecureString -String $Credentials.Password -AsPlainText -Force)


            $ClientSecret = Decrypt-Secret -Description 'SecretStoreCred'

            # $pass = (ConvertTo-SecureString -String $Credentials.Password -AsPlainText -Force)
            # $pass = (ConvertTo-SecureString -String $pass1.Password -AsPlainText -Force)

            # Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout (60 * 60) -Interaction None -Password $pass -Confirm:$false
 
            # Register-SecretVault -Name "CCISecretStore" -ModuleName "Microsoft.PowerShell.SecretStore" -DefaultVault


            # $Credentials = $ClientSecret
            # $Credentials 


            $pass = (ConvertTo-SecureString -String $ClientSecret.Password -AsPlainText -Force)

            Unlock-SecretStore -Password $pass


        }
           
        <#Do this if a terminating exception happens#>


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
            
    }
}


# $TeamViewerSecretStoreCred = $null
# $TeamViewerSecretStoreCred = Decrypt-Secret -Description 'SecretStoreCred'
# Import-TeamViewerSecretStore -TeamViewerSecretStoreCred "$TeamViewerSecretStoreCred"

# Import-TeamViewerSecretStore