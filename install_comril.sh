#!/bin/bash
#==========================================================================
#
# IMPORTANT: only for internal use!
#
# Description:
#   This script was written for uninstall/install com-ril.
#
# Author: Askeing fyen@mozilla.com
# History:
#   2013/10/31 Askeing: v1.0 First release.
#   2014/02/05 Askeing: Added support of install com-ril.
#
#==========================================================================

####################
# Parameter Flags  #
####################
VERY_SURE=false
RIL_CLEAN=false
RIL_INSTALL=false
RIL_DEBUG=false

####################
# Functions        #
####################

## Show usage
function helper(){
    echo -e "This script was written for clean or install com-ril."
    echo -e "Usage: ./flash_ril.sh [parameters]"
    echo -e "  -u|--uninstall\tuninstall the com-ril."
    echo -e "  -r|--ril\tinstall the com-ril from the file."
    echo -e "  -d|--ril-debug\tturn on ril debugging."
    echo -e "  -s <serial number>\tdirects command to device with the given serial number."
    echo -e "  -y\t\tAssume \"yes\" to all questions"
    echo -e "  -h|--help\tdisplay help."
    exit 0
}

## adb with flags
function run_adb(){
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
    adb $ADB_FLAGS $@
}

function check_ril_file(){
    RIL_FILE=$1
    if [ -f ${RIL_FILE} ]; then
        if ! which mktemp > /dev/null; then
            echo "Package \"mktemp\" not found!"
            rm -rf ./ril_temp
            mkdir ril_temp
            cd ril_temp
            RIL_DIR=`pwd`
            cd ..
        else
            RIL_DIR=`mktemp -d -t ril_temp.XXXXXXXXXXXX`
        fi
        # Extract RIL file to temp folder
        tar -C ${RIL_DIR} -xf ${RIL_FILE}
        if [ $? != 0 ]; then echo "Extract com-ril file ${RIL_FILE} error." >&2; rm -rf ${RIL_DIR}; exit -1; fi
    else
        echo "The com-ril file ${RIL_FILE} do not exist." && exit -1
    fi
}

function remount_system(){
    echo "gaining root access"
    run_adb root
    run_adb wait-for-device
    
    echo "remounting the system partition"
    run_adb remount
    run_adb shell mount -o remount,rw /system
    
    echo "Waiting for adb to come back up"
    run_adb wait-for-device
    
    echo "Stopping b2g"
    run_adb shell stop b2g
}

function reboot_system(){
    echo "Rebooting"
    run_adb shell sync
    run_adb reboot
}

#########################
# Processing Parameters #
#########################

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o ur::ds::yh --long uninstall,ril::,ril-debug,help \
        -n 'invalid option' -- "$@"`

        if [ $? != 0 ]; then echo "Try '--help' for more information." >&2; exit 1; fi

        eval set -- "$TEMP";;
    "Darwin");;
esac

while true
do
    case "$1" in
        -u|--uninstall) RIL_CLEAN=true; shift;;
        -r|--ril)
            case "$2" in
                "") helper; exit 0; shift 2;;
                *) RIL_INSTALL=true; check_ril_file $2; shift 2;;
            esac ;;
        -d|--ril-debug) RIL_DEBUG=true; shift;;
        -s)
            case "$2" in
                "") shift 2;;
                *) ADB_FLAGS+="-s $2"; shift 2;;
            esac ;;
        -y) VERY_SURE=true; shift;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) helper; echo error occured; exit 1;;
    esac
done

remount_system

if [ ${RIL_CLEAN} == true ]; then
    if [ ${VERY_SURE} == false ]; then
        read -p "Are you sure you want to UN-INSTALL com-ril? [y/N]" isClean
        test "$isClean" != "y" && test "$isClean" != "Y" && reboot_system && echo "byebye." && exit 0
    fi
    echo "Uninstalling old RIL..."
    run_adb shell rm -r /system/b2g/distribution/bundles/libqc_b2g_location
    run_adb shell rm -r /system/b2g/distribution/bundles/libqc_b2g_ril
    
    echo "Removing incompatible extensions"
    run_adb shell rm -r /system/b2g/distribution/bundles/liblge_b2g_extension > /dev/null
    
    echo "Done uninstalling RIL!"
fi

if [ ${RIL_INSTALL} == true ]; then
    if [ ${VERY_SURE} == false ]; then
        read -p "Are you sure you want to INSTALL com-ril? [y/N]" isInstall
        test "$isInstall" != "y" && test "$isInstall" != "Y" && echo "byebye." && rm -rf ${RIL_DIR} && reboot_system && exit 0
    fi
    
    RIL_BUNDLES=${RIL_DIR}/vendor/*/proprietary/*/target/product/*/system/b2g/distribution/bundles/
    if [ -d ${RIL_BUNDLES} ]; then
        echo "Installing new RIL..."
        run_adb push ${RIL_BUNDLES} /system/b2g/distribution/bundles/

        echo "Removing incompatible extensions"
        run_adb shell rm -r /system/b2g/distribution/bundles/liblge_b2g_extension > /dev/null

        echo "Done installing RIL!"
        rm -rf ${RIL_DIR}
    else
        echo "Can NOT found the Com RIL from ${RIL_DIR}." && rm -rf ${RIL_DIR} && reboot_system && exit -1
    fi
fi

if [ ${RIL_DEBUG} == true ]; then
    if [ ${VERY_SURE} == false ]; then
        read -p "Are you sure you want to enable ril debugging? [y/N]" isDebug
        test "$isDebug" != "y" && test "$isDebug" != "Y" && echo "byebye." && exit 0
    fi
    rm -f user.js user.js.org
    run_adb pull /system/b2g/defaults/pref/user.js user.js.org
    cat user.js.org | sed -e "s/ril.debugging.enabled\", false/ril.debugging.enabled\", true/" | sed -e "s/ril.debugging.enabled', false/ril.debugging.enabled', true/" > user.js
    run_adb push user.js /system/b2g/defaults/pref
    rm -f user.js user.js.org
fi

reboot_system

echo "Done!"

