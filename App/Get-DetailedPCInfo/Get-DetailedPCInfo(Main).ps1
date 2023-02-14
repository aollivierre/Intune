. "$PSScriptRoot\Get-NETTCP_ProcessName\Get-NETTCPConnection_ProcessName_V2.ps1"
. "$PSScriptRoot\Get-PCInfo.ps1"
. "$PSScriptRoot\Send-email\Send-Email.ps1"
. "$PSScriptRoot\Get-MSHotfix.ps1"
. "$PSScriptRoot\Get-RemoteProgram.ps1"

$ErrorActionPreference = 'SilentlyContinue'



$Script:SYS_ENV_SYSDIRECTORY = $null
$Script:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory


        #take input from user for the new 7 chars of the new hostname
        Write-Host '--------------------------------------------'
        Write-Host '--------------------------------------------'
        Write-Host '--------------------------------------------'
        Write-Host '--------------------------------------------'
        Write-Host 'Welcome to the Detailed PC Info Utility V 1.0.0' -ForegroundColor Green
        Write-Host '--------------------------------------------'
        Write-Host '--------------------------------------------'
        Write-Host '--------------------------------------------'
        Write-Host '--------------------------------------------'

        $Customer_Name = Read-Host -Prompt "Please enter the Customer Name i.e Contoso Fabrikam"
        $Computer_Description = Read-Host -Prompt "Please enter the computer description i.e General Manager computer"
        $User_Description = Read-Host -Prompt "Please enter the User First name (and last name if possible) i.e John Smith"
        $User_title = Read-Host -Prompt "Please enter the User position in the organization i.e Accountant"






$TargetMachineName = [System.Environment]::MachineName

$date = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")
$sitename = (Get-WmiObject -query "SELECT DESCRIPTION FROM win32_operatingsystem").DESCRIPTION
$Domainname = (Get-WmiObject -query "SELECT DOMAIN FROM win32_computersystem").DOMAIN

#Create log
$logdirname = "($Domainname)_$($sitename)_$($TargetMachineName)_$($date)"

$logdir = "c:\cci\$logdirname"
if (!(Test-Path -Path $logdir )) { 
    New-Item -Force -ItemType directory -Path $logdir
}


Write-Host 'Get-RemoteProgram' -ForegroundColor Green

Get-RemoteProgram -Property DisplayVersion, VersionMajor, Publisher | Export-Csv "c:\cci\$logdirname\installedsoftware.csv"

#CMD
Write-Host 'ipconfig' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\ipconfig.exe /all > "c:\cci\$logdirname\networkinfo.txt"
& $SYS_ENV_SYSDIRECTORY\ipconfig.exe /all > "c:\cci\networkinfo.txt"

#PowerShell

Write-Host 'Get-NetIPAddress' -ForegroundColor Green
Get-NetIPAddress | Where-Object { $_.AddressFamily -like "*IPV4*" } | Select-Object "interfacealias", "interfaceindex" , "IPaddress" | Sort-Object "interfaceindex" | Format-Table -auto > "c:\cci\$logdirname\ipnetworkinfo.txt"


Write-Host 'WMIC Serial Number' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\wbem\WMIC.exe bios get serialnumber > "c:\cci\$logdirname\serialnumberinfo.txt"

#CMD
Write-Host 'systeminfo' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\systeminfo.exe > "c:\cci\$logdirname\sysinfo.txt"

#WMIC & PowerShell
Write-Host 'Get-PCInfo' -ForegroundColor Green
Get-PCInfo -Computer $TargetMachineName -filepath "c:\cci\$logdirname\PCInfo.txt"

#PowerShell
Write-Host 'Get-ComputerInfo' -ForegroundColor Green
Get-ComputerInfo > "c:\cci\$logdirname\computerinfo.txt"


Write-Host 'net share' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\net.exe share > "c:\cci\$logdirname\networkUNCPaths_Sharedwithothers.txt"

#MappedNetworkDrives

#CMD
Write-Host 'net use' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\net.exe use > "c:\cci\$logdirname\mappednetworkdrives.txt"
#PowerShell

Write-Host 'WMI Network Connection' -ForegroundColor Green
Get-WmiObject Win32_NetworkConnection | Format-Table "RemoteName","LocalName" -A > "c:\cci\$logdirname\mappednetworkdrives_PS.txt"


