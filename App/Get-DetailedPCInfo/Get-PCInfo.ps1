<#
.SYNOPSIS
  Name: Get-PCInfo.ps1
  The purpose of this script is to retrieve basic information of a PC.
  
.DESCRIPTION
  This is a simple script to retrieve basic information of domain joined computers.
  It will gather hardware specifications and Operating System and present them on the screen.

.RELATED LINKS
  https://www.sconstantinou.com

.PARAMETER Computer
  This is the only parameter that is needed to provide the name of the computer either
  in as computer name or DNS name.

.NOTES
    Updated: 08-02-2018        Testing the connection before the information gathering.
    Release Date: 05-02-2018
   
  Author: Stephanos Constantinou

.EXAMPLE
  Run the Get-PCInfo script to retrievw the information.
  Get-PCInfo.ps1 -Computer test-pc
#>

function Get-PCInfo {


  Param(

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $computer,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $filepath
  )

  $Connection = Test-Connection $Computer -Count 1 -Quiet

  if ($Connection -eq "True") {

    $ComputerHW = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer | Select-Object Manufacturer, Model | Format-Table -AutoSize

    $ComputerCPU = Get-WmiObject win32_processor -ComputerName $Computer | Select-Object DeviceID, Name | Format-Table -AutoSize

    $ComputerRam_Total = Get-WmiObject Win32_PhysicalMemoryArray -ComputerName $Computer | Select-Object MemoryDevices, MaxCapacity | Format-Table -AutoSize

    $ComputerRAM = Get-WmiObject Win32_PhysicalMemory -ComputerName $Computer | Select-Object DeviceLocator, Manufacturer, PartNumber, Capacity, Speed | Format-Table -AutoSize

    $ComputerDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $Computer | Select-Object DeviceID, VolumeName, Size, FreeSpace | Format-Table -AutoSize

    $ComputerOS = (Get-WmiObject Win32_OperatingSystem -ComputerName $Computer).Version

    $ComputerMotherBoard = Get-WmiObject win32_baseboard
    
    $ComputerBIOS = Get-WmiObject Win32_Bios

    switch -Wildcard ($ComputerOS) {
      "6.1.7600" { $OS = "Windows 7"; break }
      "6.1.7601" { $OS = "Windows 7 SP1"; break }
      "6.2.9200" { $OS = "Windows 8"; break }
      "6.3.9600" { $OS = "Windows 8.1"; break }
      "10.0.*" { $OS = "Windows 10"; break }
      default { $OS = "Unknown Operating System"; break }
    }

    # Write-Host "Computer Name: $Computer"
    # Write-Host "Operating System: $OS"
    # Write-Output $ComputerHW
    # Write-Output $ComputerCPU
    # Write-Output $ComputerRam_Total
    # Write-Output $ComputerRAM
    # Write-Output $ComputerDisks


    # "Computer Name: $Computer" > c:\cci\logs\pcinfo1.txt
    # "Operating System: $OS" > c:\cci\logs\pcinfo2.txt
    # $ComputerHW > c:\cci\logs\pcinfo3.txt
    # $ComputerCPU > c:\cci\logs\pcinfo4.txt
    # $ComputerRam_Total > c:\cci\logs\pcinfo5.txt
    # $ComputerRAM > c:\cci\logs\pcinfo6.txt
    # $ComputerDisks > c:\cci\logs\pcinfo7.txt


    $ComputerHW = $ComputerHW | Out-String
    $ComputerCPU = $ComputerCPU | Out-String
    $ComputerRam_Total = $ComputerRam_Total | Out-String
    $ComputerRAM = $ComputerRAM | Out-String
    $ComputerDisks = $ComputerDisks | Out-String
    $ComputerMotherBoard = $ComputerMotherBoard | Out-String
    $ComputerBIOS = $ComputerBIOS | Out-String
    
    $PCInfo_OBJECT_ARRAY = [PSCustomObject]@{
  
      ComputerName        = "$Computer"
      ComputerOS          = "$OS"
      ComputerHW          = $ComputerHW
      ComputerCPU         = $ComputerCPU
      ComputerRam_Total   = $ComputerRam_Total
      ComputerRAM         = $ComputerRAM
      ComputerDisks       = $ComputerDisks
      ComputerMotherBoard = $ComputerMotherBoard
      ComputerBIOS        = $ComputerBIOS
    }


    # $PCInfo_OBJECT_ARRAY | export-csv "c:\cci\logs\PCInfo.csv"
    $PCInfo_OBJECT_ARRAY | Out-File $filepath

  }
  else {
    Write-Host -ForegroundColor Red @"

Computer is not reachable or does not exists.

"@
  }

  
}

#Example:

# $TargetMachineName = $null
# $TargetMachineName = [System.Environment]::MachineName

# $filepath = "c:\cci\logs\PCInfo.txt"

# Get-PCInfo -Computer $TargetMachineName -filepath $filepath

