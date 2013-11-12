#!/bin/bash
#==========================================================================
# 
# Description:
#   This script was written for uninstall com-ril.
#
# Author: Askeing fyen@mozilla.com
# History:
#   2013/10/31 Askeing: v1.0 First release.
#
#==========================================================================

####################
# Parameter Flags  #
####################
VERY_SURE=false
RIL_CLEAN=false

####################
# Functions        #
####################

## Show usage
function helper(){
	echo -e "This script was written for uninstall com-ril."
	echo -e "Usage: ./uninstall_comril.sh [parameters]"
    echo -e "  -u|--uninstall\tuninstall the com-ril."
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
        TEMP=`getopt -o us::yh --long uninstall,help \
        -n 'invalid option' -- "$@"`

        if [ $? != 0 ]; then echo "Try '--help' for more information." >&2; exit 1; fi

        eval set -- "$TEMP";;
    "Darwin");;
esac

while true
do
    case "$1" in
        -u|--uninstall) RIL_CLEAN=true; shift;;
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

if [ ${RIL_CLEAN} == true ]; then
    remount_system
    
    if [ ${VERY_SURE} == false ]; then
        read -p "Are you sure you want to UN-INSTALL com-ril? [y/N]" isUninstall
        test "$isUninstall" != "y" && test "$isUninstall" != "Y" && reboot_system echo "byebye." && exit 0
    fi
    echo "Uninstalling old RIL..."
    run_adb shell rm -r /system/b2g/distribution/bundles/libqc_b2g_location
    run_adb shell rm -r /system/b2g/distribution/bundles/libqc_b2g_ril
    
    echo "Removing incompatible extensions"
    run_adb shell rm -r /system/b2g/distribution/bundles/liblge_b2g_extension > /dev/null
    
    echo "Done uninstalling RIL!"
    
    reboot_system
    echo "Done!"
else
    helper
fi

