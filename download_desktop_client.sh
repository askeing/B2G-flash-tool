#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for download last desktop from server.
#
# Author: Askeing fyen@mozilla.com
#==========================================================================

DOWNLOAD_DIR="B2G_Desktop"
Decompress_Flag=false
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
    echo -e "-d|--decompress\tDecompress the downloaded build."
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
        0|master) Version_Flag="0";;
        200|v2.0.0) Version_Flag="200";;
        140|v1.4.0) Version_Flag="140";;
        130|v1.3.0) Version_Flag="130";;
        120|v1.2.0) Version_Flag="120";;
        110|v1.1.0) Version_Flag="110";;
    esac
}

function version_info(){
    echo -e "Available version:"
    echo -e "\t0|master\tB2G master build"
    echo -e "\t200|v2.0.0\tB2G v2.0.0 build"
    echo -e "\t140|v1.4.0\tB2G v1.4.0 build"
    echo -e "\t130|v1.3.0\tB2G v1.3.0 build"
    echo -e "\t120|v1.2.0\tB2G v1.2.0 build"
    echo -e "\t110|v1.1.0\tB2G v1.1.0 build"
}

####################
# Load Config File (before load parameters)
####################
CONFIG_FILE=.download_desktop_client.conf
if [[ -f ${CONFIG_FILE} ]]; then
    . ${CONFIG_FILE}
else
    helper_config
    exit -2
fi

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o hdo::v:: --long help,decompress,os::,version:: \
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
        -d|--decompress) Decompress_Flag=true; shift;;
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
echo -e "Target: ${TARGET}"
eval URL=\${$TARGET}
echo -e "DL URL: ${URL}"
DownloadFilename=$(basename ${URL})


####################
# Download task
####################
BUILD_TXT_URL=${URL//tar.bz2/txt}
BUILD_JSON_URL=${URL//tar.bz2/json}

if [[ ! -d ${DOWNLOAD_DIR} ]]; then
    mkdir -p ${DOWNLOAD_DIR}/${Version_Flag}/
fi

## Get the Build ID of Build
BUILD_ID=`wget -qO- ${BUILD_TXT_URL} | head -n 1`
echo "BuildID: ${BUILD_ID}"
# record Latest Build ID
echo "BUILD_ID=${BUILD_ID}" > ${DOWNLOAD_DIR}/${Version_Flag}/VERSION-DESKTOP
TARGET_DIR=${DOWNLOAD_DIR}/${Version_Flag}/${BUILD_ID}

## Download B2G Desktop Build
if [ ${Download_Flag} == true ]; then
    ## Clean Folder
    rm -rf ${TARGET_DIR}

    # Download file
    echo -e "Download latest desktop client build (${DownloadFilename})..."
    wget -P ${TARGET_DIR}/ ${URL} &&
    wget -P ${TARGET_DIR}/ ${BUILD_TXT_URL} &&
    wget -P ${TARGET_DIR}/ ${BUILD_JSON_URL}

    # Check the download is okay
    if [ $? -ne 0 ]; then
        echo -e "Download ${URL} failed."
        exit 1
    fi

    echo -e "Download latest desktop client build done."
fi

####################
# Decompress task
####################

if [[ ! ${OS_Flag} == "mac" ]] && [[ ${Decompress_Flag} == true ]]; then
    Filename=${DownloadFilename}

    # Check the file is exist
    if [[ ! -z ${TARGET_DIR}/${Filename} ]]; then
        test ! -f ${TARGET_DIR}/${Filename} && echo -e "The file ${TARGET_DIR}/${Filename} DO NOT exist." && exit 1
    else
        echo -e "The file DO NOT exist." && exit 1
    fi

    # Delete folder
    echo -e "Delete folder: ${TARGET_DIR}/b2g"
    rm -rf ${TARGET_DIR}/b2g/

    # Unzip file
    echo -e "Unzip ${Filename} ..."
    tar xvf ${TARGET_DIR}/${Filename} -C ${TARGET_DIR}/ > /dev/null || exit -1
else
    echo "Mac desktop client, do not decompress."
fi

####################
# Done
####################
echo -e "Done!\nbyebye."

