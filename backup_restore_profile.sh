#!/bin/bash

LOGFILE=${LOGFILE:=backup_restore_profile.log}

function helper(){
    echo -e "This script was written for backup and restore user profile.\n"
    echo -e "Usage:"
    echo -e "  -b|--backup\tbackup user profile."
    echo -e "  -r|--restore\trestore user profile."
    echo -e "  -p|--profile-dir\tspecify the profile folder. Default=./mozilla-profile"
    echo -e "  -h|--help\tdisplay help."
}

function log_command() {
    mkdir -p $(dirname $LOGFILE)
    $@ 2>&1 | tee -a $LOGFILE
}

function log() {
    log_command $logname echo -e "$(date -u +'%Y-%m-%d %H:%M%S') ###" $@
}

## adb with flags
function run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
    log_command adb $ADB_FLAGS $@
}

function do_backup_profile() {
    profile_dir=$1 ; shift
    do_reboot=$1 ; shift
    mkdir -p ${profile_dir}
    log "Backing up your profile..."
    rm -rf ${profile_dir}/*
    log "Stoping B2G..."
    run_adb shell stop b2g

    log "Backing up Wifi information..."
    mkdir -p ${profile_dir}/wifi
    run_adb pull /data/misc/wifi/wpa_supplicant.conf ${profile_dir}/wifi/wpa_supplicant.conf

    log "Backup /data/b2g/mozilla to ${profile_dir}/profile ..."
    mkdir -p ${profile_dir}/profile &&
    run_adb pull /data/b2g/mozilla ${profile_dir}/profile

    log "Backup /data/local to ${profile_dir}/data-local ..."
    mkdir -p ${profile_dir}/data-local
    run_adb pull /data/local ${profile_dir}/data-local

    ls ${profile_dir}/data-local/webapps | grep "marketplace\|gaiamobile.org" | while read -r LINE ; do
        FILE=`echo -e $LINE | tr -d "\r\n"`;
        rm -rf ${profile_dir}/data-local/webapps/$FILE
        log "Removed ${profile_dir}/data-local/webapps/$FILE ..."
    done
    if [ $do_reboot -eq 1 ]; then
        log "Start B2G..."
        run_adb shell start b2g
    fi
    log "Backup done."
}

function do_restore_profile() {
    profile_dir=$1 ; shift
    do_reboot=$1 ; shift
    log "Recover your profiles..."
    if [ ! -d ${profile_dir}/profile ] || [ ! -d ${profile_dir}/data-local ]; then
        log "No recover files in ${profile_dir}."
        exit -1
    fi
    log "Stop B2G..."
    run_adb shell stop b2g
    run_adb shell rm -r /data/b2g/mozilla

    "Restore Wifi information ..."
    run_adb push ${profile_dir}/wifi /data/misc/wifi 2>> ${profile_dir}/recover.log &&
    run_adb shell chown wifi.wifi /data/misc/wifi/wpa_supplicant.conf ||
    log "No Wifi information."

    log "Restore ${profile_dir}/profile ..."
    run_adb push ${profile_dir}/profile /data/b2g/mozilla

    log "Restore ${profile_dir}/data-local ..."
    run_adb push ${profile_dir}/data-local /data/local

    if [[ ${REBOOT_FLAG} == true ]]; then
        log "Reboot..."
        run_adb reboot
        run_adb wait-for-device
    fi
    log "Recover done."
}

do_backup=0
do_restore=0
profile_dir=${PROFILE_HOME:="./mozilla-profile"}
do_reboot=1

if [ $# = 0 ]; then echo "Nothing specified"; helper; exit 1; fi

while [ $# -gt 0 ]
do
    case "$1" in
        -b|--backup) do_backup=1;;
        -r|--restore) do_restore=1;;
        -p|--profile-dir) profile_dir=$2; shift;;
        --no-reboot) do_reboot=0;;
        -h|--help) helper; exit 0;;
        *) helper; echo "$1 is not a recognized option!"; exit 1;;
    esac
    shift
done

if [[ $do_backup -eq 1 && $do_restore -eq 1 ]] ; then
    helper
    echo "You must either backup or restore, not both" 1>&2
    exit 1
fi
 
if [ -z $profile_dir ] ; then
    helper
    echo "You must specify a profile directory if you use the option" 1>&2
    exit 1
fi

if [ ! -d $profile_dir ] ; then
    mkdir -p $profile_dir
fi

if [ $do_backup -eq 1 ] ; then
    do_backup_profile $profile_dir $do_reboot  
elif [ $do_restore -eq 1 ] ; then
    do_restore_profile $profile_dir $do_reboot
fi
