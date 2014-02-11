#!/bin/bash

## Show usage
function helper(){
    echo -e "This script was written for backup and restore user profile.\n"
    echo -e "Usage:"
    echo -e "  -b|--backup\tbackup user profile."
    echo -e "  -r|--restore\trestore user profile."
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
    if [ ! -d mozilla-profile ]; then
        echo "no backup folder, creating..."
        mkdir mozilla-profile
    fi
    echo -e "Backup your profiles..."
    run_adb shell stop b2g 2> ./mozilla-profile/backup.log
    rm -rf ./mozilla-profile/*

    mkdir -p mozilla-profile/profile
    run_adb pull /data/b2g/mozilla ./mozilla-profile/profile 2> ./mozilla-profile/backup.log
    mkdir -p mozilla-profile/data-local
    run_adb pull /data/local ./mozilla-profile/data-local 2> ./mozilla-profile/backup.log
    rm -rf mozilla-profile/data-local/webapps
    run_adb shell start b2g 2> ./mozilla-profile/backup.log
    echo -e "Backup done."
}

function do_restore_profile() {
    echo -e "Recover your profiles..."
    if [ ! -d mozilla-profile/profile ] || [ ! -d mozilla-profile/data-local ]; then
        echo "no recover files."
        exit -1
    fi
    run_adb shell stop b2g 2> ./mozilla-profile/recover.log
    run_adb shell rm -r /data/b2g/mozilla 2> ./mozilla-profile/recover.log
    run_adb push ./mozilla-profile/profile /data/b2g/mozilla 2> ./mozilla-profile/recover.log
    run_adb push ./mozilla-profile/data-local /data/local 2> ./mozilla-profile/recover.log
    run_adb reboot
    sleep 30
    echo -e "Recover done."
}


### Script Start ###

## show helper if nothing specified
if [ $# = 0 ]; then echo "Nothing specified"; helper; exit 0; fi

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o brh --long backup,restore,help \
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
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) helper; echo error occured; exit 1;;
    esac
done
