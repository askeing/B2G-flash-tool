#!/bin/bash
#==========================================================================
# 
# IMPORTANT: only for internal use!
# 
# Description:
#   This script was written for download builds from TW-CI server.
#
# Author: Askeing fyen@mozilla.com
# History:
#   2013/08/13 Askeing: v1.0 First release.
#   2013/08/14 Askeing: v1.1 Interaction GUI mode.
#   2013/10/11 Askeing: updated -f|--flash to -f|--full.
#   2013/11/13 Askeing: if flash gecko, then un-install com-ril. set KEEP_COMRIL=1 will skip this step.
#   2013/11/13 Askeing: removed KEEP_COMRIL, set UNINSTALL_COMRIL=true to un-install com-ril.
#
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

## Show usage
function helper(){
    echo -e "This script was written for download builds from TW-CI server.\n"
    echo -e "Usage: ./auto_flash_from_TWCI.sh [parameters]"
    echo -e "  -v|--version\tthe target build version."
    echo -e "  -d|--device\tthe target device."
    echo -e "  -s <serial number>\tdirects command to device with the given serial number."
    echo -e "  -f|--full\tflash full image into device."
    echo -e "  -g|--gaia\tshallow flash gaia into device."
    echo -e "  -G|--gecko\tshallow flash gecko into device."
    echo -e "  -w\t\tinteraction GUI mode."
    echo -e "  -y\t\tAssume \"yes\" to all questions"
    echo -e "  -h|--help\tdisplay help."
    echo -e "Environment:"
    echo -e "  UNINSTALL_COMRIL=true \tuninstall the com-ril when shallow flash gecko. (Keep com-ril by default)"
    echo -e "Example:"
    echo -e "  Flash unagi v1train image\t\t./auto_flash_from_TWCI.sh -vv1train -dunagi -f"
    echo -e "  Flash wasabi master gaia/gecko\t./auto_flash_from_TWCI.sh -vmaster -dwasabi -g -G"
    echo -e "  Flash by interaction GUI mode\t./auto_flash_from_TWCI.sh -w"
    exit 0
}


## Show the available version info
function version_info(){
    echo -e "Available version:"
    echo -e "  120|v1.2.0"
    echo -e "  110hd|v1.1.0hd"
#    echo -e "  110|v1train"
#    echo -e "  101|v1.0.1"
    echo -e "  0|master"
}


## Select the version
function version() {
    local_ver=$1
    case "$local_ver" in
        120|v1.2.0) VERSION_NAME="v1.2.0";;
        110hd|v1.1.0hd) VERSION_NAME="v1.1.0hd";;
#        110|v1train) VERSION_NAME="v1train";;
#        101|v1.0.1) VERSION_NAME="v101";;
        0|master) VERSION_NAME="master";;
        *) version_info; exit -1;;
    esac
    
}

## Show the available device info
function device_info(){
    print_list
    echo -e "Available device:"
    echo -e "  unagi"
#    echo -e "  inari"
#    echo -e "  leo"
    echo -e "  hamachi"
    echo -e "  buri"
    echo -e "  helix"
    echo -e "  wasabi"
    echo -e "  flatfish"
    echo -e "  nexus4"
}

## Select the device
function device() {
    local_ver=$1
    case "$local_ver" in
        unagi) DEVICE_NAME="unagi";;
#        inari) DEVICE_NAME="inari";;
#        leo) DEVICE_NAME="leo";;
        hamachi) DEVICE_NAME="hamachi";;
        buri) DEVICE_NAME="hamachi";;
        helix) DEVICE_NAME="helix";;
        wasabi) DEVICE_NAME="wasabi";;
        flatfish) DEVICE_NAME="flatfish";;
        nexus4) DEVICE_NAME="nexus4";;
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

## install dialog package for interaction GUI mode
function check_install_dialog() {
    if ! which dialog > /dev/null; then
        read -p "Package \"dialog\" not found! Install? [Y/n]" REPLY
        test "$REPLY" == "n" || test "$REPLY" == "N" && echo "byebye." && exit 0
        sudo apt-get install dialog
    fi
}

## Create the message for make sure dialog
function create_make_sure_msg() {
    MAKE_SURE_MSG="\n"
    MAKE_SURE_MSG+="Your Target Build: ${TARGET_NAME}\n"
    MAKE_SURE_MSG+="         Rev Info: ${TARGET_DESC}\n"
    MAKE_SURE_MSG+="            Flash: "
    if [ ${FLASH_FULL} == true ]; then
        MAKE_SURE_MSG+="Full Image."
    else
        if [ ${FLASH_GAIA} == true ]; then
            MAKE_SURE_MSG+="Gaia, "
        fi
        if [ ${FLASH_GECKO} == true ]; then
            MAKE_SURE_MSG+="Gecko, "
        fi
    fi
}

