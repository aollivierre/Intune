# Get-Secret -Name "TeamViewer-Teams-Webhook" -AsPlainText



#or a more detailed exampled (where Get-Secret does not use the -AsPlainText which is better to avoid exposing the secret )



# Create Microsoft 365 Credential Secret
# $username = "admin@domain.onmicrosoft.com"
# $password = ConvertTo-SecureString "Pass@word1" -AsPlainText -Force
# $creds = New-Object System.Management.Automation.PSCredential($username,$password)
# # Create the secret by storing the PSCredential object
# Set-Secret -Name M365 -Secret $cred -Metadata @{Information="M365 Credentials for Tenant"}
# # Retrieve the Stored Credentials
# $m365creds = Get-Secret -Name M365Creds
# # Connect to Microsoft Online with the retrieved credentials
# Connect-MsolService -Credential $m365creds











<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


# $LoadModuleFileScriptRoot_1 = $null
# $LoadModuleFileScriptRoot_1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
#     Split-Path -Path $MyInvocation.MyCommand.Path
# }
# else {
#     $PSScriptRoot
# }

function Get-TeamViewerSecret {
    [CmdletBinding()]
    param (
        [Parameter()]
        $TeamViewerSecret
    )
        
    begin {
            
    }
        
    process {


        try {


            Get-Secret -Name "TeamViewer-Teams-Webhook"


        }
           
        <#Do this if a terminating exception happens#>


        catch [Exception] {
        
            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            # Write-Host $PSItem -ForegroundColor Red
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
                    
                    
            $ErrorMessage_3 = $_.Exception.Message
            write-host $ErrorMessage_3  -ForegroundColor Red
            Write-Output "Ran into an issue: $PSItem"
            Write-host "Ran into an issue: $PSItem" -ForegroundColor Red
            throw "Ran into an issue: $PSItem"
            throw "I am the catch"
            throw "Ran into an issue: $PSItem"
            $PSItem | Write-host -ForegroundColor
            $PSItem | Select-Object *
            $PSCmdlet.ThrowTerminatingError($PSitem)
            throw
            throw "Something went wrong"
            Write-Log $PSItem.ToString()
                


        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
            
    }
        
    end {
            
    }
}



Get-TeamViewerSecret
