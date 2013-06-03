#!/bin/bash
#==========================================================================
# Description:
#   This script was written for download last desktop from server.
#==========================================================================

Download_Flag=true
Version_Flag="l64"

## helper_config function
function helper_config(){
    echo -e "The config file error."
    echo -e "\tfilename: .download_desktop_client.conf"
    echo -e "\t===== File Content ====="
    echo -e "\tCONF_LINUX_32_URL=https://path.to.linux32bit.desktopclient.file/"
    echo -e "\tCONF_LINUX_64_URL=https://path.to.linux64bit.desktopclient.file/"
    echo -e "\tCONF_MAC_URL=https://path.to.mac.desktopclient.file/"
    echo -e "\t========================"
}

## helper function
## no input arguments, simply print helper descirption to std out
function helper(){
	echo -e "This script was written for download last desktop from server.\n"
	echo -e "Usage: ./download_desktop_client.sh [parameters]"
    # -v, --version
    echo -e "-v|--version\tThe target build version. Default: -v64\n\t\tshow available version if nothing specified."
	# -h, --help
	echo -e "-h|--help\tDisplay help."
	echo -e "Example:"
	echo -e "  Linux 32bit build.\t./download_desktop_client.sh -v32"
	echo -e "  Linux 64bit build.\t./download_desktop_client.sh -v64"
	echo -e "  Mac build.\t./download_desktop_client.sh -vmac"
	exit 0
}

## version parsing
## arg1: version for flash, if the version is not specified then default option will be taken
## output: set version to global $Version_Flag
function version(){
    local_ver=$1
    case "$local_ver" in
        32) Version_Flag="l32";;
        64) Version_Flag="l64";;
        mac) Version_Flag="mac";;
    esac
}

function version_info(){
    echo -e "Available version:"
    echo -e "\t-v32\tLinux 32bit desktop client"
    echo -e "\t-v64\tLinux 64bit desktop client"
    echo -e "\t-vmac\tMac desktop client"
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
if [ -z $CONF_LINUX_32_URL ] || [ -z $CONF_LINUX_64_URL ] || [ -z $CONF_MAC_URL ]; then
    helper_config
    exit -2
fi


## distinguish platform
case `uname` in
	"Linux")
		## add getopt argument parsing
		TEMP=`getopt -o hv:: --long help,version:: \
	    -n 'error occured' -- "$@"`

		if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi

		eval set -- "$TEMP";;
	"Darwin");;
esac


while true
do
    case "$1" in
        -v|--version) 
           case "$2" in
            "") version_info; exit 0; shift 2;;
             *) version $2; shift 2;;
           esac;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) echo error occured; exit 1;;
    esac
done


####################
# Check Files
####################
# linux 32
if [ $Version_Flag == "l32" ]; then
    DownloadFilename=$(basename ${CONF_LINUX_32_URL})
	URL=${CONF_LINUX_32_URL}
# linux 64
elif [ $Version_Flag == "l64" ]; then
    DownloadFilename=$(basename ${CONF_LINUX_64_URL})
	URL=${CONF_LINUX_64_URL}
# mac
elif [ $Version_Flag == "mac" ]; then
    DownloadFilename=$(basename ${CONF_MAC_URL})
	URL=${CONF_MAC_URL}
fi

####################
# Download task
####################
if [ $Download_Flag == true ]; then
	# Clean file
	echo -e "Clean..."
	rm -f $DownloadFilename

	# Download file
	echo -e "Download latest desktop client build..."
    wget -q $URL

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

if ! [ ${Version_Flag} == "mac" ]; then
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
    grep "gecko.buildID" b2g/gaia/profile/prefs.js | sed "s/user_pref(\"//g" | sed "s/\");//g" | sed "s/\", \"/=/g" | sed "s/gecko.buildID=/GECKO_BUILD_ID=/g" > VERSION-DESKTOP
    cat VERSION-DESKTOP
else
    echo "Mac desktop client, do not decompress."
fi

####################
# Done
####################
echo -e "Done!\nbyebye."

