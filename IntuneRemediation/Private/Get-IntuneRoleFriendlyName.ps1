function Get-IntuneRoleFriendlyName {
    <#
    .SYNOPSIS
        Gets the friendly name for a Microsoft Entra ID role GUID.
        
    .DESCRIPTION
        This function converts Microsoft Entra ID (Azure AD) role GUIDs to their friendly display names.
        It primarily attempts to query Microsoft Graph for the most up-to-date information,
        with a fallback to a small dictionary of common roles if Graph isn't available.
        
    .PARAMETER RoleId
        The GUID of the role to look up.
        
    .EXAMPLE
        Get-IntuneRoleFriendlyName -RoleId "3a2c62db-5318-420d-8d74-23affee5d9d5"
        
        Returns "Intune Administrator"
        
    .NOTES
        This function dynamically queries Microsoft Graph when possible for the most
        accurate and current role names.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoleId
    )

    # Use script-level variable for caching role information
    if (-not (Test-Path variable:script:cachedRoleTemplates)) {
        $script:cachedRoleTemplates = @{}
    }
    
    # First, try to get from cache
    if ($script:cachedRoleTemplates.ContainsKey($RoleId)) {
        Write-Verbose "Retrieved role name from cache: $($script:cachedRoleTemplates[$RoleId])"
        return $script:cachedRoleTemplates[$RoleId]
    }
    
    # Try to query Microsoft Graph if connected
    try {
        # Check if Graph module is available and we're connected
        if ((Get-Command Get-MgContext -ErrorAction SilentlyContinue) -and (Get-MgContext)) {
            Write-Verbose "Connected to Microsoft Graph, querying for role with ID: $RoleId"
            
            # Try to get the role template directly
            try {
                $role = Get-MgDirectoryRoleTemplate -DirectoryRoleTemplateId $RoleId -ErrorAction Stop
                if ($role -and $role.DisplayName) {
                    # Store in cache for future use
                    $script:cachedRoleTemplates[$RoleId] = $role.DisplayName
                    return $role.DisplayName
                }
            }
            catch {
                Write-Verbose "Could not find role template with ID $RoleId directly, trying beta API"
                
                # Try with beta API if available
                if (Get-Command Get-MgBetaDirectoryRoleTemplate -ErrorAction SilentlyContinue) {
                    try {
                        $role = Get-MgBetaDirectoryRoleTemplate -DirectoryRoleTemplateId $RoleId -ErrorAction Stop
                        if ($role -and $role.DisplayName) {
                            # Store in cache for future use
                            $script:cachedRoleTemplates[$RoleId] = $role.DisplayName
                            return $role.DisplayName
                        }
                    }
                    catch {
                        Write-Verbose "Could not find role template with beta API: $_"
                    }
                }
            }
            
            # If we get here, try to get all role templates and search for our ID
            if (-not $script:allRoleTemplates) {
                try {
                    $script:allRoleTemplates = if (Get-Command Get-MgBetaDirectoryRoleTemplate -ErrorAction SilentlyContinue) {
                        Get-MgBetaDirectoryRoleTemplate -All
                    } else {
                        Get-MgDirectoryRoleTemplate -All
                    }
                }
                catch {
                    Write-Verbose "Failed to retrieve all role templates: $_"
                    $script:allRoleTemplates = @()
                }
            }
            
            # Search in the full list
            $foundRole = $script:allRoleTemplates | Where-Object { $_.Id -eq $RoleId }
            if ($foundRole -and $foundRole.DisplayName) {
                # Store in cache for future use
                $script:cachedRoleTemplates[$RoleId] = $foundRole.DisplayName
                return $foundRole.DisplayName
            }
        }
    }
    catch {
        Write-Verbose "Error querying Microsoft Graph for role information: $_"
    }
    
    # Fallback to a small dictionary of common Intune and Microsoft 365 admin roles
    $commonRoles = @{
        # Most common Intune roles
        "3a2c62db-5318-420d-8d74-23affee5d9d5" = "Intune Administrator"
        "7698a772-787b-4ac8-901f-60d6b08affd2" = "Endpoint Security Administrator" 
        "c4e39bd9-1100-46d3-8c65-fb160da0071f" = "Intune ReadOnly Administrator"
        
        # Most common Microsoft 365 admin roles
        "62e90394-69f5-4237-9190-012177145e10" = "Global Administrator"
        "4a5d8f65-41da-4de4-8968-e035b65339cf" = "Security Administrator"
        "644ef478-e28f-4e28-b9dc-3fdde9aa0b1f" = "Groups Administrator"
        "fe930be7-5e62-47db-91af-98c3a49a38b1" = "User Administrator"
        "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9" = "Compliance Administrator"
        "b79fbf4d-3ef9-4689-8143-76b194e85509" = "Security Reader"
        "790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b" = "Reports Reader"
        "9f06204d-73c1-4d4c-880a-6edb90606fd8" = "Cloud Device Administrator"
        "729827e3-9c14-49f7-bb1b-9608f156bbb8" = "Service Support Administrator"
        "fdd7a751-b60b-444a-984c-02652fe8fa1c" = "Helpdesk Administrator"
        "194ae4cb-b126-40b2-bd5b-6091b380977d" = "Printer Administrator"
        "c4e39bd9-1100-46d3-8c65-fb160da071f" = "Authentication Administrator"
    }
    
    # Try to get from the fallback dictionary
    if ($commonRoles.ContainsKey($RoleId)) {
        # Store in cache for future use
        $script:cachedRoleTemplates[$RoleId] = $commonRoles[$RoleId]
        return $commonRoles[$RoleId]
    }
    
    # If all else fails, return the original ID
    return $RoleId
} 