## make sure user want to flash/shallow flash
function make_sure() {
    read -p "Are you sure you want to flash your device? [y/N]" isFlash
    test "$isFlash" != "y" && test "$isFlash" != "Y" && echo "byebye." && exit 0
}

function make_sure_dialog() {
    case `uname` in
        "Linux")
            create_make_sure_msg
            MAKE_SURE_MSG+="\n\n\nAre you sure you want to flash your device?"
            dialog --backtitle "Confirm the Information " --title "Confirmation" --yesno "${MAKE_SURE_MSG}" 18 55 2>${TMP_DIR}/menuitem_makesure
            ret=$?
    
            if [ ${ret} == 1 ]; then
                echo "" && echo "byebye." && exit 0
            fi;;
        "Darwin")
            ret=$(osascript -e 'tell application "Terminal" to display dialog "Do you want to flash your device?" with title "Check Message"')
    esac
}

## Download the download list
function download_list() {
    CONFIG_FILE=.auto_flash_from_TWCI.conf
    if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
    else
        echo "Can NOT found the config file: $CONFIG_FILE"
        exit -1
    fi

    TWCI_DL_LIST=.TWCI_DL_LIST.conf
    rm -f ${TWCI_DL_LIST}
    echo "Updating DL List from TWCI..."
    wget -q $TWCI_DL_LIST_URL
    if [ -f $TWCI_DL_LIST ]; then
        . $TWCI_DL_LIST
    else
        echo "Cannot download the ${TWCI_DL_LIST} file from ${TWCI_DL_LIST_URL}"
        exit -1
    fi
}

## Print download list
function print_list() {
    echo "Available Builds:"
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_JOB_NAME
        eval VALUE=\$$KEY
        echo -e "  ${COUNT}) ${VALUE}"
    done
}

## Select build
function select_build() {
    print_list
    while [[ ${TARGET_ID} -lt 0 ]] || [[ ${TARGET_ID} -gt ${DL_SIZE} ]]; do
        read -p "What do you want to flash into your device? [Q to exit]" TARGET_ID
        test ${TARGET_ID} == "q" || test ${TARGET_ID} == "Q" && echo "byebye." && exit 0
    done
}

function select_build_dialog() {
    case `uname` in
        "Linux")
            MENU_FLAG=""
            for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
            do
                KEY=DL_${COUNT}_JOB_NAME
                eval VALUE=\$$KEY
                echo -e "${COUNT}) ${VALUE}"
                MENU_FLAG+=" ${COUNT} \"${VALUE}\""
            done
            dialog --backtitle "Select Build from TW-CI Server " --title "Download List" --menu "Move using [UP] [DOWN],[Enter] to Select" \
            18 55 10 ${MENU_FLAG} 2>${TMP_DIR}/menuitem_build
            ret=$?
            if [ ${ret} == 1 ]; then
                echo "" && echo "byebye." && exit 0
            fi
            menuitem_build=`cat ${TMP_DIR}/menuitem_build`
            case $menuitem_build in
                "") echo ""; echo "byebye."; exit 0;;
                *) TARGET_ID=$menuitem_build;;
            esac;;
        "Darwin")
            option_list=""
            for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
            do
                KEY=DL_${COUNT}_JOB_NAME
                eval VALUE=\$$KEY

                option_list=$option_list,\"${COUNT}-${VALUE}\"
            done
            local_option_list=${option_list#,*}
            eval ret=\$\(osascript -e \'tell application \"Terminal\" to choose from list \{$local_option_list\} with title \"Select Build\"\'\)
            echo $ret
            TARGET_ID=${ret%%-*};;
    esac
}

## Print flash mode
function print_flash_mode() {
    echo "Flash Mode:"
    echo "  1) Shallow flash Gaia/Gecko"
    echo "  2) Shallow flash Gaia"
    echo "  3) Shallow flash Gecko"
    echo "  4) Flash Full Image"
}

## Select flash mode
function select_flash_mode() {
    # if there are no flash flag, then ask
    while [ ${FLASH_FULL} == false ] && [ ${FLASH_GAIA} == false ] && [ ${FLASH_GECKO} == false ]; do
        print_flash_mode
        read -p "What do you want to flash? [Q to exit]" FLASH_INPUT
        test ${FLASH_INPUT} == "q" || test ${FLASH_INPUT} == "Q" && echo "byebye." && exit 0
        case $FLASH_INPUT in
            1) FLASH_GAIA=true; FLASH_GECKO=true;;
            2) FLASH_GAIA=true;;
            3) FLASH_GECKO=true;;
            4) FLASH_FULL=true;;
        esac
    done
}

