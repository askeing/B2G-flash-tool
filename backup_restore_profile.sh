#!/bin/bash

set -e

LOGFILE=${LOGFILE:=backup_restore_profile.log}

function helper(){
    echo -e "Backup and restore Firefox OS profiles.\n"
    echo -e "Usage:"
    echo -e "  -b|--backup\tbackup user profile."
    echo -e "  -r|--restore\trestore user profile."
    echo -e "  -p|--profile-dir\tspecify the profile folder. Default=./mozilla-profile"
    echo -e "  -h|--help\tdisplay help."
}

function log_command() {
    mkdir -p $(dirname $LOGFILE)
    $@ 2>&1 | tee -a $LOGFILE
    return ${PIPESTATUS[0]}
}

function log() {
    log_command echo -e "$(date -u +'%Y-%m-%d %H:%M%S') ###" $@
}

function run_adb()
{
    log_command adb $ADB_FLAGS $@
}

function do_backup_profile() {
    local profile_dir=$1 ; shift
    local do_reboot=$1 ; shift
    # GNU mktemp has a nice --tmpdir option, but not so on OS X
    tmp_dir=$(TMPDIR=. mktemp -d -t "$(basename $profile_dir).XXXXXXXXXX")
    log "Stoping B2G..."
    run_adb shell stop b2g

    log "Backing up Wifi information..."
    mkdir -p ${tmp_dir}/wifi
    run_adb pull /data/misc/wifi/wpa_supplicant.conf ${tmp_dir}/wifi/wpa_supplicant.conf

    log "Backing up /data/b2g/mozilla to ${tmp_dir}/profile ..."
    mkdir -p ${tmp_dir}/profile &&
    run_adb pull /data/b2g/mozilla ${tmp_dir}/profile

    log "Backing up /data/local to ${tmp_dir}/data-local ..."
    mkdir -p ${tmp_dir}/data-local
    run_adb pull /data/local ${tmp_dir}/data-local

    ls ${tmp_dir}/data-local/webapps | grep "marketplace\|gaiamobile.org" | while read -r LINE ; do
        FILE=`echo -e $LINE | tr -d "\r\n"`;
        rm -rf ${tmp_dir}/data-local/webapps/$FILE
        log "Removed ${tmp_dir}/data-local/webapps/$FILE ..."
    done
    if [ $do_reboot -eq 1 ]; then
        log "Start B2G..."
        run_adb shell start b2g
    fi
    rm -rf $profile_dir
    mv $tmp_dir $profile_dir
    log "Backup done."
}

function do_restore_profile() {
    local profile_dir=$1 ; shift
    local do_reboot=$1 ; shift
    log "Recover your profile..."
    if [ ! -d ${profile_dir}/profile ] || [ ! -d ${profile_dir}/data-local ]; then
        log "No recover files in ${profile_dir}."
        exit -1
    fi
    log "Stoping B2G..."
    run_adb shell stop b2g
    run_adb shell rm -r /data/b2g/mozilla

    log "Restoring Wifi information ..."
    run_adb push ${profile_dir}/wifi /data/misc/wifi &&
    run_adb shell chown wifi.wifi /data/misc/wifi/wpa_supplicant.conf ||
    log "No Wifi information."

    log "Restoring ${profile_dir}/profile ..."
    run_adb push ${profile_dir}/profile /data/b2g/mozilla

    log "Restoring ${profile_dir}/data-local ..."
    run_adb push ${profile_dir}/data-local /data/local

    if [ $do_reboot -eq 1 ]; then
        log "Reboot..."
        run_adb reboot
        run_adb wait-for-device
    fi
    log "Recovery done."
}

do_backup=0
do_restore=0
profile_dir=${PROFILE_HOME:="./mozilla-profile"}
do_reboot=1

if [ $# = 0 ]; then echo "Must specify either backup or restore"; helper; exit 1; fi

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

log "######################"
log "# B2G Backup/Restore #"
log "######################"

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

