# IntuneAppFileRetriever
# Function: 1/3 - Connect-To-GraphAPI
# Function's description:

# Utilizes Connect-MgGraph from the Microsoft.Graph PowerShell SDK for authentication.
# Automatically handles the token acquisition.
# Requires the appropriate scopes for interacting with Intune apps.
# Function's code:

function Connect-To-GraphAPI {
    param (
        [Parameter(Mandatory=$false)]
        [string[]]$Scopes = @("DeviceManagementApps.Read.All", "DeviceManagementApps.ReadWrite.All")
    )

    # Authenticate using Connect-MgGraph
    Connect-MgGraph -Scopes $Scopes
}
Connect-To-GraphAPI
