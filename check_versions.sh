#!/bin/bash

set -e

function helper(){
    echo "-s <serial number>            - directs command to the USB device or emulator with"
    echo "                                 the given serial number. Overrides ANDROID_SERIAL"
    echo "                                 environment variable."
    echo "-h | --help                   - print usage."
    exit 0
}

run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
	adb $ADB_FLAGS $@
}


# argument parsing
while [ $# -gt 0 ]; do
	case "$1" in
	"-s")
		ADB_FLAGS+="-s $2"
		shift
		;;
	"-h"|"--help")
	    helper
	    exit 0
	    ;;
	esac
	shift
done


if [ 'unknown' == $(run_adb get-state) ]; then
	echo "Unknown command..."
	adb devices
	exit -1
fi

dir=$(mktemp -d -t revision.XXXXXXXXXXXX)
cp optimizejars.py $dir
cd $dir 

run_adb pull /system/b2g/omni.ja &>/dev/null || echo "Error pulling gecko"
run_adb pull /data/local/webapps/settings.gaiamobile.org/application.zip &> /dev/null || \
run_adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip &> /dev/null || echo "Error pulling gaia file"
run_adb pull /system/b2g/application.ini &> /dev/null || echo "Error pulling application.ini"

if [ -f omni.ja ] && [ -f application.zip ] && [ -f application.ini ]; then
	python optimizejars.py --deoptimize ./ ./ ./ &> /dev/null
	unzip omni.ja chrome/toolkit/content/global/buildconfig.html > /dev/null
	unzip application.zip resources/gaia_commit.txt > /dev/null
	
	echo 'Gaia:    ' $(head -n 1 resources/gaia_commit.txt)
	echo '  B-D    ' $(date --date=@$(cat resources/gaia_commit.txt | sed -n 2p) +"%Y-%m-%d %H:%M:%S")
	
	echo 'Gecko:   ' $(grep "Built from" chrome/toolkit/content/global/buildconfig.html | sed "s,.*\">,,g ; s,</a>.*,,g")
	
	for i in BuildID Version ; do
	    echo $i ' ' $(grep "^ *$i" application.ini | sed "s,.*=,,g")
	done
fi

rm -rf $dir