#Printers

#CMD

Write-Host 'WMIC Printers' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\wbem\WMIC.exe printer list brief > "c:\cci\$logdirname\printers.txt"

#PowerShell

Write-Host 'Get-Printer' -ForegroundColor Green
Get-Printer | Select-Object * | Export-Csv -path "c:\cci\$logdirname\printers_PS_table.csv"
Get-Printer | Format-list > "c:\cci\$logdirname\printers_PS_list.txt"



#Processes

#CMD
Write-Host 'tasklist' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\tasklist.exe > "c:\cci\$logdirname\processes_cmd.txt"


#PowerShell and CIM Instance
Write-Host 'CIM_INSTANCE' -ForegroundColor Green
$System = Get-CimInstance CIM_ComputerSystem
$BIOS = Get-CimInstance CIM_BIOSElement
$OS = Get-CimInstance CIM_OperatingSystem
$CPU = Get-CimInstance CIM_Processor
$HDD = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = 'C:'"
$EXTXT = "c:\cci\$logdirname\sysinfo_summary_ps_cim_instance.txt"

"Manufacturer: " + $System.Manufacturer >> $EXTXT
"Model: " + $System.Model >> $EXTXT
"BIOS Serialnumber: " + $BIOS.SerialNumber >> $EXTXT
"CPU: " + $CPU.Name >> $EXTXT
"RAM: " + "{0:N2}" -f ($System.TotalPhysicalMemory/1GB) + "GB" >> $EXTXT
"HDD Capacity: "  + "{0:N2}" -f ($HDD.Size/1GB) + "GB" >> $EXTXT
"Operating System: " + $OS.caption >> $EXTXT


#DSREGCMD
Write-Host 'dsregcmd' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\dsregcmd.exe /status > "c:\cci\$logdirname\dsregcmd.txt"



#net user CMD
Write-Host 'net user' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\net.exe user > "c:\cci\$logdirname\localusers_cmd.txt"


#net localgroup CMD
Write-Host 'net localgroup' -ForegroundColor Green
& $SYS_ENV_SYSDIRECTORY\net.exe localgroup > "c:\cci\$logdirname\localgroups_cmd.txt"


#Local users PowerShell
Write-Host 'Local users PS' -ForegroundColor Green
Get-LocalUser  > "c:\cci\$logdirname\localusers_PS.txt"


#Local groups PowerShell
Write-Host 'Local Groups PS' -ForegroundColor Green
Get-LocalGroup  > "c:\cci\$logdirname\localgroups_PS.txt"


#Local admins group members PowerShell
Write-Host 'Local admins group members PS' -ForegroundColor Green
Get-LocalGroupmember -Name 'administrators' > "c:\cci\$logdirname\localadminsgroupmembers_PS.txt"


#Local users group members PowerShell
Write-Host 'Local users group members PS' -ForegroundColor Green
Get-LocalGroupmember -Name 'users' > "c:\cci\$logdirname\localusersgroupmembers_PS.txt"

#Local groups PowerShell
Write-Host 'Local Remote Desktop Users PS' -ForegroundColor Green
Get-LocalGroupmember -Name 'Remote Desktop Users' > "c:\cci\$logdirname\localremotedesktopusersgroupmembers_PS.txt"

#Link speed PowerShell
Write-Host 'link speed' -ForegroundColor Green
get-wmiobject Win32_NetworkAdapter | foreach-object {get-wmiobject -namespace root/WMI -class MSNdis_LinkSpeed -filter "InstanceName='$($_.Name)'"} | Select-Object InstanceName,NdisLinkSpeed,Active > "c:\cci\$logdirname\link_speed_PS.txt"

#C users profiles PowerShell
Write-Host 'c users profiles' -ForegroundColor Green
$USER_PRFOILES_PATH_MAIN = $null
$USER_PRFOILES_PATH_MAIN = 'C:\Users'
$USER_PRFOILES = $null
$USER_PRFOILES = Get-ChildItem $USER_PRFOILES_PATH_MAIN
$USER_PRFOILES > "c:\cci\$logdirname\c_users_profiles.txt"





