#!/bin/bash
#==========================================================================
# Description:
#   This script was written for download last desktop from server.
#==========================================================================

Run_Once_Flag=false
Download_Flag=true
OS_Flag="LINUX_64"
Version_Flag="0"

## helper_config function
function helper_config(){
    echo -e "The config file (.download_desktop_client.conf) error."
}

## helper function
## no input arguments, simply print helper descirption to std out
function helper(){
	echo -e "This script was written for download last desktop from server.\n"
	echo -e "Usage: ./download_desktop_client.sh [parameters]"
    echo -e "-o|--os \tThe target OS. Default: linux64\n\t\tshow available OS if nothing specified."
    echo -e "-v|--version\tThe target build version. Default: master\n\t\tshow available version if nothing specified."
    echo -e "-r|--run-once\tRun once to get BuildID."
	echo -e "-h|--help\tDisplay help."
	echo -e "Example:"
	echo -e "  B2G v1.2.0 Linux 32bit build.\t./download_desktop_client.sh --os=l32 --version=120"
	echo -e "  B2G v1.1.0 Linux 64bit build.\t./download_desktop_client.sh -ol64 -v110"
	echo -e "  B2G master Mac build.\t./download_desktop_client.sh -omac"
	exit 0
}

## parameters parsing
## arg1: os for flash, if the version is not specified then default option will be taken
## output: set version to global $OS_Flag
function os(){
    local_ver=$1
    case "$local_ver" in
        l32|linux32) OS_Flag="LINUX_32";;
        l64|linux64) OS_Flag="LINUX_64";;
        mac) OS_Flag="MAC";;
    esac
}

function os_info(){
    echo -e "Available OS:"
    echo -e "\tl32|linux32\tLinux 32bit desktop client"
    echo -e "\tl64|linux64\tLinux 64bit desktop client"
    echo -e "\tmac\tMac desktop client"
}

function version(){
    local_ver=$1
    case "$local_ver" in
        110|v1.1.0) Version_Flag="110";;
        120|v1.2.0) Version_Flag="120";;
        0|master) Version_Flag="0";;
    esac
}

function version_info(){
    echo -e "Available version:"
    echo -e "\t110|v1.1.0\tB2G v1.1.0 build"
    echo -e "\t120|v1.2.0\tB2G v1.2.0 build"
    echo -e "\t0|master\tB2G master build"
}

####################
# Load Config File (before load parameters)
####################
CONFIG_FILE=.download_desktop_client.conf
if [ -f $CONFIG_FILE ]; then
    . $CONFIG_FILE
else
    helper_config
    exit -2
fi

## distinguish platform
case `uname` in
	"Linux")
		## add getopt argument parsing
		TEMP=`getopt -o hro::v:: --long help,run-once,os::,version:: \
	    -n 'error occured' -- "$@"`

		if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi

		eval set -- "$TEMP";;
	"Darwin");;
esac


while true
do
    case "$1" in
        -o|--os)
           case "$2" in
            "") os_info; exit 0; shift 2;;
             *) os $2; shift 2;;
           esac;;
        -v|--version) 
           case "$2" in
            "") version_info; exit 0; shift 2;;
             *) version $2; shift 2;;
           esac;;
        -r|--run-once) Run_Once_Flag=true; shift;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) echo error occured; exit 1;;
    esac
done

####################
# Parse URL
####################
TARGET=CONF_B2G${Version_Flag}_${OS_Flag}_URL
echo -e "Target: $TARGET"
eval URL=\$$TARGET
echo -e "DL URL: $URL"
DownloadFilename=$(basename ${URL})


####################
# Download task
####################
if [ $Download_Flag == true ]; then
	# Clean file
	echo -e "Clean downloaded build ($DownloadFilename)..."
	rm -f $DownloadFilename

	# Download file
	echo -e "Download latest desktop client build ($DownloadFilename)..."
    wget $URL

	# Check the download is okay
	if [ $? -ne 0 ]; then
		echo -e "Download $URL failed."
		exit 1
	fi

	echo -e "Download latest desktop client build done."
fi

####################
# Decompress task
####################

if ! [ ${OS_Flag} == "mac" ] && [ $Run_Once_Flag == true ]; then
    Filename=${DownloadFilename}

    # Check the file is exist
    if ! [ -z $Filename ]; then
        test ! -f $Filename && echo -e "The file $Filename DO NOT exist." && exit 1
    else
        echo -e "The file DO NOT exist." && exit 1
    fi

    # Delete folder
    echo -e "Delete old build folder: b2g"
    rm -rf b2g/

    # Unzip file
    echo -e "Unzip $Filename ..."
    tar xvf $Filename > /dev/null || exit -1

    # version info
    echo -e "\nRunning b2g to get BuildID..."
    echo "user_pref('marionette.force-local', true);" >> ./b2g/gaia/profile/user.js
    ./b2g/b2g > /dev/null &
    PID=$!
    sleep 15
    echo -e "Kill b2g..."
    kill $PID
    echo -e "\n=== VERSION ==="
    grep "gecko.buildID" ./b2g/gaia/profile/prefs.js | sed "s/user_pref(\"//g" | sed "s/\");//g" | sed "s/\", \"/=/g" | sed "s/gecko.buildID=/GECKO_BUILD_ID=/g" > VERSION-DESKTOP
    RET=$?
    if ! [ $RET == 0 ]; then
        echo "GECKO_BUILD_ID=None" > VERSION-DESKTOP
    fi
    cat VERSION-DESKTOP
else
    echo "Mac desktop client, do not decompress."
fi

####################
# Done
####################
echo -e "Done!\nbyebye."

