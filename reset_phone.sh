#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for reset the Firefox OS phone.
#
# Author: Askeing fyen@mozilla.com
#
# History:
#   2014/02/27 Askeing: v1.0 First release.
#==========================================================================


####################
# Functions        #
####################

## Show usage
function helper(){
    echo -e "This script was written to reset the Firefox OS phone.\n"
    echo -e "Usage: ./reset_phone.sh [parameters]"
    echo -e "  -s <serial number>\tdirects command to device with the given serial number."
    echo -e "  -h|--help\tdisplay help."
    exit 0
}

## adb with flags
function run_adb() {
    adb $ADB_FLAGS $@
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


###################
# Run Reset Phone #
###################

echo "### Starting to Reset Firefox OS Phone..."
run_adb shell rm -r /cache/*
run_adb shell mkdir /cache/recovery > /dev/null
run_adb shell 'echo "--wipe_data" > /cache/recovery/command' &&
run_adb reboot recovery
echo "### Reset of Firefox OS Phone done."

