#!/bin/bash

cur_dir=$(pwd)

set -e
if [ 'unknown' == $(adb get-state) ]; then
	echo "Unknown device"
	exit -1
fi

dir=$(mktemp -d -t captive.XXXXXXXXXXXX)
cd ${dir} 

default_dir=$(adb shell ls /data/b2g/mozilla/ | grep "default" | sed "s/\n//g" | sed "s/\r//g")
prefs_path="/data/b2g/mozilla/${default_dir}/prefs.js"

adb pull ${prefs_path}
cp prefs.js prefs.js.bak

echo -e "user_pref(\"captivedetect.canonicalURL\", \"http://people.mozilla.org/~schien/test.txt\");" >> prefs.js
echo -e "user_pref(\"captivedetect.canonicalContent\", \"true\\\n\");" >> prefs.js

adb push prefs.js ${prefs_path}
adb shell stop b2g
sleep 5
adb shell start b2g

cd ${cur_dir}
rm -rf ${dir}
