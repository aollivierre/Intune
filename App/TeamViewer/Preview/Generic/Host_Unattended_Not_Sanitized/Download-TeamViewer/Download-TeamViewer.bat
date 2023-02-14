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

REM Script Version V9.0

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




@REM powershell.exe -c "(new-object System.Net.WebClient).DownloadFile('http://bit.ly/3iJFlN9','c:\cci\scripts\teamviewerclientid.ps1')"
Exit|mkdir "C:\CCI\Scripts" & powershell.exe -command "(new-object System.Net.WebClient).DownloadFile('http://bit.ly/319UTng','c:\cci\scripts\teamviewer.zip')"


@echo off
setlocal
cd /d %~dp0
Call :UnZipFile "C:\CCI\TeamViewer" "c:\cci\scripts\teamviewer.zip"
exit /b

:UnZipFile <ExtractTo> <newzipfile>
set vbs="%temp%\_.vbs"
if exist %vbs% del /f /q %vbs%
>%vbs%  echo Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% echo If NOT fso.FolderExists(%1) Then
>>%vbs% echo fso.CreateFolder(%1)
>>%vbs% echo End If
>>%vbs% echo set objShell = CreateObject("Shell.Application")
>>%vbs% echo set FilesInZip=objShell.NameSpace(%2).items
>>%vbs% echo objShell.NameSpace(%1).CopyHere(FilesInZip)
>>%vbs% echo Set fso = Nothing
>>%vbs% echo Set objShell = Nothing
call cscript.exe //B //nologo %vbs%
if exist %vbs% del /f /q %vbs%

timeout /t 20 /nobreak > NUL

call "C:\CCI\teamviewer\Install-TeamViewer\Invoke-LGPO_Unrestrictedv9.bat"

@REM visit assist.canadacomputing.ca
@REM this download a bat file
@REM user/admin run the bat file
@REM the bat file will download the latest full Install-TeamViewer zip folder/packge
@REM then it will extract the zip file to c:\cci\scripts
@REM then first it will execute Invoke-LGPO_Unrestrictedv9.bat
@REM second that file will execute the powershell script Install-TeamViewer_Hostv3.ps1 with no restrictions






