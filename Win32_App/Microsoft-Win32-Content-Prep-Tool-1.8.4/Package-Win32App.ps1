# & "C:\Code\Win32_App\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\IntuneWinAppUtil.exe" -v
# & "C:\Code\Win32_App\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\IntuneWinAppUtil.exe" -h
# & "C:\Code\Win32_App\Microsoft-Win32-Content-Prep-Tool-1.8.4\Microsoft-Win32-Content-Prep-Tool-1.8.4\IntuneWinAppUtil.exe" -c ""



$SourceFolder = "C:\Code\PSAppDeployToolkit_v3.9.2\Toolkit"
$SetupFile = "Deploy-Application.exe"
$OutputFolder = "C:\Code\KnowBe4\Intune_Win32App_Output"
New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose