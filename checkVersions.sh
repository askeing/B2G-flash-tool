#!/bin/bash

set -e
#echo "Plug in your device"
#adb wait-for-device
#echo "Found device"
if [ 'unknown' == $(adb get-state) ]; then
	echo "Unknown device"
	exit -1
fi

dir=$(mktemp -d -t revision.XXXXXXXXXXXX)
cp optimizejars.py $dir
cd $dir 

adb pull /system/b2g/omni.ja &>/dev/null || echo "Error pulling gecko"
adb pull /data/local/webapps/settings.gaiamobile.org/application.zip &> /dev/null || \
adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip &> /dev/null || echo "Error pulling gaia file"
adb pull /system/b2g/application.ini &> /dev/null || echo "Error pulling application.ini"

if [ -f omni.ja ] && [ -f application.zip ] && [ -f application.ini ]; then
        python optimizejars.py --deoptimize ./ ./ ./ &> /dev/null
	unzip omni.ja chrome/toolkit/content/global/buildconfig.html > /dev/null
	unzip application.zip resources/gaia_commit.txt > /dev/null
	
	echo 'Gaia:    ' $(head -n 1 resources/gaia_commit.txt)
	echo '  B-D    ' $(date --date=@$(cat resources/gaia_commit.txt | sed -n 2p) +"%Y-%m-%d %H:%M:%S")
	
	echo 'Gecko:   ' $(grep "Built from" chrome/toolkit/content/global/buildconfig.html | sed "s,.*<a href=\",,g ; s,\">.*,,g")
	
	for i in BuildID Version ; do
	    echo $i ' ' $(grep "^ *$i" application.ini | sed "s,.*=,,g")
	done
fi

rm -rf $dir
