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

function log_command() {
    logname=$1 ; shift
    mkdir -p ${PROFILE_HOME}
    $@ 2>&1 | tee -a ${PROFILE_HOME}/${logname}.log
}

function log() {
    logname=$1 ; shift
    log_command $logname echo -e "$(date -u +'%Y-%m-%d %H:%M%S') ###" $@
}

## adb with flags
function run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
    logname=$1 ; shift
    mkdir -p ${PROFILE_HOME}
    log_command $logname adb $ADB_FLAGS $@
}

function do_backup_profile() {
    mkdir -p ${PROFILE_HOME}
    log backup "Backing up your profile..."
    rm -rf ${PROFILE_HOME}/*
    log backup "Stoping B2G..."
    run_adb backup shell stop b2g

    log backup "Backing up Wifi information..."
    mkdir -p ${PROFILE_HOME}/wifi
    run_adb backup pull /data/misc/wifi/wpa_supplicant.conf ${PROFILE_HOME}/wifi/wpa_supplicant.conf

    log backup "Backup /data/b2g/mozilla to ${PROFILE_HOME}/profile ..."
    mkdir -p ${PROFILE_HOME}/profile &&
    run_adb backup pull /data/b2g/mozilla ${PROFILE_HOME}/profile

    log backup "Backup /data/local to ${PROFILE_HOME}/data-local ..."
    mkdir -p ${PROFILE_HOME}/data-local
    run_adb backup pull /data/local ${PROFILE_HOME}/data-local

    ls ${PROFILE_HOME}/data-local/webapps | grep "marketplace\|gaiamobile.org" | while read -r LINE ; do
        FILE=`echo -e $LINE | tr -d "\r\n"`;
        rm -rf ${PROFILE_HOME}/data-local/webapps/$FILE
        log backup "Removed ${PROFILE_HOME}/data-local/webapps/$FILE ..."
    done
    if [[ ${REBOOT_FLAG} == true ]]; then
        log backup "Start B2G..."
        run_adb backup shell start b2g
    fi
    log backup "Backup done."
}

function do_restore_profile() {
    log restore "Recover your profiles..."
    if [ ! -d ${PROFILE_HOME}/profile ] || [ ! -d ${PROFILE_HOME}/data-local ]; then
        log restore "No recover files in ${PROFILE_HOME}."
        exit -1
    fi
    log restore "Stop B2G..."
    run_adb restore shell stop b2g
    run_adb restore shell rm -r /data/b2g/mozilla

    "Restore Wifi information ..."
    run_adb restore push ${PROFILE_HOME}/wifi /data/misc/wifi 2>> ${PROFILE_HOME}/recover.log &&
    run_adb restore shell chown wifi.wifi /data/misc/wifi/wpa_supplicant.conf ||
    log restore "No Wifi information."

    log restore "Restore ${PROFILE_HOME}/profile ..."
    run_adb restore push ${PROFILE_HOME}/profile /data/b2g/mozilla

    log restore "Restore ${PROFILE_HOME}/data-local ..."
    run_adb restore push ${PROFILE_HOME}/data-local /data/local

    if [[ ${REBOOT_FLAG} == true ]]; then
        log restore "Reboot..."
        run_adb restore reboot
        run_adb restore wait-for-device
    fi
    log restore "Recover done."
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
