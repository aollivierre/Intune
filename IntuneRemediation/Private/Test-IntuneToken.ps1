function Test-IntuneToken {
    <#
    .SYNOPSIS
        Tests if a token is valid and not expired for Intune management.
        
    .DESCRIPTION
        This function validates an authentication token for Intune management.
        It checks the token format, expiration, and makes a test request to the Intune API.
        
    .PARAMETER Token
        The authentication token to test.
        
    .EXAMPLE
        Test-IntuneToken -Token $token
        
    .NOTES
        This is a private function used by public functions in the module.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token
    )
    
    # Check if token is empty or null
    if ([string]::IsNullOrEmpty($Token)) {
        Write-Error "Token is empty or null."
        return $false
    }
    
    # Check if token is in correct format (should start with eyJ)
    if (-not $Token.StartsWith("eyJ")) {
        Write-Error "Token is not in the correct format. It should start with 'eyJ'."
        return $false
    }
    
    try {
        # Decode the token to check expiration
        $tokenPayload = $Token.Split(".")[1]
        # Add padding to avoid "Invalid length for a Base-64 char array" error
        while ($tokenPayload.Length % 4) { $tokenPayload += "=" }
        $tokenBytes = [System.Convert]::FromBase64String($tokenPayload)
        $tokenJson = [System.Text.Encoding]::UTF8.GetString($tokenBytes)
        $tokenData = ConvertFrom-Json -InputObject $tokenJson
        
        # Get the expiration time
        $epochTime = $tokenData.exp
        $expirationTime = [System.DateTimeOffset]::FromUnixTimeSeconds($epochTime).DateTime.ToLocalTime()
        
        # Check if token is expired
        $currentTime = Get-Date
        if ($expirationTime -lt $currentTime) {
            Write-Error "Token has expired on $($expirationTime.ToString('yyyy-MM-dd HH:mm:ss')). Current time is $($currentTime.ToString('yyyy-MM-dd HH:mm:ss'))."
            return $false
        }
        
        # Make a test request to the Graph API to verify token works
        try {
            $headers = @{
                "Authorization" = "Bearer $Token"
                "Content-Type" = "application/json"
            }
            
            # Test request to a lightweight Graph API endpoint
            $testUrl = "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?`$top=1"
            $response = Invoke-RestMethod -Uri $testUrl -Headers $headers -Method Get -ErrorAction Stop
            
            # If we get here, the API call was successful
            Write-Verbose "Token validated successfully with Microsoft Graph API."
            return $true
        }
        catch {
            # API call failed - token might be invalid despite passing expiration check
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMessage = $_.Exception.Message
            
            Write-Error "Token validation against Microsoft Graph API failed. Status code: $statusCode. Error: $errorMessage"
            return $false
        }
    }
    catch {
        Write-Error "Failed to parse or validate the token: $_"
        return $false
    }
    finally {
        # Clean up memory to avoid leaving sensitive information
        if ($tokenBytes) { [System.GC]::Collect() }
        if ($tokenJson) { [System.GC]::Collect() }
        if ($tokenData) { [System.GC]::Collect() }
    }
} 