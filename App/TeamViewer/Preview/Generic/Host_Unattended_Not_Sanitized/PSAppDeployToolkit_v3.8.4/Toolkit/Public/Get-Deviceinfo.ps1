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



function get-deviceinfo {
    [CmdletBinding()]
    param (
        
    )
    
    begin {

        $PCInfo_OBJECT_ARRAY = $null
        
    }
    
    process {

        try {
            

            #Hostname/FQDN
            $Hostname = [System.Environment]::MachineName

            #FQDN
            $FQDN = (Get-ciminstance win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain 

            #Private IP
            $PrivateIP = ((ipconfig | findstr [0-9].\.)[0]).Split()[-1]

            #public IP
            $PublicIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

            #OS
            $OS = (Get-WmiObject Win32_OperatingSystem).version


            #Serial number
            $SerialNumber = (Get-WmiObject -ClassName win32_bios).serialnumber

            # $DBG
            #Model
            $Manufacturer = (Get-WmiObject -ClassName Win32_ComputerSystem).Manufacturer

            #Manufacturer
            $Model = (Get-WmiObject -ClassName Win32_ComputerSystem).model


            #User
            $User = whoami.exe



            $Hostname = $Hostname | Out-String
            $FQDN = $FQDN | Out-String
            $PrivateIP = $PrivateIP | Out-String
            $publicIP = $publicIP | Out-String
            $OS = $OS | Out-String
            $SerialNumber = $SerialNumber | Out-String
            $Manufacturer = $Manufacturer | Out-String
            $Model = $Model | Out-String
            $User = $User | Out-String
            
            $PCInfo_OBJECT_ARRAY = [PSCustomObject]@{
          
                Hostname     = "$Hostname"
                FQDN         = "$FQDN"
                PrivateIP    = "$PrivateIP"
                PublicIP     = "$publicIP"
                OS           = "$OS"
                SerialNumber = "$SerialNumber"
                Manufacturer = "$Manufacturer"
                Model        = "$Model"
                User         = "$User"
        
            }


        }
   
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


        return  $PCInfo_OBJECT_ARRAY
        
    }
}



# get-deviceinfo

