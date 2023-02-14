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



#! run the following in PowerShell 6+ or 7+ (does not work in PowerShell 5) as you will get the following error if you run it in PowerShell 5

# Exception calling "GetResult" with "0" argument(s): "Could not load file or assembly 'System.Text.Json, Version=5.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its 
# dependencies. The system cannot find the file specified."
# At C:\Program Files\WindowsPowerShell\Modules\SecretManagement.Keeper\16.3.3\SecretManagement.Keeper.psm1:37 char:7
# +       $result = [SecretManagement.Keeper.Client]::GetVaultConfigFromT ...
# +       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#     + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
#     + FullyQualifiedErrorId : FileNotFoundException


# Register-KeeperVault -Name Keeper -LocalVaultName LocalStore -OneTimeToken XXX
# Register-KeeperVault -Name "Keeper" -LocalVaultName "LocalStore" -OneTimeToken "US:kqxaLTgRW6kzOA4nPFYf-8CtkDBoh-WrdbDYfB-FBE0"
# Register-KeeperVault -Name "Keeper" -LocalVaultName "LocalStore" -OneTimeToken "US:1CUParyRzqNSuePKBThtiBA_u3xNys0rOo1VtYRhBLg"
Register-KeeperVault -Name "Keeper" -LocalVaultName "LocalStore" -OneTimeToken "US:YrrHH7RsiX9kVVkhLjvJR5qa3jq9tTGJdCQ73T6lYqc"


# Register-KeeperVault: {"path":"https://keepersecurity.com/api/rest/sm/v1/get_secret, POST, null","additional_info":"","location":"default exception manager - api validation exception","error":"access_denied","message":"Signature is invalid"}