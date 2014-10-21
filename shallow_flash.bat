@rem ==========================================================================
@rem This Source Code Form is subject to the terms of the Mozilla Public
@rem License, v. 2.0. If a copy of the MPL was not distributed with this
@rem file, You can obtain one at http://mozilla.org/MPL/2.0/.
@rem ==========================================================================
@rem  Description:
@rem    This script runs shallow flash.sh on Windows + Cygwin.
@rem    Before use install Cygwin base package plus unzip
@rem 
@rem   Useage:
@rem 
@rem     Run in same folder as shallow_flash.sh and Gaia + Gecko archive files
@rem     It will automatically flash gaia.zip and any b2g-*.android-arm.tar.gz
@rem     ADB and fastboot can be run from the folder containing this script if
@rem     you copy ADB*.* and fastboot.exe from the Android distribution.
@rem
@rem    If Cygwin and unzip are not installed it will prompt with instructions.
@rem    Cywin setup is then run with as little interaction user as as possible 
@rem    Just select a download site and click Next twice. 
@rem 
@rem  Author: slee steve@opendirective.com
@rem  History:
@rem    2014/10/11 slee: v1.0 First release.
@rem    2014/10/20 slee: v1.1 Added Cygwin installation.
@rem ==========================================================================

@setlocal

@echo ### Finding Cygwin
@set CYGWINBIN=
@call :findCygwin
@if not "%CYGWINBIN%"=="" goto check_Gecko		

@rem Run Cygwin setup to install Base and unzip 
@if exist setup-x86.exe (
    @set SETUP=setup-x86.exe
) else if exist setup-x86_64.exe (
    @set SETUP=setup-x86_64.exe
)
@if not exist %SETUP% goto error_no_CYGWIN_SETUP

@rem Note: Setup returns immediately - ie it runs async
@rem so we can't tell if it succeeded or not from errorlevel
@rem We wait until the task ends
@echo ### Installing Cygwin
@%SETUP% -q -C Base -P unzip -g
:loop
@tasklist | find /I "%SETUP%" > :null
@if errorlevel 1 (
    @goto end_loop
) else (
    @Rem Pause a few seconds. "Timeout" is Windows 7 onwards 
    @ping 127.0.0.1 -n 3 > :null
    @goto loop
)
:end_loop

@rem Bail if still no Cywin or unzip 
@call :findCygwin
@if "%CYGWINBIN%"=="" goto error_CYGWIN_FAILED		

:check_gecko
@rem Find the Gaia and Gecko archive files 
@echo ### Checking for Gaia and Gecko files to flash
@set "GAIA=gaia.zip"
@if not exist %GAIA% goto error_no_GAIA
@set GECKO=
@set "GECKOPATTERN=b2g-*.android-arm.tar.gz"
@for %%f in (%GECKOPATTERN%) do @(
    @set "GECKO=%%f"
)
@if "%GECKO%"=="" goto error_no_GECKO

@rem Set path so Cygwin can find it's commands
@set "PATH=%CYGWINBIN%;%PATH%"

@rem Create a temp .bashrc that mounts /tmp and performs a few tests
@rem The # is to stop the Windows EOL \r breaking bash
@echo ### Preparing to flash
@set "BASHRC=%TEMP%\.bashrc"
@echo unset TMP # > %BASHRC%
@echo unset TEMP # >> %BASHRC%
@rem allow adb and fastboot to be run from the current dir.
@echo PATH="./:"$PATH # >> %BASHRC%
@echo mount "%TEMP%" /tmp ^&^> /dev/null # >> %BASHRC%
@echo $^(which adb ^&^> /dev/null^) ^|^| { printf "!!! Cannot find ADB\nEnsure it is installed or copied to the folder containing this script"; exit 1; } # >> %BASHRC%
@echo $^(which fastboot ^&^> /dev/null^) ^|^| { printf "!!! Cannot find Fastboot\nEnsure it is installed or copied to the folder containing this script"; exit 1; } # >> %BASHRC%
@for /F %%i in ('%CYGWINBIN%\cygpath "%BASHRC%"') do @(
    @set "BASH_ENV=%%i" 
)

@rem Run shallow_flash.sh
@%CYGWINBIN%\bash -- shallow_flash.sh -g%GAIA% -G%GECKO%

@goto end

@rem Subroutines -------------------------------------------------------------

@rem Find Cygwin bin
:findCygwin
@for /F "tokens=1,2*" %%i in ('reg query "HKLM\SOFTWARE\Cygwin\setup" /v "rootdir"') do @(
    @if "%%i"=="rootdir" (
        @if exist "%%k\bin\bash.exe" (
            @if exist %%k\bin\unzip.exe (
                @set "CYGWINBIN=%%k\bin"
            )
        )
    )
)
@if "%CYGWINBIN%"=="" (
    @for /F "tokens=1,2*" %%i in ('reg query "HKLM\SOFTWARE\Wow6432Node\Cygwin\setup" /v "rootdir"') do @(
        @if "%%i"=="rootdir"  (
            @if exist "%%k\bin\bash.exe" (
                @if exist %%k\bin\unzip.exe (
                    @set "CYGWINBIN=%%k\bin"
                )
            )
        )
    )
)
@exit /B 0

@rem -----------------------------------------------------------------------
:error_no_CYGWIN_SETUP
@echo !!! Cannot find Cygwin.
@echo Please download the Cygwin "setup*.exe" from https://cygwin.com/install.html
@echo and copy it to the folder containing this script.
@echo TRun this script again so it can install Cygwin.
@goto end

:error_CYGWIN_FAILED
@echo !!! Cygwin base and unzip have not been installed.
@echo Flashing cancelled.
@goto end

:error_no_GAIA
@echo !!! Cannot find the file "%GAIA%"
@echo Get one from Firefox OS nightlies and put it in same folder as this script
@goto end

:error_no_GECKO
@echo !!! Cannot find the file "%GECKOPATTERN%"
@echo Get one from Firefox OS nightlies and put it in same folder as this script
@goto end

:end
@rem pause if it looks like we were launched with a double clicked from explorer
@if %0 == "%~0"  pause
