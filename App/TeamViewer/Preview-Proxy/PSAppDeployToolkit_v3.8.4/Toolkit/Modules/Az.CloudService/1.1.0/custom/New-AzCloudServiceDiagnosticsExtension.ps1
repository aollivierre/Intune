# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the \"License\");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an \"AS IS\" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.Synopsis
Create a in-memory object for Diagnostics Extension
.Description
Create a in-memory object for Diagnostics Extension
#>

function New-AzCloudServiceDiagnosticsExtension {
  [OutputType('Microsoft.Azure.PowerShell.Cmdlets.CloudService.Models.Api20210301.Extension')]
  param(
    [Parameter(HelpMessage="Name of Diagnostics Extension.", Mandatory)]
    [string] $Name,

    [Parameter(HelpMessage="Subscription.")]
    [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Category('Path')]
    [Microsoft.Azure.PowerShell.Cmdlets.CloudService.Runtime.DefaultInfo(Script='(Get-AzContext).Subscription.Id')]
    [System.String]
    # Subscription credentials which uniquely identify Microsoft Azure subscription.
    # The subscription ID forms part of the URI for every service call.
    ${Subscription},

    [Parameter(HelpMessage="Resource Group name of Cloud Service.", Mandatory)]
    [string] $ResourceGroupName,

    [Parameter(HelpMessage="Name of Cloud Service.", Mandatory)]
    [string] $CloudServiceName,

    [Parameter(HelpMessage="Specifies the configuration for Azure Diagnostics. You can download the schema by using the following command: (Get-AzureServiceAvailableExtension -ExtensionName 'PaaSDiagnostics' -ProviderNamespace 'Microsoft.Azure.Diagnostics').PublicConfigurationSchema | Out-File -Encoding utf8 -FilePath 'WadConfig.xsd'", Mandatory)]
    [string] $DiagnosticsConfigurationPath,

    [Parameter(HelpMessage="Name of the Storage Account.", Mandatory)]
    [string] $StorageAccountName,

    [Parameter(HelpMessage="Storage Account Key.", Mandatory)]
    [string] $StorageAccountKey,

    [Parameter(HelpMessage="Specifies the version of the extension.")]
    [string] $TypeHandlerVersion,

    [Parameter(HelpMessage="Roles applied to.")]
    [string[]] $RolesAppliedTo,

    [Parameter(HelpMessage="Auto upgrade minor version.")]
    [Boolean] $AutoUpgradeMinorVersion
  )

  process {
    $publisher = "Microsoft.Azure.Diagnostics"
    $extensionType = "PaaSDiagnostics"

    if (!(Test-Path $DiagnosticsConfigurationPath -PathType Leaf))
    {
        throw ("DiagnosticsConfigurationPath does not exits: " + $DiagnosticsConfigurationPath)
    }

    [xml]$diagnosticsConfigurationXml = Get-Content $DiagnosticsConfigurationPath

    $storageAccount = $diagnosticsConfigurationXml.PublicConfig.ChildNodes | Where-Object { $_.Name -eq 'StorageAccount' }
    if ($storageAccount)
    {
        Write-Host "Using StorageAccount information defined in diagnostics configuration file."
    }
    else
    {
        $storageAccount = $diagnosticsConfigurationXml.CreateElement('StorageAccount', $diagnosticsConfigurationXml.PublicConfig.NamespaceURI)
        $storageAccount.InnerText = $StorageAccountName
        $storageAccount = $diagnosticsConfigurationXml.PublicConfig.AppendChild($storageAccount)
    }

    $metrics = $diagnosticsConfigurationXml.PublicConfig.WadCfg.DiagnosticMonitorConfiguration.ChildNodes | Where-Object { $_.Name -eq 'Metrics' }
    if ($metrics)
    {
        Write-Host "Using Metrics information defined in diagnostics configuration file."
    }
    else
    {
        $metrics = $diagnosticsConfigurationXml.CreateElement('Metrics', $diagnosticsConfigurationXml.PublicConfig.NamespaceURI)
        $resourceId = "/subscriptions/$Subscription/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/cloudservices/$CloudServiceName"
        $metrics.SetAttribute('resourceId', $resourceId)
        $metrics = $diagnosticsConfigurationXml.PublicConfig.WadCfg.DiagnosticMonitorConfiguration.AppendChild($metrics)
    }

    $setting = $diagnosticsConfigurationXml.PublicConfig.OuterXml

    $privateConfig = $diagnosticsConfigurationXml.ChildNodes | Where-Object { $_.Name -eq 'PrivateConfig' }
    if ($privateConfig)
    {
        $protectedSetting = $privateConfig.OuterXml
        Write-Host "Using PrivateConfig information defined in diagnostics configuration file."
    }
    else
    {
        $storageEndpoint = "https://core.windows.net"
        $protectedSetting = '<?xml version="1.0" encoding="UTF-8"?><PrivateConfig xmlns="http://schemas.microsoft.com/ServiceHosting/2010/10/DiagnosticsConfiguration"><StorageAccount endpoint="' + $storageEndpoint + '" key="' + $StorageAccountKey + '" name="' + $storageAccountName + '"/></PrivateConfig>'
    }

    return New-AzCloudServiceExtensionObject -Name $Name -Publisher $publisher -Type $extensionType -TypeHandlerVersion $TypeHandlerVersion -Setting $setting -ProtectedSetting $protectedSetting -RolesAppliedTo $RolesAppliedTo -AutoUpgradeMinorVersion $AutoUpgradeMinorVersion
  }
}

