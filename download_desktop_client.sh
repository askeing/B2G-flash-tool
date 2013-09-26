#!/bin/bash
#==========================================================================
# Description:
#   This script was written for download last desktop from server.
#==========================================================================

Run_Once_Flag=false
Download_Flag=true
OS_Flag="LINUX_64"
Version_Flag="18"

## helper_config function
function helper_config(){
    echo -e "The config file error."
    echo -e "\tfilename: .download_desktop_client.conf"
    echo -e "\t===== File Content ====="
    echo -e "\tCONF_B2G18_LINUX_32_URL=https://path.to.B2G18_linux32bit.desktopclient.file/"
    echo -e "\tCONF_B2G18_LINUX_64_URL=https://path.to.B2G18_linux64bit.desktopclient.file/"
    echo -e "\tCONF_B2G18_MAC_URL=https://path.to.B2G18_mac.desktopclient.file/"
    echo -e "\tCONF_B2G26_LINUX_32_URL=https://path.to.B2G26_linux32bit.desktopclient.file/"
    echo -e "\tCONF_B2G26_LINUX_64_URL=https://path.to.B2G26_linux64bit.desktopclient.file/"
    echo -e "\tCONF_B2G26_MAC_URL=https://path.to.B2G26_mac.desktopclient.file/"
    echo -e "\t========================"
}

## helper function
## no input arguments, simply print helper descirption to std out
function helper(){
	echo -e "This script was written for download last desktop from server.\n"
	echo -e "Usage: ./download_desktop_client.sh [parameters]"
    echo -e "-o|--os \tThe target OS. Default: --os l64\n\t\tshow available OS if nothing specified."
    echo -e "-v|--version\tThe target build version. Default: -v18\n\t\tshow available version if nothing specified."
    echo -e "-r|--run-once\tRun once to get BuildID."
	echo -e "-h|--help\tDisplay help."
	echo -e "Example:"
	echo -e "  B2G 26 Linux 32bit build.\t./download_desktop_client.sh --os=l32 -v26"
	echo -e "  B2G 18 Linux 64bit build.\t./download_desktop_client.sh --os=l64 -v18"
	echo -e "  B2G 18 Mac build.\t./download_desktop_client.sh -omac"
	exit 0
}

## parameters parsing
## arg1: os for flash, if the version is not specified then default option will be taken
## output: set version to global $OS_Flag
function os(){
    local_ver=$1
    case "$local_ver" in
        l32) OS_Flag="LINUX_32";;
        l64) OS_Flag="LINUX_64";;
        mac) OS_Flag="MAC";;
    esac
}

function os_info(){
    echo -e "Available OS:"
    echo -e "\t--os=l32\tLinux 32bit desktop client"
    echo -e "\t--os=l64\tLinux 64bit desktop client"
    echo -e "\t--os=mac\tMac desktop client"
}

function version(){
    local_ver=$1
    case "$local_ver" in
        18) Version_Flag="18";;
        26) Version_Flag="26";;
        27) Version_Flag="27";;
    esac
}

function version_info(){
    echo -e "Available version:"
    echo -e "\t--version=18\tB2G 18"
    echo -e "\t--version=26\tB2G 26"
    echo -e "\t--version=27\tB2G 27"
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
if [ -z $CONF_B2G18_LINUX_32_URL ] || [ -z $CONF_B2G18_LINUX_64_URL ] || [ -z $CONF_B2G18_MAC_URL ]; then
    helper_config
    exit -2
fi
if [ -z $CONF_B2G26_LINUX_32_URL ] || [ -z $CONF_B2G26_LINUX_64_URL ] || [ -z $CONF_B2G26_MAC_URL ]; then
    helper_config
    exit -2
fi
if [ -z $CONF_B2G27_LINUX_32_URL ] || [ -z $CONF_B2G27_LINUX_64_URL ] || [ -z $CONF_B2G27_MAC_URL ]; then
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
	echo -e "Clean..."
	rm -f $DownloadFilename

	# Download file
	echo -e "Download latest desktop client build..."
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

