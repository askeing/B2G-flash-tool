#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   Update the system fonts of B2G v2.1 (Bug 1032874).
#   https://bugzilla.mozilla.org/show_bug.cgi?id=1032874
#
# Author: Askeing fyen@mozilla.com
# History:
#   2014/07/07 Askeing: v1.0 First release.
#
#==========================================================================

## URL
FONTS_URL="https://people.mozilla.org/~mwu/fira-font-update.zip"

## Show usage
function helper(){
    echo -e "Update the system fonts of B2G v2.1 (Bug 1032874).\n"
    exit 0
}

## wget with flags
function run_wget() {
    wget -P $@
}


#########################
# Processing Parameters #
#########################

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o h --long help \
        -n 'invalid option' -- "$@"`

        if [ $? != 0 ]; then echo "Try '--help' for more information." >&2; exit 1; fi

        eval set -- "$TEMP";;
    "Darwin");;
esac

while true
do
    case "$1" in
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) shift;break;;
    esac
done

echo 

#########################
# Create TEMP Folder    #
#########################
if ! which mktemp > /dev/null; then
    echo "Package \"mktemp\" not found!"
    rm -rf ./fonts_temp
    mkdir fonts_temp
    cd fonts_temp
    TMP_DIR=`pwd`
    cd ..
else
    rm -rf /tmp/fonts_temp.*
    TMP_DIR=`mktemp -d -t fonts_temp.XXXXXXXXXXXX`
fi

#########################
# Download and Unzip    #
#########################
run_wget ${TMP_DIR} ${FONTS_URL}
FONTS_BASENAME=`basename ${FONTS_URL}`
unzip -d ${TMP_DIR} ${TMP_DIR}/${FONTS_BASENAME}

echo -e "\n### Please make sure:\n1) your phone is unlocked,\n2) the adb is enabled,\n3) and the adb is running as root."
read -p "### (Press Return to continue...)" is_continue

#########################
# Flash System Fonts    #
#########################
CURRENT_DIR=`pwd`
TARGET_DIR=`ls -d ${TMP_DIR}/*/`
echo "${TMP_DIR} ${TARGET_DIR}"

cd ${TARGET_DIR}
bash ./flash.sh
ret=$?
if ! [ ${ret} == 0 ]; then
    echo "Flash System Fonts failed."
    exit -1
fi
cd ${CURRENT_DIR}

#rm -rf ${TMP_DIR}
echo -e "\n### The following command can update fonts without download again:\n  cd ${TARGET_DIR} && ./flash.sh && cd ${CURRENT_DIR}\n"

