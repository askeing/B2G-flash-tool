@ECHO OFF

:: This Source Code Form is subject to the terms of the Mozilla Public
:: License, v. 2.0. If a copy of the MPL was not distributed with this
:: file, You can obtain one at http://mozilla.org/MPL/2.0/.

:: Print Usage
IF "%1"=="-h" GOTO:HELPER
IF "%1"=="--help" GOTO:HELPER 

:: Check adb and python
@where adb > nul
if errorlevel 1 (
   echo Can not find "adb" command
   echo please install adb, and add the path to environment.
   pause
   exit /b %errorlevel%
)
@where python > nul
if errorlevel 1 (
   echo Can not find "python" command
   echo please install python, and add the path to environment.
   pause
   exit /b %errorlevel%
)

:: Get Date as temp folder name
set MY_DATE=%DATE:/=_%
set TEMP_DIR=%MY_DATE:~0,10%

:: Clean temp folder
echo Clean temp folder: %TEMP_DIR% ...
@rmdir %TEMP_DIR% /s

:: Create temp folder
echo Create temp folder: %TEMP_DIR% ...
@mkdir %TEMP_DIR% > nul

:: Copy optimizejars.py into temp folder
@copy optimizejars.py %TEMP_DIR% > nul

:: Go into temp folder as workspace
@cd %TEMP_DIR%

@adb pull /system/b2g/omni.ja 1> nul 2>&1 || echo Error pulling gecko
@adb pull /data/local/webapps/settings.gaiamobile.org/application.zip 1> nul 2>&1 || @adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip 1> nul 2>&1 || echo Error pulling gaia file
@adb pull /system/b2g/application.ini 1> nul 2>&1 || echo Error pulling application.ini

@python optimizejars.py --deoptimize ./ ./ ./ > nul
@if EXIST application.zip @..\7za920\7za.exe e application.zip resources/gaia_commit.txt > nul && more gaia_commit.txt > gaia_out && set /P GAIA_REV= < gaia_out
@if EXIST omni.ja @..\7za920\7za.exe e omni.ja chrome/toolkit/content/global/buildconfig.html > nul && findstr /i /c:"Built from" buildconfig.html | @cscript ..\parse_gecko.vbs | more +3 > gecko_out
@if EXIST gecko_out set /P GECKO_REV= < gecko_out
del buildconfig.html

echo =====
echo Gaia=%GAIA_REV%
echo Gecko=%GECKO_REV%
if EXIST application.ini findstr "^BuildID ^Version" application.ini
echo =====
pause

:: Clean temp folder
cd ..
echo Clean temp folder: %TEMP_DIR% ...
@rmdir %TEMP_DIR% > nul
GOTO:END


:HELPER
    echo -h --help        - print usage.
GOTO:END

:END

@ECHO ON
