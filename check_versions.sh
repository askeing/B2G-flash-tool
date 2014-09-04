#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for change OTA update URL.
#
# Author: Al Tsai, Askeing Yen, Naoki Hirata, Walter Chen,
#==========================================================================

set -e

function helper(){
    echo "-s <serial number>            - directs command to the USB device or emulator with"
    echo "                                 the given serial number. Overrides ANDROID_SERIAL"
    echo "                                 environment variable."
    echo "-h | --help                   - print usage."
    exit 0
}

run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
    adb $ADB_FLAGS $@
}


# argument parsing
while [ $# -gt 0 ]; do
    case "$1" in
    "-s")
        ADB_FLAGS+="-s $2"
        shift
        ;;
    "-h"|"--help")
        helper
        exit 0
        ;;
    esac
    shift
done


if [ 'unknown' == $(run_adb get-state) ]; then
    echo "Unknown command..."
    adb devices
    exit -1
fi


if ! which mktemp > /dev/null; then
    echo "Package \"mktemp\" not found!"
    rm -rf ./checkversions_temp
    mkdir checkversions_temp
    cd checkversions_temp
    dir=`pwd`
    cd ..
else
    dir=$(mktemp -d -t checkversions.XXXXXXXXXXXX)
fi
cp optimizejars.py $dir
cd $dir 

run_adb pull /system/b2g/omni.ja &>/dev/null || echo "Error pulling gecko"
run_adb pull /data/local/webapps/settings.gaiamobile.org/application.zip &> /dev/null || \
run_adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip &> /dev/null || echo "Error pulling gaia file"
run_adb pull /system/b2g/application.ini &> /dev/null || echo "Error pulling application.ini"

if [[ -f omni.ja ]] && [[ -f application.zip ]] && [[ -f application.ini ]]; then
    # unzip application.zip to get gaia info
    unzip application.zip resources/gaia_commit.txt &> /dev/null || \
    echo '#####    Unzip application.zip error.'
    if [[ -f resources/gaia_commit.txt ]]; then
        echo 'Gaia     ' $(head -n 1 resources/gaia_commit.txt)
        # echo '  B-D    ' $(date --date=@$(cat resources/gaia_commit.txt | sed -n 2p) +"%Y-%m-%d %H:%M:%S")
    fi

    # de-optimize the ja file
    mkdir -p deoptimize
    python optimizejars.py --deoptimize ./ ./ ./deoptimize &> /dev/null || \
    echo '#####    Deoptimize omni.ja failed, please run this script with sudo.'
    # unzip omni.ja to get gecko info
    unzip deoptimize/omni.ja chrome/toolkit/content/global/buildconfig.html &> /dev/null || \
    echo '#####    Unzip deoptimized omni.ja error.'
    if [[ -f chrome/toolkit/content/global/buildconfig.html ]]; then
        echo 'Gecko    ' $(grep "Built from" chrome/toolkit/content/global/buildconfig.html | sed "s,.*\">,,g ; s,</a>.*,,g")
    fi

    # get BuildID from application.ini
    for i in BuildID Version ; do
        echo $i ' ' $(grep "^ *$i" application.ini | sed "s,.*=,,g")
    done
fi

# get OEM build info
for KEY in ro.build.date ro.bootloader ro.build.version.incremental ; do
    if [[ $(run_adb shell getprop $KEY) ]]; then
        echo $KEY ' ' $(run_adb shell getprop $KEY)
    fi
done

rm -rf $dir

