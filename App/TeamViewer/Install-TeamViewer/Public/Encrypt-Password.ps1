
# Set ScripRoot variable to the path which the script is executed from
$ScriptRoot3 = $null
$ScriptRoot3 = if ($PSVersionTable.PSVersion.Major -lt 3) {
    Split-Path -Path $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}


function Encrypt-Password {
    [CmdletBinding()]
    param (
        
    )
    
    begin {

        <#
        The following script is used to generate an ecrypted password

        It will generate a Password.txt 

        Secure Password with PowerShell: Encrypting Credentials
        https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-1/
        https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-2/

        #>



        #Creating AES key with random data and export to file
        $Key_File_1 = "$ScriptRoot3\AES.key"
        $Key_1 = New-Object Byte[] 32   # You can use 16, 24, or 32 for AES
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key_1)
        $Key_1 | out-file $Key_File_1

        #Creating SecureString object
        $Password_File_1 = "$ScriptRoot3\password.txt"
        $Key_File_1 = "$ScriptRoot3\AES.key"
        $Key_1 = Get-Content $Key_File_1
        # $Password = "Whatever your password is" | ConvertTo-SecureString -AsPlainText -Force

        
    }
    
    process {

        try {
            
            Read-Host "Enter a Password to be Encrypted as a key file" -AsSecureString | ConvertFrom-SecureString -key $Key_1 | Out-File $Password_File_1
            
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
        
    }
}

# Encrypt-Password
