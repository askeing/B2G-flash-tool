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

OUTPUT_FORMAT_CODE="\e[1;34m%-16s\e[1;32m%s\e[0m\n"
OUTPUT_FORMAT_DEVICE="\e[1;34m%-16s\e[1;33m%s\e[0m\n"
if [[ $NO_COLOR == "true" ]]; then
    OUTPUT_FORMAT_CODE="%-16s%s\n"
    OUTPUT_FORMAT_DEVICE="%-16s%s\n"
fi

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
while [[ $# -gt 0 ]]; do
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


if [[ 'unknown' == $(run_adb get-state) ]]; then
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
    ### unzip application.zip to get gaia info
    unzip application.zip resources/gaia_commit.txt &> /dev/null || \
    echo '#####    Unzip application.zip error.'
    if [[ -f resources/gaia_commit.txt ]]; then
        GAIA_REV=$(head -n 1 resources/gaia_commit.txt)
    fi

    ### de-optimize the ja file
    mkdir -p deoptimize
    python optimizejars.py --deoptimize ./ ./ ./deoptimize &> /dev/null || \
    echo '#####    Deoptimize omni.ja failed, please run this script with sudo.'
    ### unzip omni.ja to get gecko info
    unzip deoptimize/omni.ja chrome/toolkit/content/global/buildconfig.html &> /dev/null || \
    echo '#####    Unzip deoptimized omni.ja error.'
    if [[ -f chrome/toolkit/content/global/buildconfig.html ]]; then
        GECKO_REV=$(grep "Built from" chrome/toolkit/content/global/buildconfig.html | sed "s,.*\">,,g ; s,</a>.*,,g")
    fi

    ### get build-id and version
    BID=$(grep "^ *BuildID" application.ini | sed "s,.*=,,g")
    VER=$(grep "^ *Version" application.ini | sed "s,.*=,,g")

    ### print information
    printf ${OUTPUT_FORMAT_CODE} "Gaia-Rev" "${GAIA_REV}"
    printf ${OUTPUT_FORMAT_CODE} "Gecko-Rev" "${GECKO_REV}"
    printf ${OUTPUT_FORMAT_CODE} "Build-ID" "${BID}"
    printf ${OUTPUT_FORMAT_CODE} "Version" "${VER}"
fi

# get and print device information
PROPS=( "Device-Name:ro.product.device"
        "FW-Release:ro.build.version.release"
        "FW-Incremental:ro.build.version.incremental"
        "FW-Date:ro.build.date"
        "Bootloader:ro.boot.bootloader" )
for KEY_VALUE in "${PROPS[@]}" ; do
    KEY="${KEY_VALUE%%:*}"
    VALUE="${KEY_VALUE##*:}"
    RET=$(run_adb shell getprop $VALUE | tr -d '\r\n')
    if [[ ${RET} ]]; then
        printf ${OUTPUT_FORMAT_DEVICE} "${KEY}" "${RET}"
    fi
done

rm -rf $dir

