@echo off
SETLOCAL ENABLEEXTENSIONS

SET me=""
SET me=%~n0

SET parent=""
SET parent=%~dp0

REM This policy setting lets you configure the script execution policy, controlling which scripts are allowed to run.
REM If you enable this policy setting, the scripts selected in the drop-down list are allowed to run.
REM The "Allow only signed scripts" policy setting allows scripts to execute only if they are signed by a trusted publisher.
REM The "Allow local scripts and remote signed scripts" policy setting allows any local scrips to run; scripts that originate from the Internet must be signed by a trusted publisher.
REM The "Allow all scripts" policy setting allows all scripts to run.
REM If you disable this policy setting, no scripts are allowed to run.
REM Note: This policy setting exists under both "Computer Configuration" and "User Configuration" in the Local Group Policy Editor. The "Computer Configuration" has precedence over "User Configuration."
REM If you disable or do not configure this policy setting, it reverts to a per-machine preference setting; the default if that is not configured is "No scripts allowed."


REM --add the following to the top of your bat file--
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
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

REM # Import some previously saved Local Group Policy settings:#!importing a GPO backup only imports the new changes specified in the registry.pol that you can read by parsing with LGPO.exe /parse /m $PATH_OF_GPO_POL_FILE >> $PATH_OF_GPO_PARSED_TXT
REM # LGPO.exe /g $PATH_OF_GPO_BACKUP
REM LGPO.exe /m $PATH_OF_GPO_POL_FILE

REM #re open GPO Editor to see new changes after the import of the new settings as the existing GPO Editor window does not reflect new chagnes unless re opened
REM gpedit.msc

REM The script below will set the following Policy that resides in
REM Computer Configuration -> Administrative Templates -> Windows Components -> Windows PowerShell -> Turn on Script Execution -> Enabled -> Options -> Execution Policy -> Allow all scripts (Unrestricted)

REM Computer
REM Software\Policies\Microsoft\Windows\PowerShell
REM EnableScripts
REM DWORD:1

REM Computer
REM Software\Policies\Microsoft\Windows\PowerShell
REM ExecutionPolicy
REM SZ:Unrestricted

REM SET ACTIVE_COMPUTER_NAME=""
REM SET ACTIVE_COMPUTER_NAME=%hostname.exe%
REM echo %ACTIVE_COMPUTER_NAME%

REM mkdir c:\GPO_BACKUPS

REM SET PATH_OF_GPO_BACKUP=""
REM SET PATH_OF_GPO_BACKUP=c:\GPO_BACKUPS
REM LGPO.exe /b %PATH_OF_GPO_BACKUP%

REM gpresult /h c:\GPO_BACKUPS\report.html /f

SET PATH_OF_UNRESTRICTED_GPO_POL_FILE=""
SET PATH_OF_UNRESTRICTED_GPO_POL_FILE=%parent%Unrestricted_PS_Execution_Policy.pol

REM # Import some previously saved Local Group Policy settings:#!importing a GPO backup only imports the new changes specified in the registry.pol that you can read by parsing with LGPO.exe /parse /m $PATH_OF_GPO_POL_FILE >> $PATH_OF_GPO_PARSED_TXT
LGPO.exe /m %PATH_OF_UNRESTRICTED_GPO_POL_FILE%

timeout /t 25 /nobreak

SET PATH_OF_PS1_FILE=""
SET PATH_OF_PS1_FILE=%parent%Install-TeamViewer_Hostv2.ps1
echo %PATH_OF_PS1_FILE%

cls
%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -Noprofile -File %PATH_OF_PS1_FILE%

REM echo setting policy back to restricted

REM Computer
REM Software\Policies\Microsoft\Windows\PowerShell
REM EnableScripts
REM DWORD:0

REM Computer
REM Software\Policies\Microsoft\Windows\PowerShell
REM ExecutionPolicy
REM DELETE

REM SET PATH_OF_RESTRICTED_GPO_POL_FILE=""
REM SET PATH_OF_GPO_POL_FILE=C:\Users\Abdullah\GitHub\Git-HubRepositry\Functions\Rename-Computer\backup\{3FED2DE1-F8CE-4E9A-B53D-0F45E4E4E3C8}\DomainSysvol\GPO\Machine\registry.pol
REM SET PATH_OF_RESTRICTED_GPO_POL_FILE=%parent%Restricted_PS_Execution_Policy.pol

REM # Import some previously saved Local Group Policy settings:#!importing a GPO backup only imports the new changes specified in the registry.pol that you can read by parsing with LGPO.exe /parse /m $PATH_OF_GPO_POL_FILE >> $PATH_OF_GPO_PARSED_TXT
REM LGPO.exe /m %PATH_OF_RESTRICTED_GPO_POL_FILE%

cls