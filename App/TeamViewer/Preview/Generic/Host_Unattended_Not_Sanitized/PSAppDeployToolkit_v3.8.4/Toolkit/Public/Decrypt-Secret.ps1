$DecryptSecretScriptRoot = $null
$DecryptSecretScriptRoot = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}


function Decrypt-Secret {
    [CmdletBinding()]
  
    param (
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description
    )

    
    begin {
        Push-Location $DecryptSecretScriptRoot -stackname 'DecryptSecretstack'
    }
    
    process {


        try {
        
            $DecryptSecretfiledescription = "$($Description)_Secret.txt"
            $DecryptSecretKeyfiledescription = "$($Description)_AES.key"
        
        
            $DecryptSecretfilepath = Get-ChildItem -Recurse -Filter $DecryptSecretfiledescription
            $DecryptSecretkeyfilepath = Get-ChildItem -Recurse -Filter $DecryptSecretKeyfiledescription


            # $InstallTeamViewerSecretStoreCredentialsPath = $null
            # $InstallTeamViewerSecretStoreCredentialsPath = @( Get-ChildItem -Path $Private\secrets\*.Key -Recurse -ErrorAction SilentlyContinue )


            # $InstallTeamViewerSecretStoreCredentialsPath = $null
            # $InstallTeamViewerSecretStoreCredentialsPath = @( Get-ChildItem -Path $Private\secrets\*.txt -Recurse -ErrorAction SilentlyContinue )
        
        
            # $DBG
        
        
            if ($DecryptSecretfilepath) {
        
                if ((Test-Path $DecryptSecretfilepath) -and ($DecryptSecretfilepath.count -eq '1')) {
                    Write-host 'found only' $DecryptSecretfilepath.count 'number of setting files'
                    Write-host ' settings file found in' $DecryptSecretfilepath.FullName
                }
            
                elseif ((Test-Path $DecryptSecretfilepath) -and ($DecryptSecretfilepath.count -gt '1')) {
                
                    Write-host 'found only' $DecryptSecretfilepath.count 'number of setting files'
                    Write-host ' settings file found in' $DecryptSecretfilepath.FullName
                    Throw 'Ensure ONLY 1 setting file is there'
                }
            
           
        
            
            }
        
            else
            #
        
            { Throw ' Secret file not found for DecryptSecretfilepath' }
        
        
        
        
            if ($DecryptSecretkeyfilepath) {
        
                if ((Test-Path $DecryptSecretkeyfilepath) -and ($DecryptSecretkeyfilepath.count -eq '1')) {
                    Write-host 'found only' $DecryptSecretkeyfilepath.count 'number of setting files'
                    Write-host ' settings file found in' $DecryptSecretkeyfilepath.FullName
                }
                
                elseif ((Test-Path $DecryptSecretkeyfilepath) -and ($DecryptSecretkeyfilepath.count -gt '1')) {
                    
                    Write-host 'found only' $DecryptSecretkeyfilepath.count 'number of setting files'
                    Write-host ' settings file found in' $DecryptSecretkeyfilepath.FullName
                    Throw 'Ensure ONLY 1 setting file is there'
                }
                
               
            
                
            }
            
            else
            #
            
            { Throw 'Secret file not found for DecryptSecretkeyfilepath' }
        
        
        
            # $DecryptSecretfilepath = "$DecryptSecretScriptRoot\$($Description)_Secret.txt"
            $DecryptSecretfilepath = $DecryptSecretfilepath.FullName
            # $DecryptSecretkeyfilepath = "$DecryptSecretScriptRoot\$($Description)_AES.key"
            $DecryptSecretkeyfilepath = $DecryptSecretkeyfilepath.FullName
        
            #Create the Encryption Keys parameters
            # $DecryptSecretfilepath = $null
            # $DecryptSecretkeyfilepath = $null
            $Key_2 = $null
            $MyCredential_2 = $null
        
            $User_2 = $null
            # $User_2 = "websiteSMTP@canadacomputing.ca"
            # $User_2 = "alerts@canadacomputing.ca"
            $User_2 = "CCI Admin"
        
        
        
        
        
            $Key_2 = Get-Content $DecryptSecretkeyfilepath
        
            if ($Key_2) {
        
        
                $SecurePWD_2 = $null
                $SecurePWD_2 = (Get-Content $DecryptSecretfilepath | ConvertTo-SecureString -Key $Key_2)
        
                if ($SecurePWD_2) {
        
                    
                $MyCredential_2 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User_2, $SecurePWD_2
        
                # $Secret_OBJECT_2 = $null
                # $Secret_OBJECT_2 = $MyCredential_2.GetNetworkCredential().Password
        
                # $smtp_2.Credentials = New-Object System.Net.NetworkCredential($MyCredential_2.UserName, $Secret_OBJECT_2)
        
               
                
                }
        
            
            }
        

            
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

        Pop-Location -StackName 'DecryptSecretstack'


        return $MyCredential_2
        
    }
}


# Decrypt-Secret




# $ClientID = Decrypt-Secret -Description 'ClientID'
# $DirectoryID = Decrypt-Secret -Description 'DirectoryID'
# $ClientSecret = Decrypt-Secret -Description 'ClientSecret'


# $ClientID
# $DirectoryID
# $ClientSecret


# $ClientSecret = Decrypt-Secret -Description 'SecretStoreCred'
# $ClientSecret

