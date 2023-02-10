$c = "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.3\setup\companyportal"
$s = "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.3\setup\companyportal\Microsoft.CompanyPortal_2022.409.807.0_neutral___8wekyb3d8bbwe.AppxBundle"
$o = "D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.3\output"



$options_1 = @(
    "-c=$c"
    "-s=$s"
    "-o=$o"
)

$cmdArgs_1 = @(
    $options_1
)

& D:\Code\Intune\Intune\Microsoft-Win32-Content-Prep-Tool-1.8.3\IntuneWinAppUtil.exe @cmdArgs_1