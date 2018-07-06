:: #########################################################################################
:: #   MICROSOFT LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
:: #########################################################################################
:: #   This Sample Code is provided for the purpose of illustration only and is not 
:: #   intended to be used in a production environment.
:: #
:: #   THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY 
:: #   OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED 
:: #   WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
:: #
:: #   We grant You a nonexclusive, royalty-free right to use and modify the Sample Code 
:: #   and to reproduce and distribute the object code form of the Sample Code, provided 
:: #   that You agree: 
:: #   (i)      to not use Our name, logo, or trademarks to market Your software product 
:: #            in which the Sample Code is embedded; 
:: #   (ii)     to include a valid copyright notice on Your software product in which 
:: #            the Sample Code is embedded; and 
:: #   (iii)    to indemnify, hold harmless, and defend Us and Our suppliers from and 
:: #            against any claims or lawsuits, including attorneys’ fees, that arise 
:: #            or result from the use or distribution of the Sample Code.
:: #########################################################################################
:: #########################################################################################
:: //***************************************************************************
:: //
:: // File:      RelaunchElevated_EmbeddedScripts.cmd
:: //
:: // Additional files required:  None.  Script creates required elevate.cmd and 
:: //                             elevate.vbs in %Temp% when run.
:: //
:: // Purpose:   CMD script that will “re-launch itself” elevated if it is 
:: //            not already running elevated
:: //
:: // Usage:     RelaunchElevated_EmbeddedScripts.cmd <arguments>
:: //
:: // Version:   1.4
:: //
:: // History:
:: // 1.5 2016/10/12 First Github version
:: // 1.4  2016/07/07  Finalized a long field tested version, fixes issues with url paste, now occurs in command line prompt instead.
:: //                    This script still runs on user logon by default, if used on a server you may want to adjust it to run with saved credentials.
:: // 1.0.3 (15.01.15) - URL Input is captured in dos screen since vbscript mangles it. This script seems to work now front to back.
:: // 1.0.2 (14.12.01) - Added command to save the html file since it says if ip had changed or not, might look at appending that file as well. As it stands the url still has to be put in the script manually.            
:: // 1.0.0  06/19/2010  Created initial version.
:: //
:: // ***** End Header *****
:: //***************************************************************************

@echo off
setlocal enabledelayedexpansion

set CmdDir=%~dp0
set CmdDir=%CmdDir:~0,-1%


:: ////////////////////////////////////////////////////////////////////////////
:: Check whether running elevated
:: ////////////////////////////////////////////////////////////////////////////
call :CREATE_ELEVATE_SCRIPTS

:: Check for Mandatory Label\High Mandatory Level
whoami /groups | find "S-1-16-12288" > nul
if "%errorlevel%"=="0" (
    echo Running as elevated user.  Continuing script.
) else (
    echo Not running as elevated user.
    echo Relaunching Elevated: "%~dpnx0" %*

    if exist "%Temp%\elevate.cmd" (
        set ELEVATE_COMMAND="%Temp%\elevate.cmd"
    ) else (
        set ELEVATE_COMMAND=elevate.cmd
    )

    set CARET=^^
    !ELEVATE_COMMAND! cmd /k cd /d "%~dp0" !CARET!^& call "%~dpnx0" %*
    goto :EOF
)

if exist %ELEVATE_CMD% del %ELEVATE_CMD%
if exist %ELEVATE_VBS% del %ELEVATE_VBS%


:: ////////////////////////////////////////////////////////////////////////////
:: Main script code starts here
:: ////////////////////////////////////////////////////////////////////////////
echo Arguments passed: %*
@ECHO OFF

::Change Log
ECHO Wscript.Echo Msgbox("Afraid.org DynDNS Script v1.5 (16.10.10)")>%TEMP%\~input.vbs
cscript //nologo %TEMP%\~input.vbs
DEL %TEMP%\~input.vbs

ECHO Wscript.Echo Msgbox("Enter the Direct URL string in the command prompt window after this dialog")>%TEMP%\~input.vbs
cscript //nologo %TEMP%\~input.vbs
DEL %TEMP%\~input.vbs
::Input URL
::ECHO Wscript.Echo Inputbox("Enter update URL")>%TEMP%\~input.vbs
::FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set url=%%G
::DEL %TEMP%\~input.vbs
set /p url=Paste the URL

::Input Destination
ECHO Wscript.Echo Inputbox("Enter Destination for scripts without trailing slash, no spaces please(Default: C:\Windows):")>%TEMP%\~input.vbs
FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set dest=%%G
DEL %TEMP%\~input.vbs

IF "%url%" == "" goto ERROR
IF "%dest%" == "" set dest=C:\Windows
::Remove Trailing Slash
IF %dest:~-1%==\ SET dest=%dest:~0,-1%

::Create invis.vbs
ECHO CreateObject("Wscript.Shell").Run """" ^& WScript.Arguments(0) ^& """", 6, False>%dest%\invis.vbs

