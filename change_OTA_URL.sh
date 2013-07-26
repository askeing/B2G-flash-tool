#!/bin/bash
#==========================================================================
# Description:
#   This script was written for change OTA update URL.
#
# Author: Askeing fyen@mozilla.com
#
#==========================================================================

function find_prefs_path(){
    # distinguish platform
    case `uname` in
        "Linux")
            prefs_path=$(adb shell ls /data/b2g/mozilla/*.default/prefs.js | tr -d '\n' | tr -d '\r');;
        "Darwin")
            prefs_path=$(adb shell ls /data/b2g/mozilla/*.default/prefs.js | tr -d '\n' | tr -d '\r');;
    esac
}

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
    find_prefs_path
    adb shell cat ${prefs_path}
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

if [ "$URL" == "" ]; then
    helper_config
    exit -1
fi
echo "Updated URL: $URL"

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
TODAY=$(date +%s)
TWO_DAY_AGO=$((${TODAY} - 172800))

dir=$(mktemp -d -t captive.XXXXXXXXXXXX)
cd ${dir} 

find_prefs_path
adb pull ${prefs_path}
cp prefs.js prefs.js.bak

echo -e "user_pref(\"app.update.url.override\", \"$URL\");" >> prefs.js
echo -e "user_pref(\"app.update.lastUpdateTime.background-update-timer\", $TWO_DAY_AGO);" >> prefs.js

adb push prefs.js ${prefs_path}
sleep 5
adb reboot

cd ${cur_dir}
rm -rf ${dir}
