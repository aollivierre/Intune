# C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4>IntuneWinAppUtil.exe -c "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup" -s "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\TeamViewer_Setup_x64.exe" -o "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\output"
# INFO   Validating parameters
# INFO   Validated parameters within 38 milliseconds
# INFO   Compressing the source folder 'C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup' to 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\IntunePackage.intunewin'
# INFO   Calculated size for folder 'C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup' is 35963456 within 1 milliseconds
# INFO   Compressed folder 'C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup' successfully within 982 milliseconds
# INFO   Checking file type
# INFO   Checked file type within 15 milliseconds
# INFO   Encrypting file 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\IntunePackage.intunewin'
# INFO   'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\IntunePackage.intunewin' has been encrypted successfully within 158 milliseconds
# INFO   Computing SHA256 hash for C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\8c512259-3195-4901-b4a8-d256f8a8d0ab
# INFO   Computed SHA256 hash for 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\8c512259-3195-4901-b4a8-d256f8a8d0ab' within 299 milliseconds
# INFO   Computing SHA256 hash for C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\IntunePackage.intunewin
# INFO   Computed SHA256 hash for C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\IntunePackage.intunewin within 290 milliseconds
# INFO   Copying encrypted file from 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\8c512259-3195-4901-b4a8-d256f8a8d0ab' to 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\IntunePackage.intunewin'
# INFO   File 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Contents\IntunePackage.intunewin' got updated successfully within 57 milliseconds
# INFO   Generating detection XML file 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage\Metadata\Detection.xml'
# INFO   Generated detection XML file within 27 milliseconds
# INFO   Compressing folder 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage' to 'C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\output\TeamViewer_Setup_x64.intunewin'
# INFO   Calculated size for folder 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage' is 35429194 within 0 milliseconds
# INFO   Compressed folder 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\e282f081-b90f-4400-bb0b-6421efccd209\IntuneWinPackage' successfully within 281 milliseconds
# INFO   Removing temporary files
# INFO   Removed temporary files within 5 milliseconds
# INFO   File 'C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\output\TeamViewer_Setup_x64.intunewin' has been generated successfully


# [=================================================]   100%                                                              INFO   Done!!!






$c = "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup"
$s = "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\TeamViewer_Setup_x64.exe"
$o = "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\output"


IntuneWinAppUtil.exe -c $c -s $s -o $o

# IntuneWinAppUtil.exe -c "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup" -s "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\TeamViewer_Setup_x64.exe" -o "C:\Users\Abdullah.Ollivierre\OneDrive\Users\Abdullah\Downloads3\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\output"




$c = "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\FGCHealth_Corp"
$s = "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\FGCHealth_Corp\AgentSetup_FGC_Corporate.exe"
$o = "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\output"



$options_1 = @(
    "-c=$c"
    "-s=$s"
    "-o=$o"
    # '-a'
)

$cmdArgs_1 = @(
    $options_1
)

& D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\IntuneWinAppUtil.exe @cmdArgs_1

# D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\IntuneWinAppUtil.exe -c $c -s $s -o $o -a






D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\IntuneWinAppUtil.exe -c "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\companyportal" -s "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\companyportal\Microsoft.CompanyPortal_2022.409.807.0_neutral___8wekyb3d8bbwe.AppxBundle" -o "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\output"

# INFO   Validating parameters
# INFO   Validated parameters within 4 milliseconds
# INFO   Compressing the source folder 'D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\companyportal' to 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\IntunePackage.intunewin'
# INFO   Calculated size for folder 'D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\companyportal' is 89706905 within 0 milliseconds
# INFO   Compressed folder 'D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\setup\companyportal' successfully within 1821 milliseconds
# INFO   Checking file type
# INFO   Checked file type within 3 milliseconds
# INFO   Encrypting file 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\IntunePackage.intunewin'
# INFO   'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\IntunePackage.intunewin' has been encrypted successfully within 187 millisecondsINFO   Computing SHA256 hash for C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\a676798b-6050-4e5a-bc60-3213dc85f5a9
# INFO   Computed SHA256 hash for 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\a676798b-6050-4e5a-bc60-3213dc85f5a9' within 413 milliseconds
# INFO   Computing SHA256 hash for C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\IntunePackage.intunewin
# INFO   Computed SHA256 hash for C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\IntunePackage.intunewin within 407 milliseconds
# INFO   Copying encrypted file from 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\a676798b-6050-4e5a-bc60-3213dc85f5a9' to 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\IntunePackage.intunewin'
# INFO   File 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Contents\IntunePackage.intunewin' got updated successfully within 96 milliseconds   
# INFO   Generating detection XML file 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage\Metadata\Detection.xml'
# INFO   Generated detection XML file within 12 milliseconds
# INFO   Compressing folder 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage' to 'D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\output\Microsoft.CompanyPortal_2022.409.807.0_neutral___8wekyb3d8bbwe.intunewin'
# INFO   Calculated size for folder 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage' is 88281964 within 0 milliseconds
# INFO   Compressed folder 'C:\Users\Abdullah.Ollivierre\AppData\Local\Temp\7d7330c6-841b-4692-8157-d38fe3f040b0\IntuneWinPackage' successfully within 312 milliseconds
# INFO   Removing temporary files
# INFO   Removed temporary files within 5 milliseconds
# INFO   File 'D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\output\Microsoft.CompanyPortal_2022.409.807.0_neutral___8wekyb3d8bbwe.intunewin' has been generated successfully


# [=================================================]   100%  
# INFO   Done!!!


# Version 1.8.4.0
# Sample commands to use the Microsoft Intune App Wrapping Tool for Windows Classic Application:

# IntuneWinAppUtil -v
#   This will show the tool version.
# IntuneWinAppUtil -h
#   This will show usage information for the tool.
# IntuneWinAppUtil -c <source_folder> -s <source_setup_file> -o <output_folder> <-a> <catalog_folder> <-q>
#   This will generate the .intunewin file from the specified source folder and setup file.
#   For MSI setup file, this tool will retrieve required information for Intune.
#   If -a is specified, all catalog files in that folder will be bundled into the .intunewin file.
#   If -q is specified, it will be in quiet mode. If the output file already exists, it will be overwritten.
#   Also if the output folder does not exist, it will be created automatically.
# IntuneWinAppUtil
#   If no parameter is specified, this tool will guide you to input the required parameters step by step.



D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\IntuneWinAppUtil.exe -c "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\FGCHealth_Corp" -s "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\Setup\DattoRMM\FGCHealth_Corp\AgentSetup_FGC_Corporate.exe" -o "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.4\output"