# SIG # Begin signature block
# MIInnAYJKoZIhvcNAQcCoIInjTCCJ4kCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBMK3Sd3Sul2qH0
# rffK8MRUNGuKtpDYzvxETocj6XKFSaCCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZcTCCGW0CAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgF5R7r2dD
# W1ulbXR2M8a5Lhvo36xyaTor+/+UR1RtT/YwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQCvowPQuEg7zj7aIrtf6+wdM85hCQm9O8GSzo18Cfl8
# aRKQ2BF/0WMbegfl9XXaSTocITYH3Mi4XtEU9rURmofavCOIiYb2KILhkjVmwl92
# FBHFmrhbKm/c8sLLp1Rpsb14oIBxl8Qb+0RmrUf0MTEyVa0KHpIfr6vsKOwP3Y0d
# rSaO+kqjj9/xVm+6JoftNeL0Ll36GFnwo7alBRj0Q1wzpW2Gvk6Y8EDnZ7qEspxw
# WBk8fSQhXUY8EzOjBOKTAd88I7glCMA8sO/Xc4opk5h4zeDibDLm2/NbRCkgyZKN
# Sl/C8cAQrKKUtJGmKhgxBwh2ZH3NiWjwb6TtV/h4ZsTHoYIW+zCCFvcGCisGAQQB
# gjcDAwExghbnMIIW4wYJKoZIhvcNAQcCoIIW1DCCFtACAQMxDzANBglghkgBZQME
# AgEFADCCAU8GCyqGSIb3DQEJEAEEoIIBPgSCATowggE2AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEILXORth0LZX7kMs68hQud/jQPBpxSK7wjil7qK68
# bqybAgZiFmyQ0K0YETIwMjIwMjI1MTM1MDUwLjFaMASAAgH0oIHQpIHNMIHKMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNy
# b3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
# TjoxMkJDLUUzQUUtNzRFQjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZaCCEVQwggcMMIIE9KADAgECAhMzAAABoQGFVZm5VF2KAAEAAAGhMA0G
# CSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIx
# MTIwMjE5MDUyNFoXDTIzMDIyODE5MDUyNFowgcoxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
# ZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjEyQkMtRTNBRS03NEVC
# MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA2sk8XuVrpJK2McVbhy2FvQRFgg/ZJI55
# x7DisBnXSD22ZS2PpeaLywzX/gRDECgGUCNw1/dZdcgg7j/V+7TjwuPGURlwP23/
# apdBSueN/ICJe3FedvF3hDhcHPwPlGyFH1tvejpoPGetsWkL946xuFP6a4gKxf3q
# 9VANRzbiBlMqo5coIkj8CtjZxQKYtSQ/lHn+XOO5Ie6VtSo+0Z3IaRXmPTHpD0EY
# mu3BGlGFOLKgoiVXQyaXny7z0/RHbYZUMe+ZXcfgMGX9mvU+7kEUgYfLacT3SAw5
# ColjMIyk6wGNPQNyP44naj7nPD71/rKsasmRDdoeBgNBHY5pOuJ5CLpACtfCuZwC
# wyzvUjE8aQMECB0Q7WXkwpbwDwhKMtb7Tw+3/nqh6krbrvlwpH0Y1xKV/fofX67A
# dPwYA+QgX9xCywGvE3nzHx2VhCUUzza21zCos0q1EpFb/9xz/2bCacGs+TMtkW8n
# NwIfW0++ngSZMn0+RTfb/ykNB58YUTLOhx4U5jcfi87WHIvrx39A90B9Xgo2VmUY
# 6dZjssaT1NpgzBuoHpbybHtSc0QA6O2CKJPydwnG5vDGwW5vOYqIBZbRR3nBxRBc
# K7AxgRZzWBzIXG2q0DQPoGNntpfXwJF9zIyO1JJZKM++Pz+iiKnuY3HfRTwm20m2
# B/Ti7LXnmDkCAwEAAaOCATYwggEyMB0GA1UdDgQWBBQWvyAy22OO+VUMiomUsOO5
# dP3MqTAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBW
# MFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNy
# b3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUH
# AQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEp
# LmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3
# DQEBCwUAA4ICAQAgwyMRJX15RuWCnCqyz0kvn9yVmaa8ChIgEr4r2h0wUZV7QLPk
# 5GnXLBHovvcOb5hebQlM0x+HNJwiO22cZ7C/kul7IjrN2dVeFl/iMKF1CeMy77NP
# pk+L4xg7WHykP27JiSmq9nPfZv3x79Vptgk3Mmnj74vOiYd1Mi43USC1m7c7OKCJ
# hTMMCm8x3T6KcawYYIvgtWGbIaLFi5YM8rsY1JfqjYNZudjCZn9dZaCOw/RyaGkM
# 3fq3/dvGPK71C5oNofxudKPg9FCdRWv3CSWh3wd7HysPV+hq7V2Bo5jN/oPgIWlb
# H7qSlzbThbubZyyrwB+TiIxA2FdWCppV7gboW2GrLMoDxTJjYBtgJ5N3axHA3GYQ
# l16qUbMzaNRehruSQqUGV2ziTPVHuT5SSrZiJgGCBrMPqZx8v6+YIEmDqeIOWdaF
# PRoVQjN1dE/WnXnujlFwZNaxOHWXP1LD5Y9KqIpYy/pTdQOYJJps+5ObSDm1Rge3
# SXc/CdBcF0ROamLtQHb2rlW2cBkJC9cfGiv7L4xEFtDVMidvc5wx4l5eby6EU44x
# abIVAYtviGPpjamy5o9uI+Xk/m4w5RNx5jbSz6S3DA2KmdR/ulOmJmojZmnNo0Vw
# wGnhBP7qAzLdnQK3yT+zPjA7988zTUyDXrjRLQ1YJvc8H4CFAl5w2blbYjCCB3Ew
# ggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1p
# Y3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkz
# MDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5
# osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVri
# fkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFEx
# N6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S
# /rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3j
# tIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKy
# zbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX78
# 2Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjt
# p+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2
# AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb
# 3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PAPBXbGjfHCBUYP3ir
# Rbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUB
# BAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYD
# VR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGC
# N0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZ
# BgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/
# BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8E
# TzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
# dWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBM
# MEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRz
# L01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEA
# nVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx8
# 0HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ
# 7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2
# KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZ
# QhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa
# 2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2dY3RILLFORy3BFARx
# v2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRr
# akURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6T
# vsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4
# JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6
# ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggLLMIICNAIBATCB+KGB
# 0KSBzTCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMG
# A1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhh
# bGVzIFRTUyBFU046MTJCQy1FM0FFLTc0RUIxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVABtxdozuCxDFS8IChl3W
# DDeBQYDgoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJ
# KoZIhvcNAQEFBQACBQDlwuVAMCIYDzIwMjIwMjI1MTMxODU2WhgPMjAyMjAyMjYx
# MzE4NTZaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOXC5UACAQAwBwIBAAICDG4w
# BwIBAAICEgYwCgIFAOXENsACAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGE
# WQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQUFAAOBgQA5
# EmuCoLDYn0u5T2wBq6Fg4QYEfgLE5bG3miEno8434VkQYR7KalH1VwxdGn6Eakym
# OvYTEYQNYEJkHcS+NySuX2qIVoEQNXSbEqGkz+vAP8Oh2tevlqs5FZc/l7P5pe+N
# KTwxz7tFkNk+wtn9xBMnDrbjJhruRL/K/MIoO+7AxDGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABoQGFVZm5VF2KAAEAAAGh
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIMPOcZGByxwjbtKEB2XbQFlQ3T5+CfCTYICRX/4ae6UQ
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg6whU8TqBgmgggo6EcgXtSUkK
# zCXggk8hK84oid+O0IQwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAaEBhVWZuVRdigABAAABoTAiBCChooRdFVeXqSdu4cjKhhOx40uG
# Ol2vWnr8KTcFNTUmuDANBgkqhkiG9w0BAQsFAASCAgAWwqhxTKQNHo/9Jcvwa/rM
# 41UxvKKueocFkWhS7leTpdyiQ43XcV/6KybKh/8jY1nEtqjaQ5QAAcxpTIhJo57q
# oqqOj0Ho/zVV/D/s4y/qw8KpgZRpkHib9tadgUtmi44jmzWO2mPefazSlENCmnLd
# 6yzvJ0eIhd7lo0snekN8hpT+QLKpixnBXI+SIHYxsjg4rzusMXxIzIeKnSSlA/Ke
# ghACWYDBa3b+vuwK4nsTJf3HfFQ5UQ6YvVptitFtNvMuaY67tJ0mNT6td1TfsGbn
# TjR5AvlBmS2AQRTxJ4UcUZ93aI4JSbT3YsDAtGnGr21SkbwsH5W0bul/zDaYhsEG
# XdXN8uwXNPP0Mc17oDtCuDzVv8/Afbx32nojqetHT9/v5xKLWys2lK6W1NE9Is+Y
# XS5vB1p2oSimAc2HEm/Fj38iyNNLxA5rLl40vjMhOjmmRQ9uCI1INiqhs+FPyHk2
# zLEz8Zja5nTe1YJPSqZIkZ0U3/hgWqx8wpbTn8s0VFnudP6oJBmr2GpeWtdu91MM
# TF+MjSWHVPj47T93ZpfsuJ+MrhowIJTl70W0csmD33HyccaU6teKVO1FpOIwC8Lr
# TJcdlKu24JzhZ0xuCH65wNcxL7K0d7UTwVbxFYTKSZcGKtHo8zYo2C3T/B1NqiZ5
# 8mvuQC7XsNxCeEsGKUDCBQ==
# SIG # End signature block
