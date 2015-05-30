#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for shallow flash the gaia and/or gecko.
#
# Author: Askeing fyen@mozilla.com
#         Contribs from slee steve@opendirective.com
# History:
#   2013/08/02 Askeing: v1.0 First release.
#   2014/08/09 Added Cygwin support by revelon.
#   2014/09/24 Fixed Cygwin path problems & set x file attrib for gecko
#==========================================================================


####################
# Parameter Flags  #
####################
VERY_SURE=false
KEEP_PROFILE=false
ADB_DEVICE="Device"
FLASH_GAIA=false
FLASH_GAIA_FILE=""
FLASH_GECKO=false
FLASH_GECKO_FILE=""
NO_FTU=${NO_FTU:-false}

####################
# Functions        #
####################

## helper function
function helper(){
    echo -e "This script was written for shallow flash of gaia and/or gecko.\n"
    echo -e "Usage: ./shallow_flash.sh [parameters]"
    echo -e "-g|--gaia\tFlash the gaia (zip format) onto your device."
    echo -e "-G|--gecko\tFlash the gecko (tar.gz format) onto your device."
    echo -e "--keep_profile\tKeep the user profile on your device. (BETA)"
    echo -e "-s <serial number>\tdirects command to device with the given serial number."
    echo -e "-y\t\tflash the file without asking askeing (it's a joke...)"
    echo -e "-h|--help\tDisplay help."
    echo -e "Example:"
    case `uname` in
        "Linux"|"CYGWIN"*)
            echo -e "  Flash gaia.\t\t./shallow_flash.sh --gaia=gaia.zip"
            echo -e "  Flash gecko.\t\t./shallow_flash.sh --gecko=b2g-18.0.en-US.android-arm.tar.gz"
            echo -e "  Flash gaia and gecko.\t./shallow_flash.sh -ggaia.zip -Gb2g-18.0.en-US.android-arm.tar.gz";;
        "Darwin")
            echo -e "  Flash gaia.\t\t./shallow_flash.sh --gaia gaia.zip"
            echo -e "  Flash gecko.\t\t./shallow_flash.sh --gecko b2g-18.0.en-US.android-arm.tar.gz"
            echo -e "  Flash gaia and gecko.\t./shallow_flash.sh -g gaia.zip -G b2g-18.0.en-US.android-arm.tar.gz";;
    esac
    exit 0
}

## adb with flags
function run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
	adb $ADB_FLAGS "$@"
}

## make sure user want to shallow flash
function make_sure() {
    echo "Are you sure you want to flash "
    if [[ $FLASH_GAIA == true ]]; then
        echo -e "Gaia: $FLASH_GAIA_FILE "
    fi
    if [[ $FLASH_GECKO == true ]]; then
        echo -e "Gecko: $FLASH_GECKO_FILE "
    fi
    read -p "to your $ADB_DEVICE? [y/N]" isFlash

    [ "y" = "$isFlash" ] || [ "Y" = "$isFlash" ] \
        || { echo -e "bye bye." && exit 0 ; }
}

## check the return code, exit if return code is not zero.
function check_exit_code() {
	RET=$1
	ERROR_MSG=$2
	if [[ ${RET} != 0 ]]; then
        if [[ -z ${ERROR_MSG} ]]; then
            echo "### Failed!"
        else
        	echo "### Failed: ${ERROR_MSG}"
        fi
        exit 1
	fi
}

