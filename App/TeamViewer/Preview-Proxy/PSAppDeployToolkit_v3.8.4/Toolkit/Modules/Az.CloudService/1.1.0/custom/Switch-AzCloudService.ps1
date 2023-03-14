
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
Swaps VIPs between two cloud service (extended support) load balancers.
.Description
Swaps VIPs between two cloud service (extended support) load balancers.

.Link
https://docs.microsoft.com/powershell/module/az.cloudservice/Switch-AzCloudService

#>
function Switch-AzCloudService {
    [OutputType([System.Boolean])]
    [CmdletBinding(DefaultParameterSetName='CloudServiceName', PositionalBinding=$false, SupportsShouldProcess, ConfirmImpact='High')]
    param(
    
        [Parameter(ParameterSetName='CloudService')]
        [Parameter(ParameterSetName='CloudServiceName')]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Path')]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Runtime.DefaultInfo(Script='(Get-AzContext).Subscription.Id')]
        [System.String]
        # Subscription credentials which uniquely identify Microsoft Azure subscription.
        # The subscription ID forms part of the URI for every service call.
        ${SubscriptionId},
    
        [Parameter(Mandatory=$true, ParameterSetName="CloudService")]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Path')]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Models.Api20210301.CloudService]
        ${CloudService},
    
        [Parameter(Mandatory=$true, ParameterSetName="CloudServiceName")]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Path')]
        [System.String]
        ${ResourceGroupName},
        
        [Parameter(Mandatory=$true, ParameterSetName="CloudServiceName")]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Path')]
        [System.String] 
        ${CloudServiceName},

        [Parameter()]
        [switch] 
        ${Async},

        [Parameter()]
        [Alias('AzureRMContext', 'AzureCredential')]
        [ValidateNotNull()]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Azure')]
        [System.Management.Automation.PSObject]
        # The credentials, account, tenant, and subscription used for communication with Azure.
        ${DefaultProfile},
    
        [Parameter()]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Runtime')]
        [System.Management.Automation.SwitchParameter]
        # Run the command as a job
        ${AsJob},
    
        [Parameter(DontShow)]
        [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Runtime')]
        [System.Management.Automation.SwitchParameter]
        # Wait for .NET debugger to attach
        ${Break}
    )
    
    process {
        $ApiVersion = "2020-06-01"
        if (-not $PSBoundParameters.ContainsKey("SubscriptionId")) {
            $SubscriptionId = (Get-AzContext).Subscription.Id
        }

        # Fetch the services to ensure that we have the latest information
        if ($PSBoundParameters.ContainsKey("CloudService")) {
            $CloudServiceName = $CloudService.Name
            $ResourceGroupName = $CloudService.ResourceGroupName
        }

        $SourceCloudService = Get-AzCloudService -SubscriptionId $SubscriptionId -Name $CloudServiceName -ResourceGroupName $ResourceGroupName

        # Check that both have swappable property set.
        if ([string]::IsNullOrEmpty($SourceCloudService.NetworkProfile.SwappableCloudService.Id)) {
            throw "SwappableCloudServiceId is not set on the source cloud service $($SourceCloudService.Name)"
        }

        # Check that Public IPs counts are correct for source
        $validSourceIP = ValidateCloudServicePublicIPAddress($SourceCloudService)
        if ($validSourceIP -eq $false) {
            throw "Specified source cloud service must have a single public IP address specified in its FrontendIpConfigurations." 
        }
  
        # Parse target cloud service fields
        $elements = $SourceCloudService.NetworkProfile.SwappableCloudService.Id.Split("/")
        if (($elements.Count -lt 9) -or ("subscriptions" -ne $elements[1]) -or ("resourceGroups" -ne $elements[3]) -or ("cloudServices" -ne $elements[7]))
        {
            throw "SourceCloudService.NetworkProfile.SwappableCloudService.Id should match the format: /subscriptions/(?<TargetSubscriptionId>[^/]+)/resourceGroups/(?<TargetResourceGroupName>[^/]+/providers/Microsoft.Compute/cloudServices/(?<TargetCloudServiceName>[^/]+))"
        }
        $TargetSubscriptionId = $elements[2]
        $TargetResourceGroupName = $elements[4]
        $TargetCloudServiceName = $elements[8]
 
        # Fetch the target cloud service 
        $TargetCloudService = Get-AzCloudService -SubscriptionId $TargetSubscriptionId -Name $TargetCloudServiceName -ResourceGroupName $TargetResourceGroupName

        # Check that Public IPs counts are correct for target
        $validTargetIP = ValidateCloudServicePublicIPAddress($TargetCloudService)
        if ($validTargetIP -eq $false) {
            throw "Specified target cloud service must have a single public IP address specified in its FrontendIpConfigurations." 
        }

        # Get the LBs and FrontEndIpConfigs to create the request body
        $sourceLB = GetCloudServiceLoadBalancer($SubscriptionId, $ResourceGroupName, $SourceCloudService.NetworkProfile.LoadBalancerConfiguration[0].Name, $ApiVersion)
        $validSourceLB = ValidateLoadBalancerFrontEndIPConfiguration($sourceLB)
        if ($validSourceLB -eq $false) {
            throw "Source loadbBalancer must have a single value in its FrontendIpConfigurations." 
        }

        $targetLB =  GetCloudServiceLoadBalancer($TargetSubscriptionId, $TargetResourceGroupName, $TargetCloudService.NetworkProfile.LoadBalancerConfiguration[0].Name, $ApiVersion)      
        $validTargetLB = ValidateLoadBalancerFrontEndIPConfiguration($targetLB)
        if ($validTargetLB -eq $false) {
            throw "Target loadbBalancer must have a single value in its FrontendIpConfigurations." 
        }

        # Construct the request body
        $requestBody = GetVIPSwapRequestBody
        $requestBody = $requestBody -replace "#LBFE1#", $sourceLB.properties.frontendIPConfigurations[0].Id
        $requestBody = $requestBody -replace "#PIP2#", $TargetCloudService.NetworkProfile.LoadBalancerConfiguration[0].FrontendIPConfiguration[0].PublicIPAddressId
        $requestBody = $requestBody -replace "#LBFE2#", $targetLB.properties.frontendIPConfigurations[0].Id
        $requestBody = $requestBody -replace "#PIP1#", $SourceCloudService.NetworkProfile.LoadBalancerConfiguration[0].FrontendIPConfiguration[0].PublicIPAddressId

        # Set up API URI and Headers
        $uriToInvoke = "/subscriptions/$SubscriptionId/providers/Microsoft.Network/locations/$($SourceCloudService.Location)/setLoadBalancerFrontendPublicIpAddresses?api-version=$ApiVersion"

        # Display the information about the VIP swap being made
        Write-Host "Performing switch cloud service (VIP swap) action between $($SourceCloudService.Name) and $($TargetCloudService.Name)

Request URI : $uriToInvoke
POST

Request Body :
$requestBody"

        # Invoke the VIP swap API
        if ($PSCmdlet.ShouldProcess($SourceCloudService.Name + " <=> " + $TargetCloudService.Name,'VIP swap')) {
            $result = Invoke-AzRestMethod -Method POST -Path $uriToInvoke -Payload $requestBody 

            if ($Async.IsPresent) {
                Write-Host "Query the Azure-AsyncOperation URI from the response for operation progress"
                return $result
            }
            else {
               if ($result.StatusCode -eq 202) {
                   QueryVipSwapOperation($result)
               }
               else {
                   return $result
               }
            }
        }
    }
}

function QueryVipSwapOperation($result) {

    $uri = [System.Uri]($result.Headers.GetValues('Azure-AsyncOperation')[0]);
    $uriToInvoke = $uri.PathAndQuery
    $retryLimit = 100
    $retry = 0

    while ($retry -lt $retryLimit) {
        $statusResult = Invoke-AzRestMethod -Method GET -Path $uriToInvoke  
        if ($statusResult.StatusCode -eq 200) {
            $status = $statusResult.Content | ConvertFrom-Json
            if (-not $status.status.Equals("InProgress",[System.StringComparison]::OrdinalIgnoreCase)) {
                return $statusResult
            }

            $retry++
            Write-Progress -Activity "Performing VIP swap" -PercentComplete $retry -CurrentOperation "Status : InProgress"

            Start-Sleep -Seconds 10
        }
    }
}

function ValidateLoadBalancerFrontEndIPConfiguration($lb) {

    if ($lb.properties.frontendIPConfigurations.Count -eq 1) {   
        if (-not [string]::IsNullOrEmpty($lb.properties.frontendIPConfigurations[0].Id)) {
            return $true;
        }
    }

    return $false;
}

function ValidateCloudServicePublicIPAddress($cs) {

    if ($cs.NetworkProfile.LoadBalancerConfiguration.Count -eq 1) {
        if ($cs.NetworkProfile.LoadBalancerConfiguration[0].FrontendIPConfiguration.Count -eq 1) {
            if (-not [string]::IsNullOrEmpty($cs.NetworkProfile.LoadBalancerConfiguration[0].FrontendIPConfiguration[0].PublicIPAddressId)) {
                return $true;
            }
        }
    }

    return $false;
}

function GetCloudServiceLoadBalancer($parameters) {

    # Set up API URI and Headers
    $uriToInvoke = "/subscriptions/" + $parameters[0] + "/resourceGroups/" + $parameters[1] + "/providers/Microsoft.Network/loadBalancers/" + $parameters[2] + "?api-version=" + $parameters[3]
    $lbResponse = Invoke-AzRestMethod -Method GET -Path $uriToInvoke
    if ($lbResponse.StatusCode -ne 200) {
       throw $lbResponse.Content
    }

    $lb = $lbResponse.Content | ConvertFrom-Json
    return $lb
}

function GetVIPSwapRequestBody() {

    return @"
{
	"frontendIPConfigurations": [
		{
			"id": "#LBFE1#",
			"properties": {
				"publicIPAddress": {
					"id": "#PIP2#"
				}
			}
		},
		{
			"id": "#LBFE2#",
			"properties": {
				"publicIPAddress": {
					"id": "#PIP1#"
				}
			}
		}
	]
}
"@
}


# SIG # Begin signature block
# MIInugYJKoZIhvcNAQcCoIInqzCCJ6cCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAyZeKQOmdwkHVP
# qQRWamE7+U2bF1XBXM/9Uc6ihxkloKCCDYEwggX/MIID56ADAgECAhMzAAACUosz
# qviV8znbAAAAAAJSMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMjU5WhcNMjIwOTAxMTgzMjU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDQ5M+Ps/X7BNuv5B/0I6uoDwj0NJOo1KrVQqO7ggRXccklyTrWL4xMShjIou2I
# sbYnF67wXzVAq5Om4oe+LfzSDOzjcb6ms00gBo0OQaqwQ1BijyJ7NvDf80I1fW9O
# L76Kt0Wpc2zrGhzcHdb7upPrvxvSNNUvxK3sgw7YTt31410vpEp8yfBEl/hd8ZzA
# v47DCgJ5j1zm295s1RVZHNp6MoiQFVOECm4AwK2l28i+YER1JO4IplTH44uvzX9o
# RnJHaMvWzZEpozPy4jNO2DDqbcNs4zh7AWMhE1PWFVA+CHI/En5nASvCvLmuR/t8
# q4bc8XR8QIZJQSp+2U6m2ldNAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUNZJaEUGL2Guwt7ZOAu4efEYXedEw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDY3NTk3MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAFkk3
# uSxkTEBh1NtAl7BivIEsAWdgX1qZ+EdZMYbQKasY6IhSLXRMxF1B3OKdR9K/kccp
# kvNcGl8D7YyYS4mhCUMBR+VLrg3f8PUj38A9V5aiY2/Jok7WZFOAmjPRNNGnyeg7
# l0lTiThFqE+2aOs6+heegqAdelGgNJKRHLWRuhGKuLIw5lkgx9Ky+QvZrn/Ddi8u
# TIgWKp+MGG8xY6PBvvjgt9jQShlnPrZ3UY8Bvwy6rynhXBaV0V0TTL0gEx7eh/K1
# o8Miaru6s/7FyqOLeUS4vTHh9TgBL5DtxCYurXbSBVtL1Fj44+Od/6cmC9mmvrti
# yG709Y3Rd3YdJj2f3GJq7Y7KdWq0QYhatKhBeg4fxjhg0yut2g6aM1mxjNPrE48z
# 6HWCNGu9gMK5ZudldRw4a45Z06Aoktof0CqOyTErvq0YjoE4Xpa0+87T/PVUXNqf
# 7Y+qSU7+9LtLQuMYR4w3cSPjuNusvLf9gBnch5RqM7kaDtYWDgLyB42EfsxeMqwK
# WwA+TVi0HrWRqfSx2olbE56hJcEkMjOSKz3sRuupFCX3UroyYf52L+2iVTrda8XW
# esPG62Mnn3T8AuLfzeJFuAbfOSERx7IFZO92UPoXE1uEjL5skl1yTZB3MubgOA4F
# 8KoRNhviFAEST+nG8c8uIsbZeb08SeYQMqjVEmkwggd6MIIFYqADAgECAgphDpDS
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
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZjzCCGYsCAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgR8Mn2xZc
# OGr3e9QnT1TtrUJ/eM2GdTi+1hsBwsPC/IAwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQCUz6wdwtGUWbmVHOfVrlzb9nVPmBY78g0lFDGAOuM2
# F37Keo3SpNoCVMgHKFoJ836R3wEZExMVi9H9ZUYOkvxWkc1uzQeUDzzqO/K/LLFl
# oh/rfZHIdZOZDudY11bRTJ45TbjcIFCAKCsYq/LLujb3PDtBjxdevJCI2LPzMuVi
# 7AlogNp1UVrzuybXqb8AY3ch+x/u/U1XLvSWii1ulPHDhGZXukB+aWenHgrG+tuE
# wGYzHdlCeZcVhT8zAWdaTrfeg6uFjmFwbQ8nD+TCdNqjFtx9hmGizt+yXItBRdV+
# fZ/oLvorpU9NbnFS2ZEcjXOIzFfMBYFQF2vsF5aPcLNzoYIXGTCCFxUGCisGAQQB
# gjcDAwExghcFMIIXAQYJKoZIhvcNAQcCoIIW8jCCFu4CAQMxDzANBglghkgBZQME
# AgEFADCCAVkGCyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIKOasWwG8KAhxDClKAc++1Q9eCt7DA/Ywq2/MVbB
# Qi0yAgZiF5Xkr6IYEzIwMjIwMjI1MTM1MDQ5LjY2N1owBIACAfSggdikgdUwgdIx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1p
# Y3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhh
# bGVzIFRTUyBFU046RkM0MS00QkQ0LUQyMjAxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFNlcnZpY2WgghFoMIIHFDCCBPygAwIBAgITMwAAAY5Z20YAqBCU
# zAABAAABjjANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMDAeFw0yMTEwMjgxOTI3NDVaFw0yMzAxMjYxOTI3NDVaMIHSMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQg
# SXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOkZDNDEtNEJENC1EMjIwMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqiMCq6OM
# zLa5wrtcf7Bf9f1WXW9kpqbOBzgPJvaGLrZG7twgwqTRWf1FkjpJKBOG5QPIRy7a
# 6IFVAy0W+tBaFX4In4DbBf2tGubyY9+hRU+hRewPJH5CYOvpPh77FfGM63+OlwRX
# p5YER6tC0WRKn3mryWpt4CwADuGv0LD2QjnhhgtRVidsiDnn9+aLjMuNapUhstGq
# Cr7JcQZt0ZrPUHW/TqTJymeU1eqgNorEbTed6UQyLaTVAmhXNQXDChfa526nW7RQ
# 7L4tXX9Lc0oguiCSkPlu5drNA6NM8z+UXQOAHxVfIQXmi+Y3SV2hr2dcxby9nlTz
# Yvf4ZDr5Wpcwt7tTdRIJibXHsXWMKrmOziliGDToLx34a/ctZE4NOLnlrKQWN9ZG
# +Ox5zRarK1EhShahM0uQNhb6BJjp3+c0eNzMFJ2qLZqDp2/3Yl5Q+4k+MDHLTipP
# 6VBdxcdVfd4mgrVTx3afO5KNfgMngGGfhSawGraRW28EhrLOspmIxii92E7vjncJ
# 2tcjhLCjBArVpPh3cZG5g3ZVy5iiAaoDaswpNgnMFAK5Un1reK+MFhPi9iMnvUPw
# tTDDJt5YED5DAT3mBUxp5QH3t7RhZwAJNLWLtpTeGF7ub81sSKYv2ardazAe9XLS
# 10tV2oOPrcniGJzlXW7VPvxqQNxe8lCDA20CAwEAAaOCATYwggEyMB0GA1UdDgQW
# BBTsQfkz9gT44N/5G8vNHayep+aV5DAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJl
# pxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAx
# MCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3Rh
# bXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMA0GCSqGSIb3DQEBCwUAA4ICAQA1UK9xzIeTlKhSbLn0bekR5gYh
# 6bB1XQpluCqCA15skZ37UilaFJw8+GklDLzlNhSP2mOiOzVyCq8kkpqnfUc01ZaB
# ezQxg77qevj2iMyg39YJfeiCIhxYOFugwepYrPO8MlB/oue/VhIiDb1eNYTlPSmv
# 3palsgtkrb0oo0F0uWmX4EQVGKRo0UENtZetVIxa0J9DpUdjQWPeEh9cEM+RgE26
# 5w5WAVb+WNx0iWiF4iTbCmrWaVEOX92dNqBm9bT1U7nGwN5CygpNAgEaYnrTMx1N
# 4AjxObACDN5DdvGlu/O0DfMWVc6qk6iKDFC6WpXQSkMlrlXII/Nhp+0+noU6tfEp
# HKLt7fYm9of5i/QomcCwo/ekiOCjYktp393ovoC1O2uLtbLnMVlE5raBLBNSbINZ
# 6QLxiA41lXnVVLIzDihUL8MU9CMvG4sdbhk2FX8zvrsP5PeBIw1faenMZuz0V3UX
# CtU5Okx5fmioWiiLZSCi1ljaxX+BEwQiinCi+vE59bTYI5FbuR8tDuGLiVu/JSpV
# FXrzWMP2Kn11sCLAGEjqJYUmO1tRY29Kd7HcIj2niSB0PQOCjYlnCnywnDinqS1C
# XvRsisjVlS1Rp4Tmuks+pGxiMGzF58zcb+hoFKyONuL3b+tgxTAz3sF3BVX9uk9M
# 5F+OEoeyLyGfLekNAjCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg
# 4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aO
# RmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41
# JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5
# LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL
# 64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9
# QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj
# 0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqE
# UUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0
# kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435
# UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB
# 3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTE
# mr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwG
# A1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNV
# HSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNV
# HQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo
# 0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29m
# dC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5j
# cmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDAN
# BgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4
# sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th54
# 2DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRX
# ud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBew
# VIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0
# DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+Cljd
# QDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFr
# DZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFh
# bHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7n
# tdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+
# oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6Fw
# ZvKhggLXMIICQAIBATCCAQChgdikgdUwgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RkM0MS00QkQ0
# LUQyMjAxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
# ATAHBgUrDgMCGgMVAD1iK+pPThHqgpa5xsPmiYruWVuMoIGDMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQACBQDlwr0OMCIY
# DzIwMjIwMjI1MTAyNzI2WhgPMjAyMjAyMjYxMDI3MjZaMHcwPQYKKwYBBAGEWQoE
# ATEvMC0wCgIFAOXCvQ4CAQAwCgIBAAICDOQCAf8wBwIBAAICEUUwCgIFAOXEDo4C
# AQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEK
# MAgCAQACAwGGoDANBgkqhkiG9w0BAQUFAAOBgQBX/UVtKrgul2Jmf6tK5Ea70TLO
# q2+EMOjez2LDx9FXZnWrly1jaQ4eCH8z0L0fRycFs1UkmzVXRZ55UWSPMb5TnqJG
# XxfKLpY8r0qs2xtW3B8cwldUNlBkvPmVfocWY/CcjfetZ4vRexSbsnHWB9chBRMO
# uoR/IOjXsHvSnPnbFjGCBA0wggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABjlnbRgCoEJTMAAEAAAGOMA0GCWCGSAFlAwQCAQUAoIIB
# SjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIJM8
# X+0y1g/WxkpHFiMs3TErzOn0FEOMQ8NYSyKqlgIlMIH6BgsqhkiG9w0BCRACLzGB
# 6jCB5zCB5DCBvQQgvQWPITvigaUuV5+f/lWs3BXZwJ/l1mf+yelu5nXmxCUwgZgw
# gYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAY5Z20YAqBCU
# zAABAAABjjAiBCBzzpIZxrSTMjWuEzEts64aL3G72IOpOS9gKknv6EwAaTANBgkq
# hkiG9w0BAQsFAASCAgAaDZMt/lCT9M126JUvmn2bI4IwptQopr9kffBI2x1uwX31
# ztG1HcPTuVx2zYoDz4bVI5vVChgKQQQz8cqYoemIv+J5jvrbYYBeW1gAsOFqscCf
# o0BWZ9i0bhBBIF7cEYpQoOO1umlHWdupQiYuj0WpUZJMIAquIFZ2sH4YEF9AJAna
# c22/2QXFFBGoMJl0krrLjRtJlIuPO9wMFT8ZjFkmSyx12fKpKAxyZQT+d6ie6FI6
# 53I8qnFBQv7vgMntsPOmTT8o8ZQeNiHQccJd93nvoqbF5RoZz/WLGenvHAy5lhjm
# yCxwxARDfYIvCNDe5R2+WYyKu6CDRxxFE4FMkMN0ChMn9BVmli26ojE7kOmOXBzu
# BTLIi6ND1HTdHJh5+XAuvTeqdDtwSCGrkmw/c2esvk9XIPZTB9IOXsLcilenHRLI
# uJaToea8ogF63vyNwNDAkDSS+r2ZYf1ip+S7pnoFvw+W3euhhcPBZCI+6i5dI2AE
# MdWmkb0D++ToGMrtUVAmJxPYiCkyoQCvPFLGltDznGyUEkDWv4bHynvfyZaw17xf
# 5Xiyk2p7rfPwrbirywgv8N2IbOrlpsmypsXRr9egYG5akdq7aRc4/FuJO6tJyP0r
# 8ygxraaatz+wTFV5FtyjvhOBrjccaUvaV5dQ4/TN6x1qRbBk2yJc3rI62r2UvQ==
# SIG # End signature block
