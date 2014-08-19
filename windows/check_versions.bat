@ECHO OFF

:: This Source Code Form is subject to the terms of the Mozilla Public
:: License, v. 2.0. If a copy of the MPL was not distributed with this
:: file, You can obtain one at http://mozilla.org/MPL/2.0/.

:: Print Usage
IF "%1"=="-h" GOTO:HELPER
IF "%1"=="--help" GOTO:HELPER 

:: Get Date as temp folder name
set MY_DATE=%DATE:/=_%
set TEMP_DIR=%MY_DATE:~0,10%

:: Clean temp folder
echo Clean %TEMP_DIR% ...
@rmdir %TEMP_DIR% /s

:: Create temp folder
echo Create %TEMP_DIR% ...
@mkdir %TEMP_DIR%

:: Copy optimizejars.py into temp folder
@copy optimizejars.py %TEMP_DIR%

:: Go into temp folder as workspace
@cd %TEMP_DIR%

@adb pull /system/b2g/omni.ja || echo Error pulling gecko
@adb pull /data/local/webapps/settings.gaiamobile.org/application.zip || @adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip || echo Error pulling gaia file
@adb pull /system/b2g/application.ini || echo Error pulling application.ini

echo =====

::python optimizejars.py --deoptimize ./ ./ ./ 	
@if EXIST application.zip ..\7za920\7za.exe e application.zip resources/gaia_commit.txt > nul && more gaia_commit.txt > gaia_out && set /P GAIA_REV= < gaia_out
echo Gaia=%GAIA_REV%
@if EXIST omni.ja ..\7za920\7za.exe e omni.ja chrome/toolkit/content/global/buildconfig.html > nul && findstr /i /c:"Built from" buildconfig.html | @cscript ..\parse_gecko.vbs | more +3 > gecko_out && set /P GECKO_REV= < gecko_out
echo Gecko=%GECKO_REV%

if EXIST application.ini findstr "^BuildID ^Version" application.ini

:: Clean temp folder
cd ..
echo =====
echo Clean %TEMP_DIR% ...
rmdir %TEMP_DIR% /s

GOTO:END


:HELPER
    echo -h --help        - print usage.
GOTO:END

:END

@ECHO ON