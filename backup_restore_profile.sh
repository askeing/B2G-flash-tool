#!/bin/bash

PROFILE_HOME=${PROFILE_HOME:="./mozilla-profile"}
REBOOT_FLAG=true

## Show usage
function helper(){
    echo -e "This script was written for backup and restore user profile.\n"
    echo -e "Usage:"
    echo -e "  -b|--backup\tbackup user profile."
    echo -e "  -r|--restore\trestore user profile."
    echo -e "  -p|--profile-dir\tspecify the profile folder. Default=./mozilla-profile"
    echo -e "  -h|--help\tdisplay help."
    exit 0
}

## adb with flags
function run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
    adb $ADB_FLAGS $@
}

function do_backup_profile() {
    mkdir -p ${PROFILE_HOME}
    echo -e "### Backup your profiles..." | tee -a ${PROFILE_HOME}/backup.log
    rm -rf ${PROFILE_HOME}/*
    date +"### %F %T" | tee -a ${PROFILE_HOME}/backup.log
    echo -e "### Stop B2G..." | tee -a ${PROFILE_HOME}/backup.log
    run_adb shell stop b2g 2>> ${PROFILE_HOME}/backup.log

    echo "### Backup Wifi information..." | tee -a ${PROFILE_HOME}/backup.log
    mkdir -p ${PROFILE_HOME}/wifi
    run_adb pull /data/misc/wifi/wpa_supplicant.conf ${PROFILE_HOME}/wifi/wpa_supplicant.conf 2>> ${PROFILE_HOME}/backup.log &&

    echo "### Backup /data/b2g/mozilla to ${PROFILE_HOME}/profile ..." | tee -a ${PROFILE_HOME}/backup.log
    mkdir -p ${PROFILE_HOME}/profile &&
    run_adb pull /data/b2g/mozilla ${PROFILE_HOME}/profile 2>> ${PROFILE_HOME}/backup.log

    echo "### Backup /data/local to ${PROFILE_HOME}/data-local ..." | tee -a ${PROFILE_HOME}/backup.log
    mkdir -p ${PROFILE_HOME}/data-local &&
    run_adb pull /data/local ${PROFILE_HOME}/data-local 2>> ${PROFILE_HOME}/backup.log

    ls ${PROFILE_HOME}/data-local/webapps | grep "marketplace\|gaiamobile.org" | while read -r LINE ; do
        FILE=`echo -e $LINE | tr -d "\r\n"`;
        echo "### Remove ${PROFILE_HOME}/data-local/webapps/$FILE ..." | tee -a ${PROFILE_HOME}/backup.log
        rm -rf ${PROFILE_HOME}/data-local/webapps/$FILE
    done
    if [[ ${REBOOT_FLAG} == true ]]; then
        echo -e "### Start B2G..." | tee -a ${PROFILE_HOME}/backup.log
        run_adb shell start b2g 2>> ${PROFILE_HOME}/backup.log
    fi
    echo -e "### Backup done." | tee -a ${PROFILE_HOME}/backup.log
}

function do_restore_profile() {
    echo -e "### Recover your profiles..." | tee -a ${PROFILE_HOME}/recover.log
    if [ ! -d ${PROFILE_HOME}/profile ] || [ ! -d ${PROFILE_HOME}/data-local ]; then
        echo "### No recover files in ${PROFILE_HOME}."
        exit -1
    fi
    rm -rf ${PROFILE_HOME}/recover.log
    date +"### %F %T" | tee -a ${PROFILE_HOME}/recover.log
    echo -e "### Stop B2G..." | tee -a ${PROFILE_HOME}/recover.log
    run_adb shell stop b2g 2>> ${PROFILE_HOME}/recover.log
    run_adb shell rm -r /data/b2g/mozilla 2>> ${PROFILE_HOME}/recover.log

    echo "### Restore Wifi information ..." | tee -a ${PROFILE_HOME}/recover.log
    run_adb push ${PROFILE_HOME}/wifi /data/misc/wifi 2>> ${PROFILE_HOME}/recover.log &&
    run_adb shell chown wifi.wifi /data/misc/wifi/wpa_supplicant.conf ||
    echo "No Wifi information." | tee -a ${PROFILE_HOME}/recover.log

    echo "### Restore ${PROFILE_HOME}/profile ..." | tee -a ${PROFILE_HOME}/recover.log
    run_adb push ${PROFILE_HOME}/profile /data/b2g/mozilla 2>> ${PROFILE_HOME}/recover.log

    echo "### Restore ${PROFILE_HOME}/data-local ..." | tee -a ${PROFILE_HOME}/recover.log
    run_adb push ${PROFILE_HOME}/data-local /data/local 2>> ${PROFILE_HOME}/recover.log

    if [[ ${REBOOT_FLAG} == true ]]; then
        echo -e "### Reboot..." | tee -a ${PROFILE_HOME}/recover.log
        run_adb reboot 2>> ${PROFILE_HOME}/recover.log
        run_adb wait-for-device 2>> ${PROFILE_HOME}/recover.log
    fi
    echo -e "### Recover done." | tee -a ${PROFILE_HOME}/recover.log
}


### Script Start ###

## show helper if nothing specified
if [ $# = 0 ]; then echo "Nothing specified"; helper; exit 0; fi

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o brp::h --long backup,restore,profile-dir::,no-reboot,help \
        -n 'invalid option' -- "$@"`

        if [ $? != 0 ]; then echo "Try '--help' for more information." >&2; exit 1; fi

        eval set -- "$TEMP";;
    "Darwin");;
esac

while true
do
    case "$1" in
        -b|--backup) do_backup_profile; shift;;
        -r|--restore) do_restore_profile; shift;;
        -p|--profile-dir)
            case "$2" in
                "") echo "Please specify the profile folder."; exit 0; shift 2;;
                *) PROFILE_HOME=$2; echo "Set the profile folder as ${PROFILE_HOME}"; shift 2;;
            esac ;;
        # only for other tools
        --no-reboot) REBOOT_FLAG=false; shift;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) helper; echo error occured; exit 1;;
    esac
done
