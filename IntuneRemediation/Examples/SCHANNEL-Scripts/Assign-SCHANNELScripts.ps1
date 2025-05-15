[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProfileName = "Default",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [string]$Token,
    
    [Parameter(Mandatory = $false)]
    [string]$SCHANNELPrefix = "SCHANNEL",
    
    [Parameter(Mandatory = $false)]
    [string]$GroupId = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

<#
.SYNOPSIS
    Safely assigns SCHANNEL remediation scripts to specific Microsoft Entra groups
.DESCRIPTION
    This script connects to Microsoft Intune, finds all remediation scripts with
    the specified prefix (default: "SCHANNEL"), displays them for selection,
    validates the target Entra group, and assigns the selected scripts to the group
    after explicit user confirmation.
.PARAMETER ProfileName
    Name of the token profile to use (default: "Default")
.PARAMETER Force
    Forces new authentication even if a valid token exists
.PARAMETER Token
    Uses the specified token for authentication instead of interactive login
.PARAMETER SCHANNELPrefix
    The prefix used to identify SCHANNEL scripts (default: "SCHANNEL")
.PARAMETER GroupId
    The Microsoft Entra Group ID to assign scripts to (optional)
.PARAMETER WhatIf
    Shows what would happen if the script runs without actually making changes
.EXAMPLE
    .\Assign-SCHANNELScripts.ps1
    
    Connects to Intune, displays available SCHANNEL scripts, and guides you through the assignment process.
.EXAMPLE
    .\Assign-SCHANNELScripts.ps1 -WhatIf
    
    Shows what assignments would be made without actually making changes.
.EXAMPLE
    .\Assign-SCHANNELScripts.ps1 -GroupId "5b90aa-1234-5678-abcd-1234567890ab"
    
    Pre-fills the group ID for assignment.
.NOTES
    Author: Intune Administrator
    Version: 1.0
    Safety Features:
    - Only targets scripts with the exact SCHANNEL prefix (or custom prefix)
    - Validates Entra group information before assignment
    - Shows detailed group membership information for verification
    - Requires explicit confirmation before making assignments
    - Offers a -WhatIf parameter to see what would be assigned without making changes
#>

# Ensure we are in the script's directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath -Parent
Set-Location -Path $scriptDir

# Import the IntuneRemediation module
try {
    $modulePath = (Get-Item -Path $scriptDir).Parent.Parent.FullName
    Import-Module -Name "$modulePath\IntuneRemediation.psd1" -Force -ErrorAction Stop
    Write-Host "IntuneRemediation module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to import IntuneRemediation module: $_"
    Write-Host "Please ensure the module is installed or adjust the path accordingly." -ForegroundColor Yellow
    exit 1
}

# Function to display a menu and get a selection
function Show-Menu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Options,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowMultiple,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowAll
    )
    
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i+1). $($Options[$i])" -ForegroundColor White
    }
    
    if ($AllowAll) {
        Write-Host "A. All options" -ForegroundColor Yellow
    }
    
    Write-Host "Q. Quit" -ForegroundColor Red
    
    if ($AllowMultiple) {
        Write-Host "`nEnter numbers separated by commas (e.g., 1,3,5) or 'A' for all:" -ForegroundColor Yellow
        $selection = Read-Host "Selection"
        
        if ($selection -eq "Q" -or $selection -eq "q") {
            return @()
        }
        
        if ($AllowAll -and ($selection -eq "A" -or $selection -eq "a")) {
            return (1..$Options.Count)
        }
        
        $selectedIndices = @()
        $selection.Split(",") | ForEach-Object {
            if ($_ -match "^\d+$" -and [int]$_ -ge 1 -and [int]$_ -le $Options.Count) {
                $selectedIndices += [int]$_
            }
        }
        
        return $selectedIndices
    }
    else {
        $selection = Read-Host "Selection"
        
        if ($selection -eq "Q" -or $selection -eq "q") {
            return 0
        }
        
        if ($AllowAll -and ($selection -eq "A" -or $selection -eq "a")) {
            return -1  # Special value for "All"
        }
        
        if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $Options.Count) {
            return [int]$selection
        }
        
        return 0  # Invalid selection
    }
}