function select_flash_mode_dialog() {
    case `uname` in
        "Linux")
            # if there are no flash flag, then ask
            if [ ${FLASH_FULL} == false ] && [ ${FLASH_GAIA} == false ] && [ ${FLASH_GECKO} == false ]; then
                dialog --backtitle "Select Build from TW-CI Server " --title "Flash Mode" --menu "Move using [UP] [DOWN],[Enter] to Select" \
                18 55 10 1 "Shallow flash Gaia/Gecko" 2 "Shallow flash Gaia" 3 "Shallow flash Gecko" 4 "Flash Full Image" 2>${TMP_DIR}/menuitem_flash
                ret=$?
                if [ ${ret} == 1 ]; then
                    echo "" && echo "byebye." && exit 0
                fi
                menuitem_flash=`cat ${TMP_DIR}/menuitem_flash`
                case $menuitem_flash in
                    "") echo ""; echo "byebye."; exit 0;;
                    1) FLASH_GAIA=true; FLASH_GECKO=true;;
                    2) FLASH_GAIA=true;;
                    3) FLASH_GECKO=true;;
                    4) FLASH_FULL=true;;
                esac
            fi;;
        "Darwin")
            ret=$(osascript -e 'tell application "Terminal" to choose from list {"1-Flash Gaia and Gecko", "2-Flash Gaia", "3-Flash Gecko", "4-Flash Full Image"}')
            echo $ret
            case ${ret%%-*} in
                "") echo ""; echo "byebye."; exit 0;;
                1) FLASH_GAIA=true; FLASH_GECKO=true;;
                2) FLASH_GAIA=true;;
                3) FLASH_GECKO=true;;
                4) FLASH_FULL=true;;
            esac;;
    esac
}

## Find the download build's info
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

## Print flash info
function print_flash_info() {
    echo    "Your Target Build: ${TARGET_NAME}"
    echo    "         Rev Info: ${TARGET_DESC}"
    echo -n "            Flash: "
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

function print_flash_info_dialog() {
    create_make_sure_msg
    if [ -e ./check_versions.sh ]; then
        MAKE_SURE_MSG+="\n\n"
        MAKE_SURE_MSG+=`bash ./check_versions.sh | sed ':a;N;$!ba;s/\n/\\\n/g'`
    fi
    case `uname` in
        "Linux")
            dialog --backtitle "Flash Information " --title "Done" --msgbox "${MAKE_SURE_MSG}" 15 55 2>${TMP_DIR}/menuitem_done ;;
    esac
}

function downlaod_file_from_TWCI() {
    DL_URL=$1
    DL_FILE=$2
    DEST_DIR=$3
    echo ""
    echo "Download file: ${DL_URL}artifact/${DL_FILE}"
    wget -P ${DEST_DIR} ${DL_URL}artifact/${DL_FILE}
}

## Shallow flash gaia/gecko
function do_shallow_flash() {
    SHALLOW_FLAG+=$ADB_FLAGS
    if [ ${FLASH_GAIA} == true ]; then
        downlaod_file_from_TWCI ${TARGET_URL} ${TARGET_GAIA} ${TMP_DIR}
        GAIA_BASENAME=`basename ${TMP_DIR}/${TARGET_GAIA}`
        case `uname` in
            "Linux") SHALLOW_FLAG+=" -g${TMP_DIR}/${GAIA_BASENAME}";;
            "Darwin") SHALLOW_FLAG+=" -g ${TMP_DIR}/${GAIA_BASENAME}";;
        esac
    fi
    if [ ${FLASH_GECKO} == true ]; then
        downlaod_file_from_TWCI ${TARGET_URL} ${TARGET_GECKO} ${TMP_DIR}
        GECKO_BASENAME=`basename ${TMP_DIR}/${TARGET_GECKO}`
        case `uname` in
            "Linux") SHALLOW_FLAG+=" -G${TMP_DIR}/${GECKO_BASENAME}";;
            "Darwin") SHALLOW_FLAG+=" -G ${TMP_DIR}/${GECKO_BASENAME}";;
        esac
        ## if flash gecko and UNINSTALL_COMRIL=true, then un-install com-ril.
        if [ -e ./uninstall_comril.sh ] && [[ ${UNINSTALL_COMRIL} == true ]]; then
            echo "Un-install com-ril..."
            bash ./uninstall_comril.sh -u -y
        fi
    fi
    SHALLOW_FLAG+=" -y"
    if [ -e ./shallow_flash.sh ]; then
        echo "./shallow_flash.sh ${SHALLOW_FLAG}"
        bash ./shallow_flash.sh ${SHALLOW_FLAG}
        ret=$?
        if ! [ ${ret} == 0 ]; then
            echo "Shallow Flash failed."
            exit -1
        fi
    else
        echo -e "There is no shallow_flash.sh in your folder."
    fi
}

