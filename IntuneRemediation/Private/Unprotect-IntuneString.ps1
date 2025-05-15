function Unprotect-IntuneString {
    <#
    .SYNOPSIS
        Decrypts a string that was encrypted using Protect-IntuneString.
        
    .DESCRIPTION
        This function decrypts a string that was previously encrypted using 
        Protect-IntuneString. It uses the same fixed key for decryption.
        
    .PARAMETER EncryptedString
        The encrypted string to decrypt.
        
    .EXAMPLE
        Unprotect-IntuneString -EncryptedString "01000000d08c9ddf0115d1118c7a00c04fc297eb01000000..."
        
    .NOTES
        This function uses a fixed encryption key and should only be used for local storage.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$EncryptedString
    )
    
    try {
        # Create the same fixed encryption key used for encryption
        $baseKey = [byte[]]@(35, 64, 87, 22, 65, 43, 21, 65, 89, 45, 11, 65, 45, 65, 88, 34,
                             12, 56, 78, 10, 36, 90, 87, 65, 13, 44, 13, 15, 76, 25, 39, 45)
        
        # Decrypt the string
        $secureString = ConvertTo-SecureString -String $EncryptedString -Key $baseKey
        
        # Convert SecureString back to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        return $decrypted
    }
    catch {
        Write-Error "Failed to decrypt string: $_"
        return $null
    }
    finally {
        # Clean up the unmanaged memory
        if ($BSTR) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
} 