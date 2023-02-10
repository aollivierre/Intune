#need to grab script from S1E02 Intune Training on YouTube


# https://www.uubyte.com/convert-iso-to-vhd.html
# https://www.powershellgallery.com/packages/Convert-WindowsImage/10.0
# https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/main/hyperv-tools/Convert-WindowsImage




#Documenetation of module switches are here
#https://github.com/MicrosoftDocs/Virtualization-Documentation/blob/main/hyperv-tools/Convert-WindowsImage/Convert-WindowsImage.psm1


#documentation of module switches are here
# https://www.powershellgallery.com/packages/Convert-WindowsImage/10.0/Content/Convert-WindowsImage.psm1


# EXAMPLE
#         Convert-WindowsImage -SourcePath D:\foo\Win7SP1.iso -Edition Ultimate -VHDPath D:\foo\Win7_Ultimate_SP1.vhd
#         This command will parse the ISO file D:\foo\Win7SP1.iso and try to locate
#         \sources\install.wim.  If that file is found, it will be used to create a
#         dynamically-expanding 40GB VHD containing the Ultimate SKU, and will be
#         named D:\foo\Win7_Ultimate_SP1.vhd



<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)


    Convert-WindowsImage : The property 'Path' cannot be found on this object. Verify that the property exists.
At line:1 char:1
+ Convert-WindowsImage -SourcePath "D:\VM\AutoPilot1\AutoPilot1\Virtual ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Convert-WindowsImage

Dismount-DiskImage : A parameter cannot be found that matches parameter name 'PassThru'.
At C:\Program Files\WindowsPowerShell\Modules\Convert-WindowsImage\10.0\Convert-WindowsImage.psm1:2401 char:77       
+ ... $DismountDiskImage = Dismount-DiskImage -ImagePath $IsoPath -PassThru
+                                                                 ~~~~~~~~~
    + CategoryInfo          : InvalidArgument: (:) [Dismount-DiskImage], ParameterBindingException
    + FullyQualifiedErrorId : NamedParameterNotFound,Dismount-DiskImage

.NOTES
    General notes


    !conclusion this does work due to error above. DO NOT WASTE YOUR TIME ON THIS
#>

$ErrorActionPreference = 'continue'

# Install-Module -Name Convert-WindowsImage



# Convert-WindowsImage -SourcePath "D:\Users\Abdullah\Downloads\Windows.iso" -VhdFormat 'VHDX' -DiskLayout 'UEFI' -Edition 'Professional' -VHDPath "D:\vm\AutoPilot1\AutoPilot1\Virtual Hard Disks\AutoPilot1.vhdx"




# Convert-WindowsImage -SourcePath "D:\VM\Windows.iso" -DiskLayout 'UEFI' -Edition 'Professional' -VHDPath "D:\VM\AutoPilot03" -Passthru


Convert-WindowsImage -SourcePath "D:\VM\Windows.iso" -DiskLayout 'UEFI' -Edition 'Professional'



Convert-WindowsImage -SourcePath "Windows.iso" -DiskLayout 'UEFI' -Edition 'Professional' -Passthru:$true


# Convert-WindowsImage -SourcePath "D:\VM\AutoPilot1\AutoPilot1\Virtual Hard Disks\Windows.iso" -DiskLayout 'UEFI' -Edition 'Professional' -VHDPath "D:\vm\AutoPilot1\AutoPilot1\Virtual Hard Disks\AutoPilot2.vhd"


# Convert-WindowsImage -SourcePath "D:\VM\AutoPilot1\AutoPilot1\Virtual Hard Disks\Windows.iso" -Edition 'Professional' -VHDPath "D:\vm\AutoPilot1\AutoPilot1\Virtual Hard Disks\AutoPilot2.vhd"



# Convert-WindowsImage -SourcePath "D:\VM\AutoPilot1\AutoPilot1\Virtual Hard Disks\Windows.iso" -DiskLayout 'UEFI' -Edition 'Professional'


# Convert-WindowsImage -SourcePath "D:\VM\AutoPilot1\AutoPilot1\Virtual Hard Disks\Windows.iso" -DiskLayout 'UEFI'






