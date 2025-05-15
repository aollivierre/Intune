<#
.SYNOPSIS
    Tests and validates SCHANNEL security scripts for Microsoft Intune
.DESCRIPTION
    This script validates all SCHANNEL remediation scripts to ensure they are properly formatted
    and ready for signing and deployment to Microsoft Intune
.NOTES
    Author: Intune Administrator
    Version: 1.0
#>

# Base script path
$scriptBasePath = Join-Path -Path $PSScriptRoot -ChildPath ""

# Get all categories
$categories = @("ServerProtocols", "ClientProtocols", "Ciphers", "Hashes", "KeyExchanges")

# Function to test a script
function Test-Script {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    try {
        # Check if file exists
        if (-not (Test-Path $ScriptPath)) {
            Write-Error "Script file not found: $ScriptPath"
            return $false
        }
        
        # Try to parse the script
        $null = [scriptblock]::Create((Get-Content -Path $ScriptPath -Raw))
        
        # Check for help sections
        $content = Get-Content -Path $ScriptPath -Raw
        $hasSynopsis = $content -match "\.SYNOPSIS"
        $hasDescription = $content -match "\.DESCRIPTION"
        
        if (-not $hasSynopsis) {
            Write-Warning "Script is missing SYNOPSIS help section: $ScriptPath"
        }
        
        if (-not $hasDescription) {
            Write-Warning "Script is missing DESCRIPTION help section: $ScriptPath"
        }
        
        # Validate exit codes for detection scripts
        if ($ScriptPath -match "Detect") {
            $hasExit0 = $content -match "exit\s+0"
            $hasExit1 = $content -match "exit\s+1"
            
            if (-not ($hasExit0 -and $hasExit1)) {
                Write-Warning "Detection script may be missing proper exit codes (0/1): $ScriptPath"
            }
        }
        
        return $true
    } catch {
        Write-Error "Error validating script $ScriptPath`: $_"
        return $false
    }
}

# Function to test script pairs
function Test-ScriptPairs {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category
    )
    
    $detectionPath = Join-Path -Path $scriptBasePath -ChildPath "$Category\Detection"
    $remediationPath = Join-Path -Path $scriptBasePath -ChildPath "$Category\Remediation"
    
    $pairs = @()
    $validCount = 0
    $warningCount = 0
    $errorCount = 0
    
    # Check if paths exist
    if (-not (Test-Path $detectionPath)) {
        Write-Error "Detection directory not found: $detectionPath"
        return $false
    }
    
    if (-not (Test-Path $remediationPath)) {
        Write-Error "Remediation directory not found: $remediationPath"
        return $false
    }
    
    # Get all detection scripts
    $detectionScripts = Get-ChildItem -Path $detectionPath -Filter "*.ps1"
    
    if ($detectionScripts.Count -eq 0) {
        Write-Warning "No detection scripts found in $detectionPath"
    }
    
    # Process each detection script
    foreach ($detectionScript in $detectionScripts) {
        $detectionName = $detectionScript.Name
        $baseName = $detectionName -replace "^Detect-", "" -replace "\.ps1$", ""
        
        Write-Host "Checking $Category - $baseName" -ForegroundColor Cyan
        
        # Find matching remediation script
        $remediationPattern = "Remediate-$baseName.ps1"
        $alternatePattern = "Remediate-$($baseName -replace '-.*', '').ps1" # For cases like TLS1.0-Server -> TLS1.0
        
        $remediationScript = Get-ChildItem -Path $remediationPath -Filter $remediationPattern -ErrorAction SilentlyContinue
        if (-not $remediationScript) {
            $remediationScript = Get-ChildItem -Path $remediationPath -Filter $alternatePattern -ErrorAction SilentlyContinue
        }
        
        if (-not $remediationScript) {
            Write-Error "  No matching remediation script found for: $detectionName"
            $errorCount++
            continue
        }
        
        # Test both scripts
        $detectionValid = Test-Script -ScriptPath $detectionScript.FullName
        $remediationValid = Test-Script -ScriptPath $remediationScript.FullName
        
        if ($detectionValid -and $remediationValid) {
            Write-Host "  [OK] Scripts are valid" -ForegroundColor Green
            $validCount++
        } else {
            Write-Warning "  [WARNING] One or both scripts have issues"
            $warningCount++
        }
    }
    
    Write-Host "`nSummary for $Category" -ForegroundColor Yellow
    Write-Host "  - Total script pairs: $($detectionScripts.Count)" -ForegroundColor White
    Write-Host "  - Valid pairs: $validCount" -ForegroundColor $(if ($validCount -eq $detectionScripts.Count) { "Green" } else { "Yellow" })
    
    if ($warningCount -gt 0) {
        Write-Host "  - Pairs with warnings: $warningCount" -ForegroundColor Yellow
    }
    
    if ($errorCount -gt 0) {
        Write-Host "  - Pairs with errors: $errorCount" -ForegroundColor Red
    }
    
    return ($errorCount -eq 0)
}

# Main process
try {
    Write-Host "Validating SCHANNEL scripts for Intune deployment`n" -ForegroundColor Cyan
    
    $allValid = $true
    
    foreach ($category in $categories) {
        Write-Host "`n=== Testing $category ===" -ForegroundColor Cyan
        $result = Test-ScriptPairs -Category $category
        $allValid = $allValid -and $result
    }
    
    if ($allValid) {
        Write-Host "`n[OK] All scripts are valid and ready for deployment" -ForegroundColor Green
    } else {
        Write-Host "`n[WARNING] Some scripts have issues that should be addressed before deployment" -ForegroundColor Yellow
    }
    
    Write-Host "`nTo deploy these scripts to Intune, run Deploy-SCHANNELScripts.ps1" -ForegroundColor Cyan
    
} catch {
    Write-Error "Error in script execution: $_"
} 