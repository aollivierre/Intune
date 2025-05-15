# Encryption and decryption functions for credentials management

function Protect-String {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$String
    )
    
    $secureString = ConvertTo-SecureString -String $String -AsPlainText -Force
    $encrypted = $secureString | ConvertFrom-SecureString -Key (1..16)
    return $encrypted
}

function Unprotect-String {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$EncryptedString
    )
    
    try {
        $secureString = ConvertTo-SecureString -String $EncryptedString -Key (1..16)
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    finally {
        if ($BSTR) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
}

function Get-SecureInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )
    
    $secureString = Read-Host -Prompt $Prompt -AsSecureString
    return $secureString
}

# Export functions to make them available within the module
Export-ModuleMember -Function Protect-String, Unprotect-String, Get-SecureInput
