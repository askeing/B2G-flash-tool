#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for enable captive portal for v1.0.1 and above.
#
# Config file:
#   .enable_captiveportal.conf
#       CONF_URL=http://this.is.example/index.html
#       CONF_CONTENT=TEST_VALUE\\\n
#
#==========================================================================

function helper_config(){
    echo -e "-h, --help\tShow usage."
    echo -e "-s\t\tShow prefs file of device."
    echo ""
    echo -e "This script work with the config file."
    echo -e "\tfilename: .enable_captiveportal.conf"
    echo -e "\t===== File Content ====="
    echo -e "\tCONF_URL=http://this.is.example/index.html"
    echo -en "\t"; echo "CONF_CONTENT=TEST_VALUE\\\\\\n"
    echo -e "\t========================"
}

function show_prefs(){
    set -e
    if [ 'unknown' == $(adb get-state) ]; then
	    echo "Unknown device"
	    exit -1
    fi
    adb shell cat /data/b2g/mozilla/*.default/prefs.js
}

for x
do
	# -h, --help, -?: help
	if [ "$x" = "--help" ] || [ "$x" = "-h" ] || [ "$x" = "-?" ]; then
	    helper_config
		exit 0
	elif [ "$x" = "-s" ]; then
	    show_prefs
	    exit 0
	else
		echo -e "'$x' is an invalid command. See '--help'."
		exit 0
	fi
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
# Load Config File
####################
CONFIG_FILE=.enable_captiveportal.conf
if [ -f $CONFIG_FILE ]; then
    . $CONFIG_FILE
else
    helper_config
    exit -2
fi
if [ -z $CONF_URL ] || [ -z $CONF_CONTENT ]; then
    helper_config
    exit -2    
fi


####################
# Start
####################
dir=$(mktemp -d -t captive.XXXXXXXXXXXX)
cd ${dir} 

default_dir=$(adb shell ls /data/b2g/mozilla/ | grep "default" | sed "s/\n//g" | sed "s/\r//g")
prefs_path="/data/b2g/mozilla/${default_dir}/prefs.js"

adb pull ${prefs_path}
cp prefs.js prefs.js.bak

echo -e "user_pref(\"captivedetect.canonicalURL\", \"$CONF_URL\");" >> prefs.js
echo -e "user_pref(\"captivedetect.canonicalContent\", \"$CONF_CONTENT\");" >> prefs.js

adb push prefs.js ${prefs_path}
adb shell stop b2g
sleep 5
adb shell start b2g

cd ${cur_dir}
rm -rf ${dir}