:: Legacy code below
::This hides a batch within a batch
::goto skip
::%DYNDNSQ%cd %~DP0
::%DYNDNSQ%del /q wget-log
::%DYNDNSQ%del /q wgetout
::%DYNDNSQ%wget -q --no-check-certificate --output-file=wget-log --output-document=wgetout --read-timeout=0.0 --waitretry=5 --tries=400 --background %url%
:skip
::type %cmddir%\dyndnscreate.cmd | find "%%DYNDNSQ%%"| find /v "BUT NOT THIS LINE!" > %dest%\dyndns.updater.cmd

echo wget -q --no-check-certificate --output-file=wget-log --output-document=wgetout --read-timeout=0.0 --waitretry=5 --tries=400 --background %url% >> %dest%/dyndns.updater.cmd
echo %url%
pause
copy /y wget.exe %dest%
if not exist %dest%\wget.exe echo wget missing
schtasks /delete /tn afraidddns /F
schtasks /create /sc onlogon /tn afraidddns /tr "%dest%\invis.vbs %dest%\dyndns.updater.cmd"
schtasks /run /tn afraidddns
GOTO :EOF

:ERROR
ECHO Enter a URL next time
GOTO :EOF


:: ////////////////////////////////////////////////////////////////////////////
:: End of main script code here
:: ////////////////////////////////////////////////////////////////////////////
goto :EOF


:: ////////////////////////////////////////////////////////////////////////////
:: Subroutines
:: ////////////////////////////////////////////////////////////////////////////

:CREATE_ELEVATE_SCRIPTS

    set ELEVATE_CMD="%Temp%\elevate.cmd"

    echo @setlocal>%ELEVATE_CMD%
    echo @echo off>>%ELEVATE_CMD%
    echo. >>%ELEVATE_CMD%
    echo :: Pass raw command line agruments and first argument to Elevate.vbs>>%ELEVATE_CMD%
    echo :: through environment variables.>>%ELEVATE_CMD%
    echo set ELEVATE_CMDLINE=%%*>>%ELEVATE_CMD%
    echo set ELEVATE_APP=%%1>>%ELEVATE_CMD%
    echo. >>%ELEVATE_CMD%
    echo start wscript //nologo "%%~dpn0.vbs" %%*>>%ELEVATE_CMD%


    set ELEVATE_VBS="%Temp%\elevate.vbs"

    echo Set objShell ^= CreateObject^("Shell.Application"^)>%ELEVATE_VBS% 
    echo Set objWshShell ^= WScript.CreateObject^("WScript.Shell"^)>>%ELEVATE_VBS%
    echo Set objWshProcessEnv ^= objWshShell.Environment^("PROCESS"^)>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo ' Get raw command line agruments and first argument from Elevate.cmd passed>>%ELEVATE_VBS%
    echo ' in through environment variables.>>%ELEVATE_VBS%
    echo strCommandLine ^= objWshProcessEnv^("ELEVATE_CMDLINE"^)>>%ELEVATE_VBS%
    echo strApplication ^= objWshProcessEnv^("ELEVATE_APP"^)>>%ELEVATE_VBS%
    echo strArguments ^= Right^(strCommandLine, ^(Len^(strCommandLine^) - Len^(strApplication^)^)^)>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo If ^(WScript.Arguments.Count ^>^= 1^) Then>>%ELEVATE_VBS%
    echo     strFlag ^= WScript.Arguments^(0^)>>%ELEVATE_VBS%
    echo     If ^(strFlag ^= "") OR (strFlag="help") OR (strFlag="/h") OR (strFlag="\h") OR (strFlag="-h"^) _>>%ELEVATE_VBS%
    echo         OR ^(strFlag ^= "\?") OR (strFlag = "/?") OR (strFlag = "-?") OR (strFlag="h"^) _>>%ELEVATE_VBS%
    echo         OR ^(strFlag ^= "?"^) Then>>%ELEVATE_VBS%
    echo         DisplayUsage>>%ELEVATE_VBS%
    echo         WScript.Quit>>%ELEVATE_VBS%
    echo     Else>>%ELEVATE_VBS%
    echo         objShell.ShellExecute strApplication, strArguments, "", "runas">>%ELEVATE_VBS%
    echo     End If>>%ELEVATE_VBS%
    echo Else>>%ELEVATE_VBS%
    echo     DisplayUsage>>%ELEVATE_VBS%
    echo     WScript.Quit>>%ELEVATE_VBS%
    echo End If>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo Sub DisplayUsage>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo     WScript.Echo "Elevate - Elevation Command Line Tool for Windows Vista" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Purpose:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "--------" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "To launch applications that prompt for elevation (i.e. Run as Administrator)" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "from the command line, a script, or the Run box." ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Usage:   " ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate application <arguments>" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Sample usage:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate notepad ""C:\Windows\win.ini""" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate cmd /k cd ""C:\Program Files""" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate powershell -NoExit -Command Set-Location 'C:\Windows'" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Usage with scripts: When using the elevate command with scripts such as" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Windows Script Host or Windows PowerShell scripts, you should specify" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "the script host executable (i.e., wscript, cscript, powershell) as the " ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "application." ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Sample usage with scripts:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate wscript ""C:\windows\system32\slmgr.vbs"" –dli" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate powershell -NoExit -Command & 'C:\Temp\Test.ps1'" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "The elevate command consists of the following files:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate.cmd" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate.vbs" ^& vbCrLf>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo End Sub>>%ELEVATE_VBS%

goto :EOF