# Function to validate an Entra group ID and display group information
function Get-EntraGroupInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId
    )
    
    try {
        # Get group details
        $url = "https://graph.microsoft.com/v1.0/groups/$GroupId"
        $groupDetails = Invoke-MgGraphRequest -Method GET -Uri $url
        
        if (-not $groupDetails) {
            return $null
        }
        
        # Get group members count
        $url = "https://graph.microsoft.com/v1.0/groups/$GroupId/members/`$count"
        $usersCount = Invoke-MgGraphRequest -Method GET -Uri $url -Headers @{ "ConsistencyLevel" = "eventual" }
        
        # Get group transitive members count
        $url = "https://graph.microsoft.com/v1.0/groups/$GroupId/transitiveMembers/`$count"
        $transitiveCount = Invoke-MgGraphRequest -Method GET -Uri $url -Headers @{ "ConsistencyLevel" = "eventual" }
        
        # Get device count (if any)
        $deviceCount = 0
        try {
            $url = "https://graph.microsoft.com/v1.0/groups/$GroupId/members/microsoft.graph.device/`$count"
            $deviceCount = Invoke-MgGraphRequest -Method GET -Uri $url -Headers @{ "ConsistencyLevel" = "eventual" }
        }
        catch {
            # Ignore errors, just means no devices
            $deviceCount = 0
        }
        
        # Determine membership types
        $membershipTypes = @()
        if ($usersCount -gt $deviceCount) {
            $membershipTypes += "Users"
        }
        if ($deviceCount -gt 0) {
            $membershipTypes += "Devices"
        }
        
        $groupInfo = [PSCustomObject]@{
            Id = $groupDetails.id
            DisplayName = $groupDetails.displayName
            Description = $groupDetails.description
            CreatedDateTime = $groupDetails.createdDateTime
            MembershipType = $membershipTypes -join ", "
            DirectMemberCount = [int]$usersCount
            TransitiveMemberCount = [int]$transitiveCount
            DeviceCount = [int]$deviceCount
            UserCount = [int]$usersCount - [int]$deviceCount
            IsValid = $true
        }
        
        return $groupInfo
    }
    catch {
        Write-Warning "Error validating group ID: $_"
        return $null
    }
}

# Function to assign a script to a group
function New-ScriptAssignment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptId,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Prepare the assignment payload
    $assignmentBody = @{
        deviceHealthScriptAssignments = @(
            @{
                target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    groupId = $GroupId
                }
                runRemediationScript = $true
                runSchedule = @{
                    "@odata.type" = "#microsoft.graph.deviceHealthScriptRunSchedule"
                    interval = 1
                    useUtc = $false
                    time = "00:00:00.0000000"
                    timeZone = "UTC"
                }
            }
        )
    } | ConvertTo-Json -Depth 10
    
    if ($WhatIf) {
        Write-Host "  [WhatIf] Would assign script '$ScriptName' to group '$GroupName'" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "  Assigning script '$ScriptName' to group '$GroupName'..." -ForegroundColor Yellow -NoNewline
    
    try {
        # Create the assignment
        $url = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$ScriptId/assign"
        Invoke-MgGraphRequest -Method POST -Uri $url -Body $assignmentBody | Out-Null
        
        Write-Host " Success!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " Failed!" -ForegroundColor Red
        Write-Warning "    Error: $($_.Exception.Message)"
        return $false
    }
}

