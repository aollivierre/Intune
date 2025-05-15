function Protect-IntuneString {
    <#
    .SYNOPSIS
        Encrypts a string using a portable encryption method.
        
    .DESCRIPTION
        This function encrypts a string using a fixed key to create a portable, encrypted string
        that can be stored in a file and decrypted later.
        
    .PARAMETER String
        The plain text string to encrypt.
        
    .EXAMPLE
        Protect-IntuneString -String "myToken123"
        
    .NOTES
        This is used for local token storage only and provides obfuscation, not high security.
        The encryption is portable across machines using the same version of PowerShell.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$String
    )
    
    try {
        # Create a fixed encryption key (32 bytes) based on module GUID
        # This provides consistent encryption/decryption across sessions
        $baseKey = [byte[]]@(35, 64, 87, 22, 65, 43, 21, 65, 89, 45, 11, 65, 45, 65, 88, 34,
                             12, 56, 78, 10, 36, 90, 87, 65, 13, 44, 13, 15, 76, 25, 39, 45)
        
        # Convert string to secure string and encrypt
        $secureString = ConvertTo-SecureString -String $String -AsPlainText -Force
        $encrypted = $secureString | ConvertFrom-SecureString -Key $baseKey
        
        return $encrypted
    }
    catch {
        Write-Error "Failed to encrypt string: $_"
        return $null
    }
} 