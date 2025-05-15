function Show-IntuneAssignedRoles {
    <#
    .SYNOPSIS
        Shows the current user's assigned Entra ID roles directly from Microsoft Graph.
        
    .DESCRIPTION
        This function queries Microsoft Graph to display the current user's assigned
        directory roles. This provides a more accurate view that matches what's shown
        in the Entra portal, instead of relying on the token's role claims.
        
    .PARAMETER UserId
        The user ID or UPN to check roles for. Defaults to the current user.
        
    .PARAMETER FallbackToToken
        If specified and Graph API lookup fails, will use the role information from the token
        instead of failing completely.
        
    .EXAMPLE
        Show-IntuneAssignedRoles
        
        Shows the current user's assigned roles.
        
    .EXAMPLE
        Show-IntuneAssignedRoles -UserId "john.doe@contoso.com"
        
        Shows the assigned roles for the specified user.
        
    .EXAMPLE
        Show-IntuneAssignedRoles -FallbackToToken
        
        Shows the current user's assigned roles, falling back to token information if Graph API fails.
        
    .NOTES
        Requires a connection to Microsoft Graph with appropriate permissions.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$UserId,
        
        [Parameter(Mandatory = $false)]
        [switch]$FallbackToToken = $true
    )
    
    try {
        # Verify Graph connection
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
            Write-Error "Not connected to Microsoft Graph. Please connect first with Connect-MgGraph."
            return
        }
        
        # If no user ID provided, get the current user
        if (-not $UserId) {
            try {
                $currentUser = Get-MgContext
                if ($currentUser -and $currentUser.Account) {
                    $UserId = $currentUser.Account
                    Write-Verbose "Using current user: $UserId"
                }
                else {
                    Write-Error "Could not determine current user. Please specify a UserId."
                    return
                }
            }
            catch {
                Write-Error "Error getting current user: $_"
                return
            }
        }
        
        Write-Host "Retrieving assigned roles for user: $UserId" -ForegroundColor Cyan
        
        # Get the user object
        $user = $null
        $errorDetails = $null
        
        try {
            # Try to get by UPN/email first
            $user = Get-MgUser -UserId $UserId -ErrorAction SilentlyContinue
            if (-not $user) {
                # Try filtering users if direct lookup fails
                Write-Verbose "Direct user lookup failed, trying filter query"
                $users = Get-MgUser -Filter "userPrincipalName eq '$UserId' or mail eq '$UserId'" -ErrorAction SilentlyContinue
                if ($users -and $users.Count -gt 0) {
                    $user = $users[0]
                }
            }
        }
        catch {
            $errorDetails = $_
            Write-Warning "Error finding user by direct ID: $($_.Exception.Message)"
            Write-Verbose "Full error: $_"
            
            try {
                Write-Warning "Attempting to search by display name or email..."
                $users = Get-MgUser -Filter "userPrincipalName eq '$UserId' or mail eq '$UserId' or displayName eq '$UserId'" -ErrorAction SilentlyContinue
                if ($users -and $users.Count -gt 0) {
                    $user = $users[0]
                }
            }
            catch {
                $errorDetails = $_
                Write-Warning "Search also failed: $($_.Exception.Message)"
                Write-Verbose "Full error: $_"
            }
        }
        
        if (-not $user) {
            # If fallback is enabled and we have a Graph connection with token info
            if ($FallbackToToken) {
                Write-Warning "User not found in Graph directory. Falling back to token role information."
                Write-Host "This may not show group-assigned roles. Check permissions or manually specify user ID." -ForegroundColor Yellow
                
                # Display token roles if we can access them
                try {
                    $context = Get-MgContext
                    if ($context -and $context.Account -eq $UserId) {
                        Write-Host "`nToken-based role information for: $UserId" -ForegroundColor Cyan
                        
                        # Get roles from the token by invoking our connection function
                        # This is a hacky way to get the token roles, but it works
                        if ($script:IntuneToken) {
                            Write-Host "Using cached token to display roles..." -ForegroundColor Gray
                            
                            # Extract token information without having to call Connect-IntuneWithToken again
                            # This avoids duplicating the output
                            try {
                                $tokenParts = $script:IntuneToken.Split('.')
                                if ($tokenParts.Count -ge 2) {
                                    $payload = $tokenParts[1].Replace('-', '+').Replace('_', '/')
                                    while ($payload.Length % 4) { $payload += "=" }
                                    
                                    $decodedToken = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
                                    
                                    # Extract roles only - we already showed scopes above
                                    $roles = @()
                                    
                                    if ($decodedToken.roles) {
                                        $roles = $decodedToken.roles
                                    }
                                    
                                    if ($decodedToken.wids) {
                                        $roles += $decodedToken.wids
                                    }
                                    
                                    # Show roles with friendly names
                                    if ($roles.Count -gt 0) {
                                        Write-Host "`nAssigned roles (from token):" -ForegroundColor Cyan
                                        foreach ($roleId in $roles | Sort-Object) {
                                            # Get friendly name without verbosity
                                            $friendlyName = Get-IntuneRoleFriendlyName -RoleId $roleId
                                            
                                            # Display both the friendly name and ID
                                            if ($friendlyName -ne $roleId) {
                                                Write-Host "  * $friendlyName  [$roleId]" -ForegroundColor Magenta
                                            } else {
                                                # If no friendly name was found, just show the ID
                                                Write-Host "  * $roleId" -ForegroundColor Magenta
                                            }
                                        }
                                        Write-Host ""
                                    }
                                    
                                    return
                                }
                            }
                            catch {
                                # If the manual token parsing fails, fall back to the original approach
                                $null = Connect-IntuneWithToken -Token $script:IntuneToken -ShowScopes -SuppressWarnings
                            }
                            
                            return # The Connect function displayed the roles already
                        }
                        else {
                            Write-Warning "No cached token available to display roles."
                        }
                    }
                }
                catch {
                    Write-Warning "Could not retrieve token role information: $($_.Exception.Message)"
                }
                
                if ($errorDetails) {
                    Write-Error "Original Graph API error: $errorDetails"
                }
                else {
                    Write-Error "User not found: $UserId"
                }
                return
            }
            else {
                if ($errorDetails) {
                    Write-Error "Error finding user: $errorDetails"
                }
                else {
                    Write-Error "User not found: $UserId"
                }
                return
            }
        }
        
        Write-Host "`nUser information:" -ForegroundColor Cyan
        Write-Host "  Display Name: $($user.DisplayName)" -ForegroundColor Yellow
        Write-Host "  UPN: $($user.UserPrincipalName)" -ForegroundColor Yellow
        Write-Host "  Object ID: $($user.Id)" -ForegroundColor Yellow
        
        # Get directory role assignments for the user
        $directRoles = @()
        $groupRoles = @()
        $allRoles = @()
        
        # Try to directly get role assignments via beta endpoint if available
        if (Get-Command Get-MgBetaUserMemberOf -ErrorAction SilentlyContinue) {
            $memberOf = Get-MgBetaUserMemberOf -UserId $user.Id -All
            
            foreach ($membership in $memberOf) {
                if ($membership.'@odata.type' -eq '#microsoft.graph.directoryRole') {
                    $directRoles += [PSCustomObject]@{
                        RoleName = $membership.DisplayName
                        RoleId = $membership.RoleTemplateId
                        AssignmentType = "Direct"
                    }
                    $allRoles += $membership.DisplayName
                }
                
                if ($membership.'@odata.type' -eq '#microsoft.graph.group') {
                    # Check if this group has role assignments
                    try {
                        $groupRoleAssignments = Get-MgBetaGroupMemberOf -GroupId $membership.Id -All | 
                            Where-Object { $_.'@odata.type' -eq '#microsoft.graph.directoryRole' }
                        
                        foreach ($roleAssignment in $groupRoleAssignments) {
                            $groupRoles += [PSCustomObject]@{
                                RoleName = $roleAssignment.DisplayName
                                RoleId = $roleAssignment.RoleTemplateId
                                GroupName = $membership.DisplayName
                                AssignmentType = "Group"
                            }
                            $allRoles += $roleAssignment.DisplayName
                        }
                    }
                    catch {
                        Write-Verbose "Error checking group role assignments for group $($membership.DisplayName): $_"
                    }
                }
            }
        }
        else {
            # Fallback to standard API if beta is not available
            $memberOf = Get-MgUserMemberOf -UserId $user.Id -All
            
            foreach ($membership in $memberOf) {
                if ($membership.'@odata.type' -eq '#microsoft.graph.directoryRole') {
                    $directRoles += [PSCustomObject]@{
                        RoleName = $membership.DisplayName
                        RoleId = $membership.RoleTemplateId
                        AssignmentType = "Direct"
                    }
                    $allRoles += $membership.DisplayName
                }
            }
            
            Write-Warning "Group role assignments cannot be retrieved with standard API. Use beta API for full information."
        }
        
        # Display the results
        if ($directRoles.Count -gt 0) {
            Write-Host "`nDirect Role Assignments:" -ForegroundColor Green
            foreach ($role in $directRoles) {
                Write-Host "  * $($role.RoleName)" -ForegroundColor Green
                if ($role.RoleId) {
                    Write-Host "    Role Template ID: $($role.RoleId)" -ForegroundColor Gray
                }
            }
        }
        else {
            Write-Host "`nNo direct role assignments found." -ForegroundColor Yellow
        }
        
        if ($groupRoles.Count -gt 0) {
            Write-Host "`nGroup-based Role Assignments:" -ForegroundColor Green
            
            # Group by role name to avoid duplication
            $groupedRoles = $groupRoles | Group-Object RoleName
            
            foreach ($groupedRole in $groupedRoles) {
                Write-Host "  * $($groupedRole.Name)" -ForegroundColor Green
                
                $groups = $groupedRole.Group | Select-Object -Unique GroupName
                $groupNames = $groups.GroupName -join ', '
                Write-Host "    Via Group(s): $groupNames" -ForegroundColor Gray
                
                # Show role ID if available
                $roleId = ($groupedRole.Group | Select-Object -First 1).RoleId
                if ($roleId) {
                    Write-Host "    Role Template ID: $roleId" -ForegroundColor Gray
                }
            }
        }
        elseif (-not (Get-Command Get-MgBetaUserMemberOf -ErrorAction SilentlyContinue)) {
            Write-Host "`nGroup-based role assignments not checked (requires beta API)." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nNo group-based role assignments found." -ForegroundColor Yellow
        }
        
        # Summary
        Write-Host "`nSummary:" -ForegroundColor Cyan
        Write-Host "  Total Direct Role Assignments: $($directRoles.Count)" -ForegroundColor Cyan
        Write-Host "  Total Group-based Role Assignments: $($groupRoles.Count)" -ForegroundColor Cyan
        Write-Host "  Total Unique Roles: $($allRoles | Select-Object -Unique | Measure-Object).Count" -ForegroundColor Cyan
        
        return @{
            DirectRoles = $directRoles
            GroupRoles = $groupRoles
            UniqueRoles = $allRoles | Select-Object -Unique
            User = $user
        }
    }
    catch {
        Write-Error "Error in Show-IntuneAssignedRoles: $_"
        
        # Fallback to token if enabled
        if ($FallbackToToken -and $script:IntuneToken) {
            Write-Warning "Falling back to token role information..."
            try {
                $tokenParts = $script:IntuneToken.Split('.')
                if ($tokenParts.Count -ge 2) {
                    $payload = $tokenParts[1].Replace('-', '+').Replace('_', '/')
                    while ($payload.Length % 4) { $payload += "=" }
                    
                    $decodedToken = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
                    
                    # Extract roles
                    $roles = @()
                    
                    if ($decodedToken.roles) {
                        $roles = $decodedToken.roles
                    }
                    
                    if ($decodedToken.wids) {
                        $roles += $decodedToken.wids
                    }
                    
                    # Show user info
                    if ($decodedToken.upn) {
                        Write-Host "`nToken-based information for: $($decodedToken.upn)" -ForegroundColor Cyan
                    } elseif ($decodedToken.unique_name) {
                        Write-Host "`nToken-based information for: $($decodedToken.unique_name)" -ForegroundColor Cyan
                    }
                    
                    # Show roles with friendly names
                    if ($roles.Count -gt 0) {
                        Write-Host "Assigned roles (from token):" -ForegroundColor Cyan
                        foreach ($roleId in $roles | Sort-Object) {
                            # Get friendly name
                            $friendlyName = Get-IntuneRoleFriendlyName -RoleId $roleId
                            
                            # Display
                            if ($friendlyName -ne $roleId) {
                                Write-Host "  * $friendlyName  [$roleId]" -ForegroundColor Magenta
                            } else {
                                Write-Host "  * $roleId" -ForegroundColor Magenta
                            }
                        }
                    }
                } else {
                    # If token parsing fails, use the original method
                    $null = Connect-IntuneWithToken -Token $script:IntuneToken -ShowScopes -SuppressWarnings
                }
            }
            catch {
                Write-Error "Failed to display token roles: $_"
            }
        }
    }
} 