# Main process
try {
    # Step 1: Connect to Intune and Microsoft Graph
    Write-Host "`n=== CONNECTING TO MICROSOFT INTUNE ===" -ForegroundColor Cyan
    
    # Determine if we need to authenticate or can use a saved token
    $connected = $false
    
    if ($Token) {
        # Use provided token
        Write-Host "Using provided token for authentication..." -ForegroundColor Yellow
        $connected = Connect-IntuneWithToken -Token $Token -ShowScopes
    }
    else {
        # Check for saved token if not forcing authentication
        $useFoundToken = $false
        
        if (-not $Force) {
            $tokenInfo = Get-IntuneTokenInfo -ProfileName $ProfileName
            
            if ($tokenInfo.TokenFound -and -not $tokenInfo.IsExpired) {
                $useFoundToken = $true
                Write-Host "Using saved token for profile '$ProfileName'..." -ForegroundColor Green
                
                # Get the token and connect
                try {
                    $appDataPath = [Environment]::GetFolderPath('ApplicationData')
                    $tokenStoragePath = Join-Path -Path $appDataPath -ChildPath "IntuneRemediation\TokenStorage\$ProfileName"
                    $tokenPath = Join-Path -Path $tokenStoragePath -ChildPath "token.xml"
                    
                    if (Test-Path -Path $tokenPath) {
                        $secureToken = Import-Clixml -Path $tokenPath
                        $tokenValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                        )
                        
                        # Connect with the token
                        $connected = Connect-IntuneWithToken -Token $tokenValue -SuppressWarnings
                    }
                }
                catch {
                    Write-Warning "Error using saved token: $_"
                    $useFoundToken = $false
                }
            }
        }
        
        # If no token found or forced auth, use interactive login
        if (-not $useFoundToken -or -not $connected) {
            Write-Host "Using interactive authentication..." -ForegroundColor Yellow
            $connected = Initialize-IntuneConnection -ProfileName $ProfileName -ForceBrowser:$true
        }
    }
    
    if (-not $connected) {
        throw "Failed to connect to Microsoft Intune. Please try again or provide a valid token."
    }
    
    # Step 2: Fetch all SCHANNEL remediation scripts from Intune
    Write-Host "`n=== SEARCHING FOR SCHANNEL REMEDIATION SCRIPTS ===" -ForegroundColor Cyan
    Write-Host "Looking for scripts with prefix: $SCHANNELPrefix" -ForegroundColor Yellow
    
    # Use Microsoft Graph to get all deviceHealthScripts (remediation scripts)
    $url = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
    $response = Invoke-MgGraphRequest -Method GET -Uri $url
    $allScripts = $response.value
    
    # Filter scripts to only those with the SCHANNEL prefix
    $schannel_scripts = $allScripts | Where-Object { $_.displayName -like "$SCHANNELPrefix*" }
    $total_schannel_scripts = $schannel_scripts.Count
    
    if ($total_schannel_scripts -eq 0) {
        Write-Host "`nNo remediation scripts found with prefix '$SCHANNELPrefix'." -ForegroundColor Yellow
        Write-Host "Please upload the scripts first before attempting to assign them." -ForegroundColor Red
        exit 0
    }
    
    # Step 3: Display the scripts and let user select which to assign
    $scriptDisplayNames = $schannel_scripts | ForEach-Object { $_.displayName }
    $scriptSelection = Show-Menu -Title "SELECT SCRIPTS TO ASSIGN" -Options $scriptDisplayNames -AllowMultiple -AllowAll
    
    if ($scriptSelection.Count -eq 0) {
        Write-Host "`nScript assignment canceled. No changes were made." -ForegroundColor Yellow
        exit 0
    }
    
    # Prepare the list of selected scripts
    $selectedScripts = @()
    if ($scriptSelection.Count -gt 0) {
        foreach ($index in $scriptSelection) {
            $selectedScripts += $schannel_scripts[$index - 1]
        }
    }
    
    # Display selected scripts
    Write-Host "`nSelected Scripts:" -ForegroundColor Green
    foreach ($script in $selectedScripts) {
        Write-Host "  * $($script.displayName)" -ForegroundColor Yellow
    }
    
    # Step 4: Get the Entra Group ID
    $enteredGroupId = $GroupId
    $groupInfo = $null
    
    while (-not $groupInfo) {
        if (-not $enteredGroupId) {
            $enteredGroupId = Read-Host "`nEnter the Microsoft Entra Group ID to assign the scripts to"
            
            if (-not $enteredGroupId) {
                Write-Host "Group ID is required. Exiting script." -ForegroundColor Red
                exit 0
            }
        }
        
        Write-Host "`nValidating Group ID: $enteredGroupId" -ForegroundColor Cyan
        $groupInfo = Get-EntraGroupInfo -GroupId $enteredGroupId
        
        if (-not $groupInfo) {
            Write-Host "Invalid Group ID. The group could not be found or you don't have permission to access it." -ForegroundColor Red
            $enteredGroupId = ""  # Reset to prompt again
        }
    }
    
    # Step 5: Display group information for confirmation
    Write-Host "`n=== GROUP INFORMATION ===" -ForegroundColor Cyan
    Write-Host "Group Name: $($groupInfo.DisplayName)" -ForegroundColor Green
    Write-Host "Group ID: $($groupInfo.Id)" -ForegroundColor Green
    Write-Host "Description: $($groupInfo.Description)" -ForegroundColor Yellow
    Write-Host "Created: $($groupInfo.CreatedDateTime)" -ForegroundColor Yellow
    Write-Host "Membership Type: $($groupInfo.MembershipType)" -ForegroundColor Yellow
    Write-Host "Direct Member Count: $($groupInfo.DirectMemberCount)" -ForegroundColor Magenta
    if ($groupInfo.TransitiveMemberCount -gt $groupInfo.DirectMemberCount) {
        Write-Host "Transitive Member Count: $($groupInfo.TransitiveMemberCount) (includes nested group members)" -ForegroundColor Magenta
    }
    Write-Host "User Count: $($groupInfo.UserCount)" -ForegroundColor Magenta
    Write-Host "Device Count: $($groupInfo.DeviceCount)" -ForegroundColor Magenta
    
    # Step 6: Confirm assignment
    if ($WhatIf) {
        Write-Host "`n[WhatIf Mode] The following assignments would be made:" -ForegroundColor Yellow
        $confirmAssign = "Y"  # Auto-confirm in WhatIf mode
    }
    else {
        Write-Host "`n" -NoNewline
        Write-Host "!!! CONFIRMATION REQUIRED !!!" -ForegroundColor Red
        Write-Host "You are about to assign $($selectedScripts.Count) remediation scripts to group '$($groupInfo.DisplayName)'." -ForegroundColor Yellow
        Write-Host "This will apply the scripts to $($groupInfo.DirectMemberCount) group members." -ForegroundColor Yellow
        
        $confirmAssign = Read-Host "Are you sure you want to proceed with these assignments? Type 'Y' to confirm or any other key to cancel"
    }
    
    # Step 7: Perform the assignments if confirmed
    if ($confirmAssign -eq "Y") {
        $assignedCount = 0
        $failedCount = 0
        
        Write-Host "`n=== ASSIGNING SCRIPTS TO GROUP ===" -ForegroundColor Cyan
        
        foreach ($script in $selectedScripts) {
            $result = New-ScriptAssignment -ScriptId $script.id -ScriptName $script.displayName `
                                         -GroupId $groupInfo.Id -GroupName $groupInfo.DisplayName `
                                         -WhatIf:$WhatIf
            
            if ($result) {
                $assignedCount++
            }
            else {
                $failedCount++
            }
        }
        
        # Show summary
        Write-Host "`nAssignment Summary:" -ForegroundColor Cyan
        if ($WhatIf) {
            Write-Host "- [WhatIf] Scripts that would be assigned: $assignedCount" -ForegroundColor Yellow
        }
        else {
            Write-Host "- Successfully assigned: $assignedCount" -ForegroundColor $(if ($assignedCount -eq $selectedScripts.Count) { "Green" } else { "Yellow" })
            if ($failedCount -gt 0) {
                Write-Host "- Failed to assign: $failedCount" -ForegroundColor Red
            }
        }
        
        if (-not $WhatIf) {
            Write-Host "`nSCHANNEL remediation scripts have been successfully assigned to the group!" -ForegroundColor Green
        }
        else {
            Write-Host "`n[WhatIf Mode] No changes were made. Run without -WhatIf to actually assign the scripts." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`nScript assignment canceled. No changes were made." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Error in script execution: $_"
} 