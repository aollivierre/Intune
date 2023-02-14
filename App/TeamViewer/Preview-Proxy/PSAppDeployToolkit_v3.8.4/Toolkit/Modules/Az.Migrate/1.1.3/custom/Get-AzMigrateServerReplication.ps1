
# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.Synopsis
Retrieves the details of the replicating server.
.Description
The Get-AzMigrateServerReplication cmdlet retrieves the object for the replicating server.
.Link
https://docs.microsoft.com/powershell/module/az.migrate/get-azmigrateserverreplication
#>
function Get-AzMigrateServerReplication {
    [OutputType([Microsoft.Azure.PowerShell.Cmdlets.Migrate.Models.Api20210210.IMigrationItem])]
    [CmdletBinding(DefaultParameterSetName = 'ListByName', PositionalBinding = $false)]
    param(
        [Parameter(ParameterSetName = 'GetBySRSID', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the replicating server.
        ${TargetObjectID},

        [Parameter(ParameterSetName = 'ListByName', Mandatory)]
        [Parameter(ParameterSetName = 'GetByMachineName', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the Resource Group of the Azure Migrate Project in the current subscription.
        ${ResourceGroupName},

        [Parameter(ParameterSetName = 'ListByName', Mandatory)]
        [Parameter(ParameterSetName = 'GetByMachineName', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the Azure Migrate project  in the current subscription.
        ${ProjectName},

        [Parameter(ParameterSetName = 'GetBySDSID', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the machine ID of the discovered server.
        ${DiscoveredMachineId},

        [Parameter(ParameterSetName = 'GetByInputObject', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Models.Api20210210.IMigrationItem]
        # Specifies the machine object of the replicating server.
        ${InputObject},

        [Parameter(ParameterSetName = 'ListById', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the Resource Group of the Azure Migrate Project in the current subscription.
        ${ResourceGroupID},

        [Parameter(ParameterSetName = 'ListById', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the Azure Migrate Project in which servers are replicating.
        ${ProjectID},

        [Parameter(ParameterSetName = 'GetByMachineName', Mandatory)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [System.String]
        # Specifies the display name of the replicating machine.
        ${MachineName},

        [Parameter(ParameterSetName = 'ListByName')]
        [Parameter(ParameterSetName = 'ListById')]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Query')]
        [System.String]
        # OData filter options.
        ${Filter},
    
        [Parameter(ParameterSetName = 'ListByName')]
        [Parameter(ParameterSetName = 'ListById')]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Query')]
        [System.String]
        # The pagination token.
        ${SkipToken},
    
        [Parameter()]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Path')]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Runtime.DefaultInfo(Script = '(Get-AzContext).Subscription.Id')]
        [System.String]
        # Azure Subscription ID.
        ${SubscriptionId},

        [Parameter()]
        [Alias('AzureRMContext', 'AzureCredential')]
        [ValidateNotNull()]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Azure')]
        [System.Management.Automation.PSObject]
        # The credentials, account, tenant, and subscription used for communication with Azure.
        ${DefaultProfile},
    
        [Parameter(DontShow)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Runtime')]
        [System.Management.Automation.SwitchParameter]
        # Wait for .NET debugger to attach
        ${Break},
    
        [Parameter(DontShow)]
        [ValidateNotNull()]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Runtime')]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Runtime.SendAsyncStep[]]
        # SendAsync Pipeline Steps to be appended to the front of the pipeline
        ${HttpPipelineAppend},
    
        [Parameter(DontShow)]
        [ValidateNotNull()]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Runtime')]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Runtime.SendAsyncStep[]]
        # SendAsync Pipeline Steps to be prepended to the front of the pipeline
        ${HttpPipelinePrepend},
    
        [Parameter(DontShow)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Runtime')]
        [System.Uri]
        # The URI for the proxy server to use
        ${Proxy},
    
        [Parameter(DontShow)]
        [ValidateNotNull()]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Runtime')]
        [System.Management.Automation.PSCredential]
        # Credentials for a proxy server to use for the remote call
        ${ProxyCredential},
    
        [Parameter(DontShow)]
        [Microsoft.Azure.PowerShell.Cmdlets.Migrate.Category('Runtime')]
        [System.Management.Automation.SwitchParameter]
        # Use the default credentials for the proxy
        ${ProxyUseDefaultCredentials}
    )
    
    process {
        $parameterSet = $PSCmdlet.ParameterSetName
        $null = $PSBoundParameters.Remove('TargetObjectID')
        $null = $PSBoundParameters.Remove('ResourceGroupName')
        $null = $PSBoundParameters.Remove('ProjectName')
        $null = $PSBoundParameters.Remove('DiscoveredMachineId')
        $null = $PSBoundParameters.Remove('InputObject')
        $null = $PSBoundParameters.Remove('ResourceGroupID')
        $null = $PSBoundParameters.Remove('ProjectID')
        $HasFilter = $PSBoundParameters.ContainsKey('Filter')
        $HasSkipToken = $PSBoundParameters.ContainsKey('SkipToken')
        $null = $PSBoundParameters.Remove('Filter')
        $null = $PSBoundParameters.Remove('SkipToken')
        $null = $PSBoundParameters.Remove('MachineName')
           
        if ($parameterSet -eq "GetBySDSID") {
            $MachineIdArray = $DiscoveredMachineId.Split("/")
            $SiteType = $MachineIdArray[7]
            $SiteName = $MachineIdArray[8]
            $ResourceGroupName = $MachineIdArray[4]
            $MachineName = $MachineIdArray[10]

            if ($SiteType -ne "VMwareSites") {
                throw "Provider not supported."
            }

            $null = $PSBoundParameters.Add('ResourceGroupName', $ResourceGroupName)
            $null = $PSBoundParameters.Add('SiteName', $SiteName)
            $siteObject = Az.Migrate\Get-AzMigrateSite @PSBoundParameters
            $ProjectName = $siteObject.DiscoverySolutionId.Split("/")[8]
                
            $null = $PSBoundParameters.Remove('SiteName')

            $null = $PSBoundParameters.Add("Name", "Servers-Migration-ServerMigration")
            $null = $PSBoundParameters.Add("MigrateProjectName", $ProjectName)
                
            $solution = Az.Migrate\Get-AzMigrateSolution @PSBoundParameters
            if ($solution -and ($solution.Count -ge 1)) {
                $VaultName = $solution.DetailExtendedDetail.AdditionalProperties.vaultId.Split("/")[8]
                   
                $null = $PSBoundParameters.Remove("Name")
                $null = $PSBoundParameters.Remove("MigrateProjectName")
                $null = $PSBoundParameters.Add('ResourceName', $VaultName)
                $allFabrics = Az.Migrate\Get-AzMigrateReplicationFabric @PSBoundParameters
                $FabricName = ""
                if ($allFabrics -and ($allFabrics.length -gt 0)) {
                    foreach ($fabric in $allFabrics) {
                        if (($fabric.Property.CustomDetail.InstanceType -ceq "VMwareV2") -and ($fabric.Property.CustomDetail.VmwareSiteId.Split("/")[8] -ceq $SiteName)) {
                            $FabricName = $fabric.Name
                            break
                        }
                    }
                }
                if ($FabricName -eq "") {
                    throw "Fabric not found for given resource group"
                }
    
                $null = $PSBoundParameters.Add('FabricName', $FabricName)
                $peContainers = Az.Migrate\Get-AzMigrateReplicationProtectionContainer @PSBoundParameters
                $ProtectionContainerName = ""
                if ($peContainers -and ($peContainers.length -gt 0)) {
                    $ProtectionContainerName = $peContainers[0].Name
                }
    
                if ($ProtectionContainerName -eq "") {
                    throw "Container not found for given resource group"
                }
    
                $null = $PSBoundParameters.Add("MigrationItemName", $MachineName)
                $null = $PSBoundParameters.Add("ProtectionContainerName", $ProtectionContainerName)
    
                return Az.Migrate.internal\Get-AzMigrateReplicationMigrationItem @PSBoundParameters
            }
            else {
                throw "Solution not found."
            }
        }
            
        if (($parameterSet -match 'List') -or ($parameterSet -eq "GetByMachineName")) {
            if ($parameterSet -eq 'ListById') {
                $ProjectName = $ProjectID.Split("/")[8]
                $ResourceGroupName = $ResourceGroupID.Split("/")[4]
            }
            $null = $PSBoundParameters.Add("ResourceGroupName", $ResourceGroupName)
            $null = $PSBoundParameters.Add("Name", "Servers-Migration-ServerMigration")
            $null = $PSBoundParameters.Add("MigrateProjectName", $ProjectName)
                
            $solution = Az.Migrate\Get-AzMigrateSolution @PSBoundParameters
            if ($solution -and ($solution.Count -ge 1)) {
                $VaultName = $solution.DetailExtendedDetail.AdditionalProperties.vaultId.Split("/")[8]
            }
            else {
                throw "Solution not found."
            }

            $null = $PSBoundParameters.Remove("Name")
            $null = $PSBoundParameters.Remove("MigrateProjectName")
            $null = $PSBoundParameters.Add('ResourceName', $VaultName)

            if ($HasFilter) {
                $null = $PSBoundParameters.Add("Filter", $Filter)
            }
            if ($HasSkipToken) {
                $null = $PSBoundParameters.Add("SkipToken", $SkipToken)
            }
                
            $replicatingItems = Az.Migrate.internal\Get-AzMigrateReplicationMigrationItem @PSBoundParameters
            if ($parameterSet -eq "GetByMachineName") {
                $replicatingItems = $replicatingItems | Where-Object { $_.MachineName -eq $MachineName }
            }
            return $replicatingItems
        }

        if (($parameterSet -eq "GetByInputObject") -or ($parameterSet -eq "GetBySRSID")) {
            if ($parameterSet -eq 'GetByInputObject') {
                $TargetObjectID = $InputObject.Id
            }
            $MachineIdArray = $TargetObjectID.Split("/")
            $ResourceGroupName = $MachineIdArray[4]
            $VaultName = $MachineIdArray[8]
            $FabricName = $MachineIdArray[10]
            $ProtectionContainerName = $MachineIdArray[12]
            $MachineName = $MachineIdArray[14]
            $null = $PSBoundParameters.Add("ResourceGroupName", $ResourceGroupName)
            $null = $PSBoundParameters.Add("ResourceName", $VaultName)
            $null = $PSBoundParameters.Add("FabricName", $FabricName)
            $null = $PSBoundParameters.Add("MigrationItemName", $MachineName)
            $null = $PSBoundParameters.Add("ProtectionContainerName", $ProtectionContainerName)
    
            return Az.Migrate.internal\Get-AzMigrateReplicationMigrationItem @PSBoundParameters
        }
    }
}
# SIG # Begin signature block
# MIInoQYJKoZIhvcNAQcCoIInkjCCJ44CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCADXMF8DaJL3JJ/
# 8quWjWskra92Gr+OeBi9AB821yMCIaCCDYEwggX/MIID56ADAgECAhMzAAACzI61
# lqa90clOAAAAAALMMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjIwNTEyMjA0NjAxWhcNMjMwNTExMjA0NjAxWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCiTbHs68bADvNud97NzcdP0zh0mRr4VpDv68KobjQFybVAuVgiINf9aG2zQtWK
# No6+2X2Ix65KGcBXuZyEi0oBUAAGnIe5O5q/Y0Ij0WwDyMWaVad2Te4r1Eic3HWH
# UfiiNjF0ETHKg3qa7DCyUqwsR9q5SaXuHlYCwM+m59Nl3jKnYnKLLfzhl13wImV9
# DF8N76ANkRyK6BYoc9I6hHF2MCTQYWbQ4fXgzKhgzj4zeabWgfu+ZJCiFLkogvc0
# RVb0x3DtyxMbl/3e45Eu+sn/x6EVwbJZVvtQYcmdGF1yAYht+JnNmWwAxL8MgHMz
# xEcoY1Q1JtstiY3+u3ulGMvhAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUiLhHjTKWzIqVIp+sM2rOHH11rfQw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDcwNTI5MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAeA8D
# sOAHS53MTIHYu8bbXrO6yQtRD6JfyMWeXaLu3Nc8PDnFc1efYq/F3MGx/aiwNbcs
# J2MU7BKNWTP5JQVBA2GNIeR3mScXqnOsv1XqXPvZeISDVWLaBQzceItdIwgo6B13
# vxlkkSYMvB0Dr3Yw7/W9U4Wk5K/RDOnIGvmKqKi3AwyxlV1mpefy729FKaWT7edB
# d3I4+hldMY8sdfDPjWRtJzjMjXZs41OUOwtHccPazjjC7KndzvZHx/0VWL8n0NT/
# 404vftnXKifMZkS4p2sB3oK+6kCcsyWsgS/3eYGw1Fe4MOnin1RhgrW1rHPODJTG
# AUOmW4wc3Q6KKr2zve7sMDZe9tfylonPwhk971rX8qGw6LkrGFv31IJeJSe/aUbG
# dUDPkbrABbVvPElgoj5eP3REqx5jdfkQw7tOdWkhn0jDUh2uQen9Atj3RkJyHuR0
# GUsJVMWFJdkIO/gFwzoOGlHNsmxvpANV86/1qgb1oZXdrURpzJp53MsDaBY/pxOc
# J0Cvg6uWs3kQWgKk5aBzvsX95BzdItHTpVMtVPW4q41XEvbFmUP1n6oL5rdNdrTM
# j/HXMRk1KCksax1Vxo3qv+13cCsZAaQNaIAvt5LvkshZkDZIP//0Hnq7NnWeYR3z
# 4oFiw9N2n3bb9baQWuWPswG0Dq9YT9kb+Cs4qIIwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZdjCCGXICAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAsyOtZamvdHJTgAAAAACzDAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgqor/1Dsq
# Z6yE0t3mYBWPElvLdVTgj+FDa9xZCwR85xQwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQBH9qSWCgwt96VbZgceKVlH90g7XeVv+rToN/tw3hyx
# gw4iObsUncydPvwpy1rpvVMJYbrHdw535QzDLO8qTJG1IBliLUBawoE6nrvT8/lb
# KeMF5ywUzo4VlWIi8dsSThRejki2wWP0bCY9hET7VxYwyhTx38dLa89pwVSmdwKy
# hNT90ovBIdpDDPAPGDiClvzr6NNNVin2/SQjgMgU6VNEvSQoZAi7Xx1ZXiZysxCR
# lmxyZUSbR3sjB1A0TalXWlV/PwDki2x3gUJqAIc101VytXN4RM36GwV7p1Zv2FWO
# 68ZE2eYiH1E0ElSIQ4cm32Z6nmdOqC/dKcBDHcPXhRP+oYIXADCCFvwGCisGAQQB
# gjcDAwExghbsMIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglghkgBZQME
# AgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEINV90N76BAbrAKEmxVHrW7dTL9wbXzS/vLX21cnj
# nnvZAgZi1XrrycAYEzIwMjIwNzI3MTAxNzE4LjM3MlowBIACAfSggdCkgc0wgcox
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
# Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOjEyQkMtRTNBRS03NEVCMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIRVzCCBwwwggT0oAMCAQICEzMAAAGhAYVVmblUXYoAAQAAAaEw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MjExMjAyMTkwNTI0WhcNMjMwMjI4MTkwNTI0WjCByjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MTJCQy1FM0FFLTc0
# RUIxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDayTxe5WukkrYxxVuHLYW9BEWCD9kk
# jnnHsOKwGddIPbZlLY+l5ovLDNf+BEMQKAZQI3DX91l1yCDuP9X7tOPC48ZRGXA/
# bf9ql0FK5438gIl7cV528XeEOFwc/A+UbIUfW296Omg8Z62xaQv3jrG4U/priArF
# /er1UA1HNuIGUyqjlygiSPwK2NnFApi1JD+Uef5c47kh7pW1Kj7RnchpFeY9MekP
# QRia7cEaUYU4sqCiJVdDJpefLvPT9EdthlQx75ldx+AwZf2a9T7uQRSBh8tpxPdI
# DDkKiWMwjKTrAY09A3I/jidqPuc8PvX+sqxqyZEN2h4GA0Edjmk64nkIukAK18K5
# nALDLO9SMTxpAwQIHRDtZeTClvAPCEoy1vtPD7f+eqHqStuu+XCkfRjXEpX9+h9f
# rsB0/BgD5CBf3ELLAa8TefMfHZWEJRTPNrbXMKizSrUSkVv/3HP/ZsJpwaz5My2R
# byc3Ah9bT76eBJkyfT5FN9v/KQ0HnxhRMs6HHhTmNx+LztYci+vHf0D3QH1eCjZW
# ZRjp1mOyxpPU2mDMG6gelvJse1JzRADo7YIok/J3Ccbm8MbBbm85iogFltFHecHF
# EFwrsDGBFnNYHMhcbarQNA+gY2e2l9fAkX3MjI7Uklkoz74/P6KIqe5jcd9FPCbb
# SbYH9OLsteeYOQIDAQABo4IBNjCCATIwHQYDVR0OBBYEFBa/IDLbY475VQyKiZSw
# 47l0/cypMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRY
# MFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01p
# Y3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEF
# BQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
# MSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQELBQADggIBACDDIxElfXlG5YKcKrLPSS+f3JWZprwKEiASvivaHTBRlXtA
# s+TkadcsEei+9w5vmF5tCUzTH4c0nCI7bZxnsL+S6XsiOs3Z1V4WX+IwoXUJ4zLv
# s0+mT4vjGDtYfKQ/bsmJKar2c99m/fHv1Wm2CTcyaePvi86Jh3UyLjdRILWbtzs4
# oImFMwwKbzHdPopxrBhgi+C1YZshosWLlgzyuxjUl+qNg1m52MJmf11loI7D9HJo
# aQzd+rf928Y8rvULmg2h/G50o+D0UJ1Fa/cJJaHfB3sfKw9X6GrtXYGjmM3+g+Ah
# aVsfupKXNtOFu5tnLKvAH5OIjEDYV1YKmlXuBuhbYassygPFMmNgG2Ank3drEcDc
# ZhCXXqpRszNo1F6Gu5JCpQZXbOJM9Ue5PlJKtmImAYIGsw+pnHy/r5ggSYOp4g5Z
# 1oU9GhVCM3V0T9adee6OUXBk1rE4dZc/UsPlj0qoiljL+lN1A5gkmmz7k5tIObVG
# B7dJdz8J0FwXRE5qYu1AdvauVbZwGQkL1x8aK/svjEQW0NUyJ29znDHiXl5vLoRT
# jjFpshUBi2+IY+mNqbLmj24j5eT+bjDlE3HmNtLPpLcMDYqZ1H+6U6YmaiNmac2j
# RXDAaeEE/uoDMt2dArfJP7M+MDv3zzNNTINeuNEtDVgm9zwfgIUCXnDZuVtiMIIH
# cTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCB
# iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
# TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEw
# OTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIh
# C3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNx
# WuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFc
# UTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAc
# nVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUo
# veO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyzi
# YrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9
# fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdH
# GO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7X
# KHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiE
# R9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/
# eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3
# FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAd
# BgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEE
# AYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMB
# Af8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1Ud
# HwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3By
# b2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQRO
# MEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2Vy
# dHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4IC
# AQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pk
# bHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gng
# ugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3
# lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHC
# gRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6
# MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEU
# BHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvsh
# VGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+
# fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrp
# NPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHI
# qzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEBMIH4
# oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUw
# IwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjoxMkJDLUUzQUUtNzRFQjElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAG3F2jO4LEMVLwgKG
# XdYMN4FBgOCggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOaLLYEwIhgPMjAyMjA3MjcxMTIwMzNaGA8yMDIyMDcy
# ODExMjAzM1owdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5ostgQIBADAKAgEAAgIz
# WgIB/zAHAgEAAgITajAKAgUA5ox/AQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUA
# A4GBAGd0J1WofPf9d6lBL7V0vmKaNAW4Zbzq4QZYPgy74WROnzXaSqX+M/53UoRe
# nRd0/baY1W/bDmVLWOPGAHlHQj2NutiwSEICtGZtpf0RgLDcG6Tqu1PMMNHZSF7g
# OPo4Mih3LgvtTQKIBM4NnN+Cvi/pIn2AbkycGDTgNxtLcn/7MYIEDTCCBAkCAQEw
# gZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGhAYVVmblUXYoA
# AQAAAaEwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAvBgkqhkiG9w0BCQQxIgQgR/aLb9AFemhv4HYt8yEGPElr2S79mVIvUaKP
# NHhrVpQwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDrCFTxOoGCaCCCjoRy
# Be1JSQrMJeCCTyErziiJ347QhDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABoQGFVZm5VF2KAAEAAAGhMCIEINJ21ak2BQL/iDLa9wQN
# FgiXvzj2L2ZKPP/4gFNsfMe/MA0GCSqGSIb3DQEBCwUABIICAMdsgdLChc45V0XV
# gDcnM2Ti7gquz4d3sF1Jjm7fAS24VpqCvTRtcbekoUnQHLxnA1pqNXEoVMP6uqKR
# fhmIG3nOGcp3T8HOLQ8aPs9yurVUhLWQv3NQxG7A+rlBOLivDV0bCwpy+sviJehU
# tCRdPl2gxwxTOaTeLDbZ+tyENxCON3T4/CB479WVENqpe4dEz3R6LmtgjBxST7l/
# nn6tpY4AztgpN1eBurxLEd6AyNqa/SI3k8tVrsLugxCfeQsvnrpLhe1LKiUUWp/A
# UkcW3bpV0UMwBqCnI0itoYxQAQIBgWszv5VgVyh003gG/iWvtQO6y6IgZSLWGGmZ
# VoL9qVoncjcjUS+9FFMwvfaGucLkhnpWiK94zhiO5S/kCjEgHNDQAFnjyfKt6BQ4
# LU0LHigUxSLBDd7VIDESFpHOEHZI7ItEI3RlW7UcI5QHHVQINz3K3idiXYC5Z4zV
# NZyWT8ofUR+jl2ZOx6gJxdkDLfpC83TDAMVctmcMGi6TeLNXI3W/PNtZAt1MQebX
# iaXctKGdMK/BMpJckaBg+sgMcOUXr69Dcq4IxHt+yMomNhyC91edMgBmcV0FZYLg
# B43pvF7hA7bIJd8eZOIoccaXM4T1ikJlxHErmONp32pQUxwYAnYCEVoiVMAseL4j
# 8LJD6GANBWEcryNE2HCFmBUeUWvW
# SIG # End signature block