function check_adb_result() {
    RET=$1
    if [[ $RET == *"error"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    elif [[ $RET == *"cannot run as root"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    elif [[ $RET == *"remount failed"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    elif [[ $RET == *"Operation not permitted"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    fi
}

## adb root, then remount and stop b2g
function adb_root_remount() {
    echo "### Waiting for device... please ensure it is connected, switched on and remote debugging is enabled in Gaia"
    run_adb wait-for-device     #in: gedit display issue

    echo "### Restarting adb with root permissions..."
    RET=$(run_adb root)
    echo "$RET"
    check_adb_result "$RET"
    run_adb wait-for-device     #in: gedit display issue

    echo "### Remounting the /system partition..."
    RET=$(run_adb remount)
    echo "$RET"
    check_adb_result "$RET"
    RET=$(run_adb shell mount -o remount,rw /system)
    echo "$RET"
    check_adb_result "$RET"

    echo "### Stopping b2g process..."
    run_adb shell stop b2g
}

## adb sync then reboot
function adb_reboot() {
    run_adb shell sync
    run_adb shell reboot
    run_adb wait-for-device     #in: gedit display issue
}

## clean cache, gaia (webapps) and profiles
function adb_clean_gaia() {
    echo "### Cleaning Gaia and Profiles ..."
    run_adb shell "rm -r /cache/*" &&
    run_adb shell "rm -r /data/b2g/*" &&
    run_adb shell "rm -r /data/local/storage/persistent/*" &&
    run_adb shell "rm -r /data/local/svoperapps" &&
    run_adb shell "rm -r /data/local/webapps" &&
    run_adb shell "rm -r /data/local/user.js" &&
    run_adb shell "rm -r /data/local/permissions.sqlite*" &&
    run_adb shell "rm -r /data/local/OfflineCache" &&
    run_adb shell "rm -r /data/local/indexedDB" &&
    run_adb shell "rm -r /data/local/debug_info_trigger" &&
    run_adb shell "rm -r /system/b2g/webapps" &&
    echo "### Cleaning Done."
}

## push gaia into device
function adb_push_gaia() {
    GAIA_DIR=$1
    LOCAL_GAIA_DIR=$GAIA_DIR
    if [[ `uname` == "CYGWIN"* ]]; then
        ## Adb on win32 is not cygwin so doesn't handle full posix paths for local access
        LOCAL_GAIA_DIR=$(cygpath -w $GAIA_DIR);
    fi 
    ## Adjusting user.js
    cat $GAIA_DIR/gaia/profile/user.js | sed -e "s/user_pref/pref/" > $GAIA_DIR/user.js &&
    echo "### Pushing Gaia to device ..." &&
    run_adb shell mkdir -p /system/b2g/defaults/pref &&
    run_adb push "$LOCAL_GAIA_DIR/gaia/profile/webapps" /system/b2g/webapps &&
    run_adb push "$LOCAL_GAIA_DIR/user.js" /system/b2g/defaults/pref &&
    run_adb push "$LOCAL_GAIA_DIR/gaia/profile/settings.json" /system/b2g/defaults &&
    echo "### Push Done."
}

## shallow flash gaia
function shallow_flash_gaia() {
    GAIA_ZIP_FILE=$1
    
    if ! [[ -f $GAIA_ZIP_FILE ]]; then
        echo "### Cannot find $GAIA_ZIP_FILE file."
        exit 2
    fi

    if ! which mktemp > /dev/null; then
        echo "### Package \"mktemp\" not found!"
        rm -rf ./shallowflashgaia_temp
        mkdir shallowflashgaia_temp
        cd shallowflashgaia_temp
        TMP_DIR=`pwd`
        cd ..
    else
        TMP_DIR=`mktemp -d -t shallowflashgaia.XXXXXXXXXXXX`
    fi

    unzip_file $GAIA_ZIP_FILE $TMP_DIR &&
    adb_clean_gaia &&
    adb_push_gaia $TMP_DIR
    check_exit_code $? "Pushing Gaia to device failed."

    rm -rf $TMP_DIR
}

## unzip zip file
function unzip_file() {
    ZIP_FILE=$1
    DEST_DIR=$2
    if ! [[ -z $ZIP_FILE ]]; then
        test ! -f $ZIP_FILE && echo -e "### The file $ZIP_FILE DOES NOT exist." && exit 2
    else
        echo "### No input zip file."
        exit 2
    fi
    echo "### Unzip $ZIP_FILE to $DEST_DIR ..."
    test -e $ZIP_FILE && unzip -q $ZIP_FILE -d $DEST_DIR
    check_exit_code $? "Unzip $ZIP_FILE Failed."
    #ls -LR $DEST_DIR
}

## clean /system/media/ and extra gecko files
function adb_clean_extra_gecko_files() {
    echo "### Cleaning Extra System Files ..."
    run_adb shell "rm -r /system/media"
    echo "### Cleaning Done."

    echo "### Cleaning Extra Gecko Files ..."
    GECKO_DIR=$1
    REMOVED_FILES="$(echo -e "$(ls "$GECKO_DIR/b2g" | cat)\n$(run_adb shell "ls /system/b2g" | tr -d '\r')" | sort | uniq -u)"
    if [[ "$REMOVED_FILES" != "" ]]; then
        for REMOVED_FILE in $REMOVED_FILES; do
            if [[ "$REMOVED_FILE" != "defaults" ]] && [[ "$REMOVED_FILE" != "webapps" ]]; then
		echo "##### Removing /system/b2g/$REMOVED_FILE ..."
                run_adb shell "rm -r /system/b2g/$REMOVED_FILE"
            fi
        done
    fi
    echo "### Cleaning Done."
}

## shallow flash gecko
function shallow_flash_gecko() {
    GECKO_TAR_FILE=$1

    if ! [[ -f $GECKO_TAR_FILE ]]; then
        echo "### Cannot find $GECKO_TAR_FILE file."
        exit 2
    fi

    if ! which mktemp > /dev/null; then
        echo "### Package \"mktemp\" not found!"
        rm -rf ./shallowflashgecko_temp
        mkdir shallowflashgecko_temp
        cd shallowflashgecko_temp
        TMP_DIR=`pwd`
        cd ..
    else
        TMP_DIR=`mktemp -d -t shallowflashgecko.XXXXXXXXXXXX`
    fi

    ## push gecko into device
    LOCAL_TMP_DIR=$TMP_DIR
    if [[ `uname` == "CYGWIN"* ]]; then
        ## Adb on win32 is not cygwin so doesn't handle full posix paths for local access
        LOCAL_TMP_DIR=$(cygpath -w $TMP_DIR);
    fi
    untar_file $GECKO_TAR_FILE $TMP_DIR &&
    echo "### Pushing Gecko to device..." &&
    adb_clean_extra_gecko_files $LOCAL_TMP_DIR &&
    run_adb push "$LOCAL_TMP_DIR/b2g" /system/b2g &&
    echo "### Push Done."
    check_exit_code $? "Pushing Gecko to device failed."

    rm -rf $TMP_DIR
	
    if [[ `uname` == "CYGWIN"* ]]; then
	    # reset excutable attribute as is not supported on Cygwin
        echo "### Setting executable file attributes..." &&
        XFILES=$(tar -tvf $GECKO_TAR_FILE | awk '$1 ~ /^-.*x$/ {print "/system/" $NF}')
        echo $XFILES
        run_adb shell chmod 777 $XFILES	
        echo "### Setting attributes Done."
        check_exit_code $? "Setting executable file attributes failed."
    fi
}

## untar tar.gz file
function untar_file() {
    TAR_FILE=$1
    DEST_DIR=$2
    if ! [[ -z $TAR_FILE ]]; then
        test ! -f $TAR_FILE && echo -e "### The file $TAR_FILE DOES NOT exist." && exit 2
    else
        echo "### No input tar file."
        exit 2
    fi
    echo "### Untar $TAR_FILE to $DEST_DIR ..."
    test -e $TAR_FILE && tar -xzf $TAR_FILE -C $DEST_DIR
    check_exit_code $? "Untar $TAR_FILE Failed."
    #ls -LR $DEST_DIR
}

## option $1 is temp_folder
function backup_profile() {
    DEST_DIR=$1
    echo "### Profile back up to ${DEST_DIR}"
    ./backup_restore_profile.py -p ${DEST_DIR} --no-reboot -b
}

## option $1 is temp_folder
function restore_profile() {
    DEST_DIR=$1
    echo "### Restore Profile from ${DEST_DIR}"
    ./backup_restore_profile.py -p ${DEST_DIR} --no-reboot -r
}

## option $1 is temp_folder
function remove_profile() {
    DEST_DIR=$1
    echo "### Removing Profile under ${DEST_DIR}"
    rm -rf ${DEST_DIR}
    echo "### Removing Profile complete ."
}

#########################
# Processing Parameters #
#########################

## show helper if nothing specified
if [[ $# = 0 ]]; then echo "Nothing specified"; helper; exit 0; fi

## distinguish platform
case `uname` in
    "Linux"|"CYGWIN"*)
        ## add getopt argument parsing
        TEMP=`getopt -o g::G::s::yh --long gaia::,gecko::,keep_profile,help \
        -n 'invalid option' -- "$@"`

        if [[ $? != 0 ]]; then echo "Try '--help' for more information." >&2; exit 1; fi

        eval set -- "$TEMP";;
    "Darwin");;
esac

while true
do
    case "$1" in
        -h|--help) helper; exit 0;;
        -g|--gaia) 
            FLASH_GAIA=true;
            case "$2" in
                "") echo -e "Please specify the gaia path.\nTry '--help' for more information.";exit 1;;
                *) FLASH_GAIA_FILE=$2; shift 2;;
            esac ;;
        -G|--gecko)
            FLASH_GECKO=true;
            case "$2" in
                "") echo -e "Please specify the gecko path.\nTry '--help' for more information."; exit 1;;
                *) FLASH_GECKO_FILE=$2; shift 2;;
            esac ;;
        --keep_profile) if [[ -e ./backup_restore_profile.py ]]; then KEEP_PROFILE=true; else echo "### There is no backup_restore_profile.py file."; fi; shift;;
        -s)
            case "$2" in
                "") shift 2;;
                *) ADB_DEVICE=$2; ADB_FLAGS+="-s $2"; shift 2;;
            esac ;;
        -y) VERY_SURE=true; shift;;
        --) shift;break;;
        "") shift;break;;
        *) helper; echo error occured; exit 1;;
    esac
