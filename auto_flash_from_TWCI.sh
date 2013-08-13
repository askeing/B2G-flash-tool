#!/bin/bash
#==========================================================================
# 
# IMPORTANT: only for internal use!
# 
# Description:
#   his script was written for download builds from TW-CI server.
#
# Author: Askeing fyen@mozilla.com
# History:
#   2013/08/13 Askeing: v1.0 First release.
#==========================================================================


####################
# Parameter Flags  #
####################
VERY_SURE=false
INTERACTION_WINDOW=false
ADB_DEVICE="Device"
DEVICE_NAME=""
VERSION_NAME=""
FLASH_FULL=false
FLASH_GAIA=false
FLASH_GECKO=false
FLASH_FULL_IMG_FILE=""
FLASH_GAIA_FILE=""
FLASH_GECKO_FILE=""
TARGET_ID=-1


####################
# Functions        #
####################

function hello() {
	echo 'hello world'
}

function helper(){
	echo -e "This script was written for download builds from TW-CI server."
	echo -e "Usage: ./auto_flash_from_TWCI.sh [parameters]"
    echo -e "  -v|--version\tthe target build version."
    echo -e "  -d|--device\tthe target device."
    echo -e "  -s <serial number>\tdirects command to device with the given serial number."
    echo -e "  -f|--flash\tflash image into device."
    echo -e "  -g|--gaia\tshallow flash gaia into device."
    echo -e "  -G|--Gecko\tshallow flash gecko into device."
    echo -e "  -w\t\tinteraction window mode."
    echo -e "  -y\t\tflash the file without asking askeing (it's a joke...)"
	echo -e "  -h|--help\tdisplay help."
	echo -e "Example:"
	echo -e "  Flash unagi v1train image\t\t./auto_flash_from_TWCI.sh -vv1train -dunagi -f"
	echo -e "  Flash wasabi master gaia/gecko\t./auto_flash_from_TWCI.sh -vmaster -dwasabi -g -G"
	echo -e "  Flash by interaction window mode\t./auto_flash_from_TWCI.sh -w"
	exit 0
}

function version_info(){
    print_list
    echo -e "Available version:"
    echo -e "  110hd|v1.1.0hd"
    echo -e "  110|v1train"
    echo -e "  0|master"
}

function version() {
    local_ver=$1
    case "$local_ver" in
        110hd|v1.1.0hd) VERSION_NAME="v1.1.0hd";;
        110|v1train) VERSION_NAME="v1train";;
        0|master) VERSION_NAME="master";;
        *) version_info; exit -1;;
    esac
    
}

function device_info(){
    print_list
    echo -e "Available device:"
    echo -e "  unagi"
    echo -e "  inari"
    echo -e "  leo"
    echo -e "  helix"
    echo -e "  wasabi"
}

function device() {
    local_ver=$1
    case "$local_ver" in
        unagi) DEVICE_NAME="unagi";;
        inari) DEVICE_NAME="inari";;
        leo) DEVICE_NAME="leo";;
        helix) DEVICE_NAME="helix";;
        wasabi) DEVICE_NAME="wasabi";;
        *) device_info; exit -1;;
    esac
    
}

## adb with flags
function run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
	adb $ADB_FLAGS $@
}

## make sure user want to shallow flash
function make_sure() {
    read -p "Are you sure you want to flash your device? [y/N]" isFlash
    test "$isFlash" != "y"  && test "$isFlash" != "Y" && echo -e "byebye." && exit 0
}

function download_list() {
    CONFIG_FILE=.auto_flash_from_TWCI.conf
    if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
    fi

    TWCI_DL_LIST=.TWCI_DL_LIST.conf
    rm -f ${TWCI_DL_LIST}
    echo "Updating DL List from TWCI..."
    wget -q $TWCI_DL_LIST_URL
    if [ -f $TWCI_DL_LIST ]; then
        . $TWCI_DL_LIST
    else
        echo "Cannot download the ${TWCI_DL_LIST} file from ${TWCI_DL_LIST_URL}"
    fi
}

function print_list() {
    echo "Available Builds:"
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_JOB_NAME
        eval VALUE=\$$KEY
        echo -e "  ${COUNT}) ${VALUE}"
    done
}