## Flash full image
function do_flash_image() {
    downlaod_file_from_TWCI ${TARGET_URL} ${TARGET_IMG} ${TMP_DIR}
    IMG_BASENAME=`basename ${TMP_DIR}/${TARGET_IMG}`
    unzip -d ${TMP_DIR} ${TMP_DIR}/${IMG_BASENAME}
    CURRENT_DIR=`pwd`
    cd ${TMP_DIR}/b2g-distro/

    ## if no DEVICE_NAME (GUI mode), then find the DEVICE_NAME from TARGET_NAME
    if [[ ${DEVICE_NAME} == "" ]]; then
        IFS="." read -a TEMP_NAMES <<< "${TARGET_NAME}"
        TEMP_NAMES_SIZE=${#TEMP_NAMES[@]}
        let TEMP_NAMES_INDEX=${TEMP_NAMES_SIZE}-1
        TEMP_NAMES_KEY=TEMP_NAMES[${TEMP_NAMES_INDEX}]
        eval DEVICE_NAME=\${$TEMP_NAMES_KEY}
    fi

    ## flash flatfish device
    if [[ ${DEVICE_NAME} == "flatfish" ]]; then
        echo "Flash by flash_flatfish.sh script..."
        bash ./flash_flatfish.sh
    ## flash other devices
    else
        bash ./flash.sh
    fi

    ret=$?
    if ! [ ${ret} == 0 ]; then
        echo "Flash image failed."
        exit -1
    fi
    cd ${CURRENT_DIR}
}


#########################
# Create TEMP Folder    #
#########################
if ! which mktemp > /dev/null; then
    echo "Package \"mktemp\" not found!"
    rm -rf ./autoflashfromTWCI_temp
    mkdir autoflashfromTWCI_temp
    cd autoflashfromTWCI_temp
    TMP_DIR=`pwd`
    cd ..
else
    rm -rf /tmp/autoflashfromTWCI.*
    TMP_DIR=`mktemp -d -t autoflashfromTWCI.XXXXXXXXXXXX`
fi


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
        TEMP=`getopt -o v::d::s::gGfwyh --long version::,device::,gaia,gecko,full,help \
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
        -f|--full) FLASH_FULL=true; shift;;
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

## Disable GUI mode for MAC OS X, issue #20 will reslove it.
# case `uname` in
#     "Darwin") INTERACTION_WINDOW=false;;
# esac


##################################################
# For interaction GUI mode, check dialog package #
##################################################
if [ ${INTERACTION_WINDOW} == true ]; then
    case `uname` in
        "Linux") check_install_dialog;;
    esac
fi


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


###################################################################################
# If can NOT find the flash mode from user input parameters, list the flash mode. #
###################################################################################
if [ ${INTERACTION_WINDOW} == false ]; then
    select_flash_mode
else
    select_flash_mode_dialog
fi


####################################
# Find the name of download files. #
####################################
find_download_files_name
if [ ${INTERACTION_WINDOW} == false ]; then
    print_flash_info
    if [ ${VERY_SURE} == false ]; then
        make_sure
    fi
else
    if [ ${VERY_SURE} == false ]; then
        make_sure_dialog
    fi
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

####################
# Version          #
####################
echo "================="
echo "Flash Information"
echo "================="
if [ ${INTERACTION_WINDOW} == false ]; then
    print_flash_info
    if [ -e ./check_versions.sh ]; then
        bash ./check_versions.sh
    fi
    echo "Done."
else
    case `uname` in
        "Linux") print_flash_info_dialog;;
        "Darwin") print_flash_info;;
    esac
fi


#########################
# Remove Temp Folder    #
#########################
rm -rf ${TMP_DIR}