done


####################
# Make Sure        #
####################
if [[ $VERY_SURE == false ]] && ([[ $FLASH_GAIA == true ]] || [[ $FLASH_GECKO == true ]]); then
    make_sure
fi
if ! [[ -f $FLASH_GAIA_FILE ]] && [[ $FLASH_GAIA == true ]]; then
    echo "### Cannot find $FLASH_GAIA_FILE file."
    exit 2
fi
if ! [[ -f $FLASH_GECKO_FILE ]] && [[ $FLASH_GECKO == true ]]; then
    echo "### Cannot find $FLASH_GECKO_FILE file."
    exit 2
fi


####################
# ADB Work         #
####################
adb_root_remount

####################
# Backup Profile   #
####################
if [[ $KEEP_PROFILE == true ]] && ([[ $FLASH_GAIA == true ]] || [[ $FLASH_GECKO == true ]]) ; then
    if ! which mktemp > /dev/null; then
        echo "### Package \"mktemp\" not found!"
        rm -rf ./profile_temp
        mkdir profile_temp
        cd profile_temp
        TMP_PROFILE_DIR=`pwd`
        cd ..
    else
        TMP_PROFILE_DIR=`mktemp -d -t shallowflashprofile.XXXXXXXXXXXX`
    fi
    backup_profile ${TMP_PROFILE_DIR}