function select_build() {
    print_list
    while [[ ${TARGET_ID} -lt 0 ]] || [[ ${TARGET_ID} -gt ${DL_SIZE} ]]; do
	    read -p "What do you want to flash into your device? [Q to exit]" TARGET_ID
        test ${TARGET_ID} == "q" || test ${TARGET_ID} == "Q" && echo "byebye." && exit 0
    done
}

function select_build_dialog() {
    MENU_FLAG=""
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_JOB_NAME
        eval VALUE=\$$KEY
        echo -e "${COUNT}) ${VALUE}"
        MENU_FLAG+=" ${COUNT} \"${VALUE}\""
    done
    echo ${MENU_FLAG}
    dialog --backtitle "Select Build from TW-CI Server " --title "Download List" --menu "Move using [UP] [DOWN],[Enter] to Select" \
    15 50 10 \
    ${MENU_FLAG} 2>${TMP_DIR}/menuitem
    
    menuitem=`cat ${TMP_DIR}/menuitem`
    #opt=$?
    case $menuitem in
        "") echo ""; echo "byebye."; exit 0;;
        *) TARGET_ID=$menuitem;;
    esac
}

function find_download_files_name() {
    TARGET_NAME_KEY=DL_${TARGET_ID}_JOB_NAME
    eval TARGET_NAME=\$$TARGET_NAME_KEY

    TARGET_DESC_KEY=DL_${TARGET_ID}_DESC
    eval TARGET_DESC=\$$TARGET_DESC_KEY

    TARGET_URL_KEY=DL_${TARGET_ID}_URL
    eval TARGET_URL=\$$TARGET_URL_KEY

    TARGET_IMG_KEY=DL_${TARGET_ID}_ARTIFACT_B2G_IMG
    eval TARGET_IMG=\$$TARGET_IMG_KEY
    
    TARGET_GAIA_KEY=DL_${TARGET_ID}_ARTIFACT_GAIA
    eval TARGET_GAIA=\$$TARGET_GAIA_KEY

    TARGET_GECKO_KEY=DL_${TARGET_ID}_ARTIFACT_GECKO
    eval TARGET_GECKO=\$$TARGET_GECKO_KEY
}

function print_flash_info() {
    echo    ""
    echo    "Your Taget Build: ${TARGET_NAME}"
    echo    "        Rev Info: ${TARGET_DESC}"
    echo -n "           Flash: "
    if [ ${FLASH_FULL} == true ]; then
        echo -n "Full Image."
    else
        if [ ${FLASH_GAIA} == true ]; then
            echo -n "Gaia, "
        fi
        if [ ${FLASH_GECKO} == true ]; then
            echo -n "Gecko, "
        fi
    fi
    echo ""
}

function downlaod_file_from_TWCI() {
    DL_URL=$1
    DL_FILE=$2
    DEST_DIR=$3
    echo "Download file: ${DL_URL}artifact/${DL_FILE}"
    wget -q -P ${DEST_DIR} ${DL_URL}artifact/${DL_FILE}
}

function do_shallow_flash() {
    SHALLOW_FLAG+=$ADB_FLAGS
    if [ ${FLASH_GAIA} == true ]; then
        downlaod_file_from_TWCI ${TARGET_URL} ${TARGET_GAIA} ${TMP_DIR}
        GAIA_BASENAME=`basename ${TMP_DIR}/${TARGET_GAIA}`
        SHALLOW_FLAG+=" -g${TMP_DIR}/${GAIA_BASENAME}"
    fi
    if [ ${FLASH_GECKO} == true ]; then
        downlaod_file_from_TWCI ${TARGET_URL} ${TARGET_GECKO} ${TMP_DIR}
        GECKO_BASENAME=`basename ${TMP_DIR}/${TARGET_GECKO}`
        SHALLOW_FLAG+=" -G${TMP_DIR}/${GECKO_BASENAME}"
    fi
    SHALLOW_FLAG+=" -y"
    if [ -e ./shallow_flash.sh ]; then
        echo "./shallow_flash.sh ${SHALLOW_FLAG}"
        bash ./shallow_flash.sh ${SHALLOW_FLAG}
    else
        echo -e "There is no shallow_flash.sh in your folder."
    fi
}

