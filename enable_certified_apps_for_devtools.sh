#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for devtools with Certified Apps.
#   Please enable "ADB and Devtools" of your device before using App Manager.
#
# Author: Askeing fyen@mozilla.com
#
# Ref:
#   https://developer.mozilla.org/en-US/Firefox_OS/Using_the_App_Manager
#   https://developer.mozilla.org/en-US/Firefox_OS/Debugging/Developer_settings#Remote_debugging
#==========================================================================

function helper(){
    echo -e "This script was written for devtools with Certified Apps.\nPlease enable \"ADB and Devtools\" of your device before using App Manager.\n"
    echo -e "Usage: ./enable_certified_apps_for_devtools.sh [parameters]"
    echo -e "  -s <serial number>\tdirects command to device with the given serial number."
    echo -e "  -h|--help\tdisplay help."
    exit 0
}

## adb with flags
function run_adb() {
    adb $ADB_FLAGS $@
}

## adb root, then remount and stop b2g
function adb_root_remount() {
    run_adb root &&
    run_adb wait-for-device
    run_adb remount &&
    run_adb wait-for-device
    run_adb shell mount -o remount,rw /system &&
    run_adb wait-for-device
    run_adb shell stop b2g &&
    run_adb wait-for-device
}

#########################
# Processing Parameters #
#########################

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o s::h --long help \
        -n 'invalid option' -- "$@"`

        if [ $? != 0 ]; then echo "Try '--help' for more information." >&2; exit 1; fi

        eval set -- "$TEMP";;
    "Darwin");;
esac

while true
do
    case "$1" in
        -s)
            case "$2" in
                "") shift 2;;
                *) ADB_DEVICE=$2; ADB_FLAGS+="-s $2"; shift 2;;
            esac ;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) helper; echo error occured; exit 1;;
    esac
done


#########
# Start #
#########

set -e
if [[ 'unknown' == $(adb get-state) ]]; then
	echo "### Unknown device."
	exit -1
fi

adb_root_remount

## Create temp folder
TMP_DIR=$(mktemp -d -t enablecertifiedapps.XXXXXXXXXXXX)
PREFS_FILE="prefs.js"
DEFAULT_PATH=$(adb shell ls /data/b2g/mozilla/ | grep "default" | sed "s/\n//g" | sed "s/\r//g")
PREFS_PATH="/data/b2g/mozilla/${DEFAULT_PATH}/${PREFS_FILE}"

## Pull prefs.js from the device
echo "### Pull ${PREFS_FILE} from the device..."
adb pull ${PREFS_PATH} ${TMP_DIR}

## Enable Certified Apps
echo "### Enable Devtools and Certified Apps..."
echo "### change ${PREFS_FILE} ..."
echo -e "user_pref(\"devtools.debugger.forbid-certified-apps\", false);" >> ${TMP_DIR}/${PREFS_FILE}
## it doesn't work, seems like will be changed by B2G base on DB of Settings
#echo -e "user_pref(\"devtools.debugger.remote-enabled\", true);" >> ${TMP_DIR}/${PREFS_FILE}

## Push prefs.js into the device
echo "### Push ${PREFS_FILE} into the device..."

adb shell stop b2g
adb push ${TMP_DIR}/${PREFS_FILE} ${PREFS_PATH}
sleep 5
adb shell start b2g

rm -rf ${TMP_DIR}

echo "### Please enable \"ADB and Devtools\" of your device before using App Manager."
echo "### Ref:"
echo "###     https://developer.mozilla.org/en-US/Firefox_OS/Using_the_App_Manager"
echo "###     https://developer.mozilla.org/en-US/Firefox_OS/Debugging/Developer_settings#Remote_debugging"

