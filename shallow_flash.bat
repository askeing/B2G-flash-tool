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
@rem 
@rem  Author: slee steve@opendirective.com
@rem  History:
@rem    2014/10/11 slee: v1.0 First release.
@rem ==========================================================================

@setlocal

@rem Find Cygwin bin
@echo ### Finding Cygwin
@set CYGWINBIN=
@if "%CYGWINBIN%"=="" (
    @for /F "tokens=1,2*" %%i in ('reg query "HKLM\SOFTWARE\Cygwin\setup" /v "rootdir"') do @(
        @if "%%i"=="rootdir" (
            @if exist "%%k\bin\bash.exe" (
                @set "CYGWINBIN=%%k\bin"
            )
        )
    )
)
@for /F "tokens=1,2*" %%i in ('reg query "HKLM\SOFTWARE\Wow6432Node\Cygwin\setup" /v "rootdir"') do @(
    @if "%%i"=="rootdir"  (
        @if exist "%%k\bin\bash.exe" (
            @set "CYGWINBIN=%%k\bin"
        )
    )
)
@if "%CYGWINBIN%"=="" goto error_no_CYGWINBIN

@rem Find the gaia and gecko archive files 
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
@set "BASHRC=%TEMP%\.bashrc"
@echo unset TMP # > %BASHRC%
@echo unset TEMP # >> %BASHRC%
@rem allow adb and fastboot to be run from the current dir.
@echo PATH="./:"$PATH # >> %BASHRC%
@echo mount "%TEMP%" /tmp ^&^> /dev/null # >> %BASHRC%
@echo $^(which adb ^&^> /dev/null^) ^|^| { echo Cannot find ADB - please make sure it is installed; exit 1; } # >> %BASHRC%
@echo $^(which fastboot ^&^> /dev/null^) ^|^| { echo Cannot find Fastboot - please make sure it is installed; exit 1; } # >> %BASHRC%
@for /F %%i in ('%CYGWINBIN%\cygpath "%BASHRC%"') do @(
    @set "BASH_ENV=%%i" 
)

@rem Run shallow_flash.sh
@%CYGWINBIN%\bash -- shallow_flash.sh -g%GAIA% -G%GECKO%

@goto end

@rem -----------------------------------------------------------------------
:error_no_CYGWINBIN
@echo Cannot find Cygwin  please make sure it is installed
@echo Get it from https://cygwin.com and install the default packages + unzip
@goto end

:error_no_GAIA
@echo Cannot find the file "%GAIA%"
@echo Get one from Firefox OS nightlies and put it in same folder as this script
@goto end

:error_no_GECKO
@echo Cannot find the file "%GECKOPATTERN%"
@echo Get one from Firefox OS nightlies and put it in same folder as this script
@goto end

:end
@rem pause if it looks like we were launched with a double clicked from explorer
@if %0 == "%~0"  pause