function do_flash_image() {
    downlaod_file_from_TWCI ${TARGET_URL} ${TARGET_IMG} ${TMP_DIR}
    IMG_BASENAME=`basename ${TMP_DIR}/${TARGET_IMG}`
    unzip -d ${TMP_DIR} ${TMP_DIR}/${IMG_BASENAME}
    CURRENT_DIR=`pwd`
    cd ${TMP_DIR}/b2g-distro/
    bash ./flash.sh
    cd ${CURRENT_DIR}
}


#########################
# Create TEMP Folder    #
#########################
TMP_DIR=`mktemp -d`


#########################
# Download TWCI List    #
#########################
download_list


#########################
# Processing Parameters #
#########################

## show helper if nothing specified
if [ $# = 0 ]; then echo "Nothing specified"; helper; exit 0; fi

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o v::d::s::gGfwyh --long version::,device::,gaia,gecko,flash,help \
        -n 'invalid option' -- "$@"`

        if [ $? != 0 ]; then echo "Try '--help' for more information." >&2; exit 1; fi

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
            esac ;;
        -d|--device)
            case "$2" in
                "") device_info; exit 0; shift 2;;
                *) device $2; shift 2;;
            esac ;;
        -s)
            case "$2" in
                "") shift 2;;
                *) ADB_DEVICE=$2; ADB_FLAGS+="-s $2"; shift 2;;
            esac ;;
        -f|--flash) FLASH_FULL=true; shift;;
        -g|--gaia) FLASH_GAIA=true; shift;;
        -G|--gecko) FLASH_GECKO=true; shift;;
        -w) INTERACTION_WINDOW=true; shift;;
        -y) VERY_SURE=true; shift;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) helper; echo error occured; exit 1;;
    esac
done


#############################################
# Find the B2G.${VERSION}.${DEVICE} in list #
#############################################
FOUND=false
TARGET_NAME=B2G.${VERSION_NAME}.${DEVICE_NAME}
for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
do
    KEY=DL_${COUNT}_JOB_NAME
    eval VALUE=\$$KEY
    
    if [ ${TARGET_NAME} == ${VALUE} ]; then
        echo "${TARGET_NAME} is found!!"
        FOUND=true
        TARGET_ID=${COUNT}
    fi
done


##########################################################################################
# If can NOT find the target from user input parameters, list the download list to user. #
##########################################################################################
if [ ${FOUND} == false ]; then
    echo "Can NOT found the ${TARGET_NAME}"
    echo "Please select one build from following list."
    if [ ${INTERACTION_WINDOW} == false ]; then
        select_build
    else
        select_build_dialog
    fi
fi


####################################
# Find the name of download files. #
####################################
find_download_files_name
print_flash_info
if [ ${VERY_SURE} == false ]; then
    make_sure
fi


##################################
# Flash full image OR gaia/gecko #
##################################
if [ ${FLASH_FULL} == true ]; then
    echo "Flash Full Image..."
    do_flash_image
elif [ ${FLASH_GAIA} == true ] || [ ${FLASH_GECKO} == true ]; then
    echo "Shallow Flash..."
    do_shallow_flash
fi

###################
# Version          #
####################
if [ -e ./check_versions.sh ] && [ ${FLASH_FULL} == true ]; then
    bash ./check_versions.sh
fi
print_flash_info
echo "Done."

#########################
# Remove Temp Folder    #
#########################
rm -rf ${TMP_DIR}


exit 0





TMP_DIR=`mktemp -d`

dialog --backtitle "Select Build from TW-CI Server " --title "Main Menu" --menu "Move using [UP] [DOWN],[Enter] to Select" \
15 50 3 \
1 "Shows Date and Time" 2 "To see calendar " 3 "To start vi editor " 2>${TMP_DIR}/menuitem

menuitem=`cat ${TMP_DIR}/menuitem`

opt=$?

case $menuitem in
Date/time) date;;
Calendar) cal;;
Editor) hello;;
esac

rm -rf ${TMP_DIR}
#clear
