if exist "%TEMP%\consoleSettingsBackup.reg" regedit /S "%TEMP%\consoleSettingsBackup.reg"&DEL /F /Q "%TEMP%\consoleSettingsBackup.reg"&goto :mainstart
regedit /S /e "%TEMP%\consoleSettingsBackup.reg" "HKEY_CURRENT_USER\Console"
echo REGEDIT4>"%TEMP%\disablequickedit.reg"
echo [HKEY_CURRENT_USER\Console]>>"%TEMP%\disablequickedit.reg"
(echo "QuickEdit"=dword:00000000)>>"%TEMP%\disablequickedit.reg"
regedit /S "%TEMP%\disablequickedit.reg"
DEL /F /Q "%TEMP%\disablequickedit.reg"
start "" "cmd" /c "%~dpnx0"&exit
cls
:mainstart

REM Script Version V10.0

REM Setting Global Variables
    @echo off
    SETLOCAL ENABLEEXTENSIONS

    SET me=""
    SET me=%~n0

    SET parent=""
    SET parent=%~dp0

    REM the following line helps in creating a virtual mapped network drive in order to make the script work when run from \\network_path\\Some_UNC_Path
    pushd %parent%
    cls

REM --------------------------------------------------------

REM Description of this batch file

REM --------------------------------------------------------

REM Requesting Admin elevated control
    :: BatchGotAdmin
    :-------------------------------------
    REM  --> Check for permissions
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

    REM --> If error flag set, we do not have admin.
    if '%errorlevel%' NEQ '0' (
        echo Requesting administrative privileges...
        goto UACPrompt
    ) else ( goto gotAdmin )

    :UACPrompt
        echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
        set params = %*:"=""
        echo UAC.ShellExecute "%SYSTEMROOT%\system32\cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

        "%temp%\getadmin.vbs"
        del "%temp%\getadmin.vbs"
        exit /B

    :gotAdmin
        pushd "%CD%"
        CD /D "%~dp0"
    :--------------------------------------
REM --------------------------------------------------------

@REM powershell.exe -executionpolicy bypass -file .\autopilot.ps1


@REM Exit|mkdir "C:\CCI\Scripts" & powershell.exe -command "(new-object System.Net.WebClient).DownloadFile('http://bit.ly/319UTng','c:\cci\scripts\Download-TeamViewer.ps1')"

Exit|mkdir "C:\CCI\Scripts" & powershell.exe -command "(new-object System.Net.WebClient).DownloadFile('https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?path=/Preview/Install-TeamViewer/Download-TeamViewer.ps1&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true','c:\cci\scripts\Download-TeamViewer.ps1')"


@REM Exit | powershell.exe -command (New-Object System.Net.WebClient).DownloadFile("https://dev.azure.com/CanadaComputingInc/edb7565a-620a-4960-89ae-96e7765b9202/_apis/git/repositories/4e3325c7-0dba-4f5c-9c3f-0e6b96208c22/items?path=/Preview/Install-TeamViewer/Download-TeamViewer.ps1&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true","c:\cci\scripts\Download-TeamViewer.ps1")


powershell.exe -executionpolicy bypass -file c:\cci\scripts\Download-TeamViewer.ps1




