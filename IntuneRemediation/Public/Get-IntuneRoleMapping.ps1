function Get-IntuneRoleMapping {
    <#
    .SYNOPSIS
        Gets a mapping of all available Microsoft Entra ID roles and their IDs.
        
    .DESCRIPTION
        This function queries Microsoft Graph to retrieve all available directory role templates
        and their corresponding IDs. This helps with troubleshooting role resolution issues
        and understanding what roles are available in your tenant.
        
    .PARAMETER IncludeDeprecated
        If specified, includes deprecated and special-purpose roles in the output.
        
    .EXAMPLE
        Get-IntuneRoleMapping
        
        Lists all active role templates and their IDs.
        
    .EXAMPLE
        Get-IntuneRoleMapping -IncludeDeprecated
        
        Lists all role templates, including deprecated ones.
        
    .NOTES
        Requires a connection to Microsoft Graph.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDeprecated
    )
    
    # Check if we're connected to Microsoft Graph
    try {
        if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue) -or -not (Get-MgContext)) {
            Write-Error "Not connected to Microsoft Graph. Please connect first with Connect-MgGraph."
            return
        }
        
        Write-Host "Retrieving directory role templates..." -ForegroundColor Cyan
        
        # Try Beta API first for the most comprehensive information
        $roleTemplates = $null
        try {
            if (Get-Command Get-MgBetaDirectoryRoleTemplate -ErrorAction SilentlyContinue) {
                $roleTemplates = Get-MgBetaDirectoryRoleTemplate -All
                Write-Verbose "Retrieved $($roleTemplates.Count) role templates using Beta API."
            }
        }
        catch {
            Write-Verbose "Failed to retrieve roles using Beta API: $_"
        }
        
        # Fall back to standard API if Beta API fails or is not available
        if (-not $roleTemplates) {
            try {
                $roleTemplates = Get-MgDirectoryRoleTemplate -All
                Write-Verbose "Retrieved $($roleTemplates.Count) role templates using standard API."
            }
            catch {
                Write-Error "Failed to retrieve role templates: $_"
                return
            }
        }
        
        # Process and filter the roles
        $results = @()
        foreach ($role in $roleTemplates) {
            $isActive = $true
            $category = "Standard"
            
            # Check if role should be skipped
            if (-not $IncludeDeprecated) {
                if (($role.DisplayName -match '(Device Managers|Device Users|Partner|Device Join|Workplace Device Join)') -or
                    ($role.Description -match '(deprecated|do not use|default role for)')) {
                    $isActive = $false
                    $category = "Deprecated/Special"
                }
            }
            
            if ($isActive -or $IncludeDeprecated) {
                $results += [PSCustomObject]@{
                    DisplayName = $role.DisplayName
                    Id          = $role.Id
                    Description = $role.Description
                    IsActive    = $isActive
                    Category    = $category
                }
            }
        }
        
        # Sort and output the results
        $sortedResults = $results | Sort-Object DisplayName
        
        Write-Host "`nFound $($sortedResults.Count) role templates" -ForegroundColor Green
        
        return $sortedResults
    }
    catch {
        Write-Error "Error in Get-IntuneRoleMapping: $_"
    }
} 