#FQDN profiles PowerShell and .NET
$EXTXT = "c:\cci\$logdirname\FQDN.txt"
(Get-ciminstance win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain >> $EXTXT
[System.Net.Dns]::GetHostEntry([string]$env:computername).HostName >> $EXTXT
Get-CimInstance win32_computersystem | ForEach-Object { $_.Name + '.' + $_.Domain } >> $EXTXT
[System.Net.Dns]::GetHostByName((hostname)).HostName >> $EXTXT


#public IP address
(Invoke-WebRequest -uri "http://ifconfig.me/ip").Content > "c:\cci\$logdirname\PublicIP.txt"


#PowerShell
# Write-Host 'Get-Process' -ForegroundColor Green
# Get-Process | Export-Csv -path "c:\cci\$logdirname\processes_PS_table.csv"
#PowerShell
# Get-Process | Select-Object -Property Id, ProcessName, Product, Description, Path, Company, FileVersion | Format-List > "c:\cci\$logdirname\processes_PS_table.txt"
# Get-Process | Select-Object -Property Id, ProcessName, Product, Description, Path, Company, FileVersion | Format-table > "c:\cci\$logdirname\processes_PS_table.txt"

# Get-Process | Select-Object -Property Id, ProcessName, Product, Description, Path, Company, FileVersion | Export-Csv -path "c:\cci\$logdirname\processes_PS_table.csv"


# Get-Process | Export-Csv -path "c:\cci\$logdirname\processes_PS_table.csv"


#Services

#PowerShell
Write-Host 'Get-Service' -ForegroundColor Green

Get-WmiObject win32_service | Select-Object -Property Name, PathName, __RELPATH, __PATH, Caption, Description, DisplayName, Path  | Export-Csv -path "c:\cci\$logdirname\Services_WMI_PS_table.csv"
Get-Service | Export-Csv -path "c:\cci\$logdirname\Services_PS_table.csv"

# Get-Service > "c:\cci\$logdirname\Services_PS_table.txt"



#Processes with their ports

#PowerShell
Write-Host 'Get-NETTCPConnection_ProcessName' -ForegroundColor Green
Get-NETTCPConnection_ProcessName -ExportFilePath "c:\cci\$logdirname\processes_PS_Table_With_Connections.csv"


#Get-MSHotfix
Get-MSHotfix > "c:\cci\$logdirname\mshotfix.txt"


Write-Host 'Invoke-ZipFiles' -ForegroundColor Green
function Invoke-ZipFiles( $zipfilename, $sourcedir )
{
   Add-Type -Assembly System.IO.Compression.FileSystem
   $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,
        $zipfilename, $compressionLevel, $false)

}

$logspackageddir = "c:\cci\logspackaged"
if (!(Test-Path -Path $logspackageddir )) { 
    New-Item -Force -ItemType directory -Path $logspackageddir
}

Invoke-ZipFiles "c:\CCI\logspackaged\_$($TargetMachineName).zip" "C:\cci\$logdirname"


Start-Sleep -Seconds 5


Write-Host 'Send-Email' -ForegroundColor Green
$emailbody = [PSCustomObject]@{
    
    Customer_Name = $Customer_Name
    Computer_Description = $Computer_Description
    User_Description = $User_Description
    User_title = $User_title

}

$Emailto = 'Inventory@canadacomputing.ca'
$emailbody = $emailbody | Out-String

$sendEmailSplat = @{
    emailbody = $emailbody
    log = $logspackageddir
    Subject = $Computer_Description
    emailto = $Emailto
}

Send-Email @sendEmailSplat

Write-Host '--------------------------------------------'
Write-Host '--------------------------------------------'
Write-Host '--------------------------------------------'
Write-Host '--------------------------------------------'
Write-Host 'Thank you for using the Detailed PC Info Utility V 1.0.0' -ForegroundColor Green
Write-Host 'This computer details has been emailed to' $Emailto -ForegroundColor Green
Write-Host '--------------------------------------------'
Write-Host '--------------------------------------------'
Write-Host '--------------------------------------------'
Write-Host '--------------------------------------------'


$user_selection_yes_or_no_to_EXIT = Read-Host 'would you like Exit [E] ?'

        
if ($user_selection_yes_or_no_to_EXIT -eq 'e') {

    exit
}





