
# Set ScripRoot variable to the path which the script is executed from
$EncryptSecretScriptRoot = $null
$EncryptSecretScriptRoot = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}



Push-Location $EncryptSecretScriptRoot -stackname 'encryptsecretstack'

 

function Encrypt-Secret {
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SecretValue,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description

    )
    
    begin {

        <#
        The following script is used to generate an ecrypted Secret

        It will generate a Secret.txt 

        Secure Secret with PowerShell: Encrypting Credentials
        https://www.pdq.com/blog/secure-Secret-with-powershell-encrypting-credentials-part-1/
        https://www.pdq.com/blog/secure-Secret-with-powershell-encrypting-credentials-part-2/

        #>




        #Creating AES key with random data and export to file
        $Key_File_1 = "$EncryptSecretScriptRoot\$($Description)_AES.key"
        $Key_1 = New-Object Byte[] 32   # You can use 16, 24, or 32 for AES
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key_1)
        $Key_1 | out-file $Key_File_1

        #Creating SecureString object
        $Secret_File_1 = "$EncryptSecretScriptRoot\$($Description)_Secret.txt"
        $Key_File_1 = "$EncryptSecretScriptRoot\$($Description)_AES.key"
        $Key_1 = Get-Content $Key_File_1
        # $Secret = "Whatever your Secret is" | ConvertTo-SecureString -AsPlainText -Force

        
    }
    
    process {

        try {
            
        #    $SecretValue = Read-Host "Enter a Secret to be Encrypted as a key file" -AsSecureString | ConvertFrom-SecureString -key $Key_1 | Out-File $Secret_File_1

       $Secret_Secure = $SecretValue | ConvertTo-SecureString -AsPlainText -Force
       
       $Secret_Secure |  ConvertFrom-SecureString -key $Key_1 | Out-File $Secret_File_1
   
            
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
            
        }
        
    }
    
    end {
        Pop-Location -StackName 'encryptsecretstack'
    }
}

# Encrypt-Secret -SecretValue "{fs@E5j)IsNI[L9n)UJnkGIqB>eXsyiHBJuJAM5^BFSl@i0yy@Kt;k<DlYsz8R@S" -Description 'SecretStoreCred'
Encrypt-Secret -SecretValue "welcome123" -Description 'SecretStoreCred'
# Encrypt-Secret -SecretValue "mytopsecretinplaintext" -Description 'mytopsecret'