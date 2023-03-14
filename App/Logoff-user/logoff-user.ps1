# $scriptBlock = {
    $ErrorActionPreference = 'Stop'

    try {
        ## Find all sessions matching the specified username
        $sessions = quser | Where-Object {$_ -match 'dattormm02user'}
        ## Parse the session IDs from the output
        $sessionIds = ($sessions -split ' +')[2]
        Write-Host "Found $(@($sessionIds).Count) user login(s) on computer."
        ## Loop through each session ID and pass each to the logoff command
        $sessionIds | ForEach-Object {
            Write-Host "Logging off session id [$($_)]..."
            logoff $_
        }
    } catch {
        if ($_.Exception.Message -match 'No user exists') {
            Write-Host "The user is not logged in."
        } else {
            throw $_.Exception.Message
        }
    }
# }

## Run the scriptblock's code on the remote computer
# PS> Invoke-Command -ComputerName REMOTECOMPUTER -ScriptBlock $scriptBlock

# Found 1 user login(s) on computer.
# Logging off session id [rdp-tcp#10]...