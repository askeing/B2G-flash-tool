#!/bin/bash
#==========================================================================
# Description:
#   This script was written for change OTA update URL.
#
# Author: Askeing fyen@mozilla.com
#
#==========================================================================

function helper_config(){
    echo -e "-h, --help\tShow usage."
    echo -e "-p\t\tShow prefs file of device."
    echo -e "-u, --url\tThe update.xml URL."
}

function show_prefs(){
    set -e
    if [ 'unknown' == $(adb get-state) ]; then
	    echo "Unknown device"
	    exit -1
    fi
    adb shell cat /data/b2g/mozilla/*.default/prefs.js
}


# argument parsing
while [ $# -gt 0 ]; do
	case "$1" in
	"-u"|"--url")
		URL="$2"
		shift
		;;
	"-p")
	    show_prefs
	    exit 0
	    ;;		
	"-h"|"-?"|"--help")
	    helper_config
	    exit 0
	    ;;
	esac
	shift
done


####################
# Start
####################

cur_dir=$(pwd)

set -e
if [ 'unknown' == $(adb get-state) ]; then
	echo "Unknown device"
	exit -1
fi


####################
# Start
####################
TWO_DAY_AGO=$(date --date='2 days ago' +%s)

dir=$(mktemp -d -t captive.XXXXXXXXXXXX)
cd ${dir} 

default_dir=$(adb shell ls /data/b2g/mozilla/ | grep "default" | sed "s/\n//g" | sed "s/\r//g")
prefs_path="/data/b2g/mozilla/${default_dir}/prefs.js"

adb pull ${prefs_path}
cp prefs.js prefs.js.bak

echo -e "user_pref(\"app.update.url.override\", \"$URL\");" >> prefs.js
echo -e "user_pref(\"app.update.lastUpdateTime.background-update-timer\", $TWO_DAY_AGO);" >> prefs.js

adb push prefs.js ${prefs_path}
sleep 5
adb reboot

cd ${cur_dir}
rm -rf ${dir}
