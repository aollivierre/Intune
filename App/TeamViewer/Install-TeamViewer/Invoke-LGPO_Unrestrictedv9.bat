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

    REM This policy setting lets you configure the script execution policy, controlling which scripts are allowed to run.
    REM If you enable this policy setting, the scripts selected in the drop-down list are allowed to run.
    REM The "Allow only signed scripts" policy setting allows scripts to execute only if they are signed by a trusted publisher.
    REM The "Allow local scripts and remote signed scripts" policy setting allows any local scrips to run; scripts that originate from the Internet must be signed by a trusted publisher.
    REM The "Allow all scripts" policy setting allows all scripts to run.
    REM If you disable this policy setting, no scripts are allowed to run.
    REM Note: This policy setting exists under both "Computer Configuration" and "User Configuration" in the Local Group Policy Editor. The "Computer Configuration" has precedence over "User Configuration."
    REM If you disable or do not configure this policy setting, it reverts to a per-machine preference setting; the default if that is not configured is "No scripts allowed."

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

REM Creating a UNIQUE TEMP folder for the script files
    SET TEMP_DIR=""
    SET NewGuid=""
    Set UUID_VAR=""
    SET LOGS_PATH=""

    @call :GetGuid NewGuid
    @goto :eof

    :GetGuid
    @set _guid=%computername%%date%%time%
    @set _guid=%_guid:/=%
    @set _guid=%_guid:.=%
    @set _guid=%_guid: =%
    @set _guid=%_guid:,=%
    @set _guid=%_guid::=%
    @set _guid=%_guid:-=%
    @set %1=%_guid%

    for /f %%i in ('%parent%uuidgen.exe') do set UUID_VAR=%%i

    SET TEMP_DIR=%TEMP%\%NewGuid%\%UUID_VAR%.tmp

    SET LOGS_PATH=%TEMP_DIR%\logs

    SET TEMP_DIR_PARENT=""
    SET TEMP_DIR_PARENT=%TEMP%\%NewGuid%

    RMDIR %TEMP_DIR% /S /Q
    RMDIR %TEMP_DIR_PARENT% /S /Q

    REM RMDIR
        REM a command which will remove an empty directory
        REM RMDIR is a synonym for RD
        
        REM %TEMP_DIR%
            REM Pathname

        REM /S
            REM Delete all files and subfolders
            REM in addition to the folder itself.
            REM Use this to remove an entire folder tree.
        
        REM /Q
            REM Quiet - do not display Y/N confirmation

    MD %TEMP_DIR%
    MD %LOGS_PATH%

REM --------------------------------------------------------

REM Copying Script files to the UNIQUE Temp Folder
    cls
    Echo Copying Files, Please Wait.
    %systemroot%\system32\xcopy.exe ".\*" %TEMP_DIR% /k /e /d /y > Nul
    c:

    cd %TEMP_DIR%
    cls


    REM ".\*"
        REM Source
            REM Specifies the file(s) to copy.
            REM Means current path where the script is running from

    REM C:\Temp
        REM Destination
            REM Specifies the location and/or name of new files.

    REM /K
        REM  Copies attributes. Normal Xcopy will reset read-only attributes.

    REM /E           
        REM Copies directories and subdirectories, including empty ones.
        REM    Same as /S /E. May be used to modify /T.


    REM /D:m-d-y
        REM Copies files changed on or after the specified date.
        REM If no date is given, copies only those files whose
        REM source time is newer than the destination time.

    REM /Y
        REM Suppresses prompting to confirm you want to overwrite an
        REM existing destination file.

REM --------------------------------------------------------

REM # Import some previously saved Local Group Policy settings

    cls

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

    SET PATH_OF_UNRESTRICTED_GPO_POL_FILE=""
    SET PATH_OF_UNRESTRICTED_GPO_POL_FILE=%TEMP_DIR%\Unrestricted_PS_Execution_Policy.pol

    REM !importing a GPO backup only imports the new changes specified in the registry.pol that you can read by parsing with LGPO.exe /parse /m $PATH_OF_GPO_POL_FILE >> $PATH_OF_GPO_PARSED_TXT
        cls

        %TEMP_DIR%\LGPO.exe /m %PATH_OF_UNRESTRICTED_GPO_POL_FILE%
        cls
        echo turning on policy via LGPO...
        echo ENABLING POLICY AND SETTING IT TO UNRESTRICTED...

        timeout /t 20 /nobreak > NUL

REM --------------------------------------------------------

REM CHECK IF THE POLICY REG VALUES WERE SET PROPERLY BY LGPO.EXE
    REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" /v "Enablescripts" | Find "0x0"

    REM "0X0" = DISABLED
    REM "0X1" = ENABLED

    REM SET EXECUTION POLICY TO UNRESTRICTED
    REM IF ERROR FLAG IS NOT SET (EQ 0) it means the EXECUTION OF SCRIPTS IS DISABLED
    If %ERRORLEVEL% == 0 goto REGturnon
    goto QUERYExecutionPolicy
    :REGturnon
        echo turning on policy via REG...
        echo ENABLING POLICY AND SETTING IT TO UNRESTRICTED
        REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" /v Enablescripts /t REG_DWORD /f /D 1
        REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" /v ExecutionPolicy /t REG_SZ /f /D Unrestricted

        REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" /v "Enablescripts" | Find "0x0"
        If %ERRORLEVEL% == 0 goto REGturnon
        goto QUERYExecutionPolicy

REM --------------------------------------------------------

REM CHECK IF THE ExecutionPolicy in REG is Found or not
    :QUERYExecutionPolicy
        REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" /v "ExecutionPolicy" | Find "Unrestricted"
        If %ERRORLEVEL% == 1 goto REGturnon
        goto RUNPS1FILE


REM --------------------------------------------------------

REM START EXECUTING THE PS1 FILE
    :RUNPS1FILE
        SET NAME_OF_PS1_FILE=""
        for /f %%G in ('dir *.ps1 /b') do set NAME_OF_PS1_FILE=%%~G


        REM /b
            REM Using the /b switch with the DIR command strips away all excess information, displaying only the name of the folders and files in the current directory and not attributes like file size and time stamps.

        SET PATH_OF_PS1_FILE=""
        SET PATH_OF_PS1_FILE=%TEMP_DIR%\%NAME_OF_PS1_FILE%

        cls


        %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -Noprofile -File %PATH_OF_PS1_FILE%
goto Quit
REM --------------------------------------------------------

REM Removes Pushd directories and removes temp folders

    popd %parent%

        REM Changes the current directory to the directory that was most recently stored by the pushd command.
        REM the popd command removes any drive-letter assignations created by pushd

    REM RMDIR %TEMP_DIR% /S /Q
    REM RMDIR %TEMP_DIR_PARENT% /S /Q
REM --------------------------------------------------------

:Quit
exit
@goto :eof