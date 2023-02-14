# will continue here


# if PAT is VALID use it to access azure dev ops

# if PAT is NOT VALID then trigger Get-MsalToken and Interactively get the user to login and this will give you an AAD Access token

# then generate a new PAT then update the Azure Key vault with the new PAT




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



#First option we will use the REST API method to check if the PAT is VALID using the validTo tag in the JSON response however, to access the PAT API we need an MSAL Access token from Azure AD scoped to Azure DEV OPS. What we really want is to check if the PAT is VALID without having to prompt the user to interactively authenticate in order to request an MSAL access token


$auth = "Bearer $proxyAppToken"
$orgname = "CanadaComputingInc"

$headers = @{
    'Authorization' = $auth
}

$uri = "https://vssps.dev.azure.com/$orgname/_apis/tokens/pats?api-version=7.1-preview.1"

$headers = @{
    
    'Content-Type'  = 'application/json' 
    'Authorization' = "Bearer $auth"

}
$response = Invoke-RestMethod -Uri $uri -UseBasicParsing -Method POST -Headers $headers -Body ([ordered]@{
        'displayName' = '002_PAT_Created_VIA_API'
        'scope'       = 'vso.code'
        'validTo'     = '2022-09-30T23:46:23.319Z'
        'allOrgs'     = 'false'


    })

return $response



#second option is to check if the PAT is VALID without having to generate an MSAL access token. To do this we will try any operation with that PAT and check if the response matches what we expect. 

# IF the response is 200 for example then the PAT is valid and no need to trigger the user interactively to generate a new MSAL token to get a new PAT and save the NEW PAT in the Az Key Vault.

# IF the response is not 200 for example then the PAT is NOT valid and we will trigger the user interactively to generate a new MSAL token to get a new PAT and save the NEW PAT in the Az Key vault


if ($response -eq '200') {
    <# Action to perform if the condition is true #>

    # IF the response is 200 for example then the PAT is valid and no need to trigger the user interactively to generate a new MSAL token to get a new PAT and save the NEW PAT in the Az Key Vault.

    $VALID_PAT = Get-AzKeyVaultSecret -VaultName $VaultName -Name $VALID_PAT_SecretName
    Connect-AzDevops -PAT $VALID_PAT

}


if ($response -ne '200') {
    <# Action to perform if the condition is true #>

  # IF the response is not 200 for example then the PAT is NOT valid and we will trigger the user interactively to generate a new MSAL token to get a new PAT and save the NEW PAT in the Az Key vault

  $New_MSAL_Token = Get-MsalToken
  $NEW_PAT_Token = Get-AzDevOpsPAT -MSALToken $New_MSAL_Token

  $NEW_PAT_Token_Secure = ConvertFrom-SecureString $NEW_PAT_Token 
  Set-AzKeyVaultSecret -VaultName $VaultName -SecretValue $NEW_PAT_Token_Secure

  Connect-AzDevops -PAT $NEW_PAT_Token



}