fi


####################
# Processing Gecko #
####################
if [[ $FLASH_GECKO == true ]]; then
    echo "### Processing Gecko: $FLASH_GECKO_FILE"
    shallow_flash_gecko $FLASH_GECKO_FILE
fi


####################
# Processing Gaia  #
####################
if [[ $FLASH_GAIA == true ]]; then
    echo "### Processing Gaia: $FLASH_GAIA_FILE"
    shallow_flash_gaia $FLASH_GAIA_FILE
fi


####################
# NO FTU           #
####################
if [[ ${NO_FTU} == true ]]; then
    if [[ -f ./disable_ftu.py ]]; then
        echo "### Processing NO FTU..."
        ./disable_ftu.py
        echo "### NO FTU done."
    fi
fi


####################
# Restore Profile  #
####################
if [[ $KEEP_PROFILE == true ]] && ([[ $FLASH_GAIA == true ]] || [[ $FLASH_GECKO == true ]]) ; then
    restore_profile ${TMP_PROFILE_DIR}
    remove_profile ${TMP_PROFILE_DIR}
fi


####################
# ADB Work         #
####################
adb_reboot


####################
# Version          #
####################
if [[ -e ./check_versions.py ]]; then
    ./check_versions.py
fi


####################
# Done             #
####################
echo -e "### Shallow Flash Successful!"


