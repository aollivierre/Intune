# IntuneAppFileRetriever
# Function: 1/3 - Authenticate-GraphAPI
# Function's description:

# Authenticates with Microsoft Graph API.
# Requires user credentials or a client secret.
# Returns an access token to be used for subsequent Graph API calls.
# Function's code:


function Authenticate-GraphAPI {
    param (
        [Parameter(Mandatory=$true)]
        [string]$clientID,

        [Parameter(Mandatory=$true)]
        [string]$clientSecret,

        [Parameter(Mandatory=$true)]
        [string]$tenantID,

        [string]$resourceURL = "https://graph.microsoft.com"
    )

    $tokenURL = "https://login.microsoftonline.com/$tenantID/oauth2/token"

    $tokenBody = @{
        client_id     = $clientID
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type    = "client_credentials"
        resource      = $resourceURL
    }

    $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenURL -Body $tokenBody
    return $tokenResponse.access_token
}
