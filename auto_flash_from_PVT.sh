#!/bin/bash
#==========================================================================
# 
# IMPORTANT: only for internal use!
# 
# Description:
#   This script was written for download builds from PVT server.
#
# Author: Askeing fyen@mozilla.com
# History:
#   2013/08/16 Askeing: v1.0 First release.
#   2013/09/25 Askeing: added v1.2.0 and changed the seqence of flash mode.
#   2013/09/25 Askeing: removed the pwd of wget when using command mode.
#   2013/09/26 Askeing: fixed the HTTP_PWD issue.
#   2013/10/07 Al: added buildID support on Mac.
#   2013/10/09 Askeing: added buildID support on Linux.
#   2013/10/09 Askeing: modified the seqence of flash mode in command mode.
#   2013/10/09 Askeing: added download failed message for wget.
#   2013/10/09 Askeing: rename -b|--build to -b|--buildid.
#   2013/10/11 Askeing: updated -f|--flash to -f|--full.
#
#==========================================================================

## Get the newest build
git checkout master
git pull --rebase

####################
# Parameter Flags  #
####################
VERY_SURE=false
INTERACTION_WINDOW=false
ADB_DEVICE="Device"
DEVICE_NAME=""
VERSION_NAME=""
BUILD_ID=""
FLASH_FULL=false
FLASH_GAIA=false
FLASH_GECKO=false
FLASH_FULL_IMG_FILE=""
FLASH_GAIA_FILE=""
FLASH_GECKO_FILE=""
TARGET_ID=-1
FLASH_USR_IF_POSSIBLE=false
FLASH_ENG_IF_POSSIBLE=false
FLASH_USER_ENG_DONE=false


####################
# Functions        #
####################

## Show usage
function helper(){
	echo -e "This script was written for download builds from PVT server.\n"
	echo -e "Usage: ./auto_flash_from_PVT.sh [parameters]"
    echo -e "Environment: HTTP_USER={username} HTTP_PWD={pwd}"
    echo -e "             or you can fill it into .ldap file."
    echo -e "  -v|--version\tthe target build version."
    echo -e "  -d|--device\tthe target device."
    echo -e "  -s <serial number>\tdirects command to device with the given serial number."
    echo -e "  -f|--full\tflash full image into device."
    echo -e "  -g|--gaia\tshallow flash gaia into device."
    echo -e "  -G|--Gecko\tshallow flash gecko into device."
    echo -e "  --usr\tspecify User(USR) build."
    echo -e "  --eng\tspecify Engineer(ENG) build."
    echo -e "  -b|--buildid\tspecify target build YYYYMMDDhhmmss"
    echo -e "  -w\t\tinteraction GUI mode."
    echo -e "  -y\t\tAssume \"yes\" to all questions"
	echo -e "  -h|--help\tdisplay help."
	echo -e "Example:"
	echo -e "  Flash unagi v1train image\t\t\t./auto_flash_from_PVT.sh -v110 -dunagi -f"
	echo -e "  Flash unagi v1train ENG build image\t\t./auto_flash_from_PVT.sh -v110 -dunagi --eng -f"
	echo -e "  Flash inari v1.0.1 gaia/gecko\t\t\t./auto_flash_from_PVT.sh -v101 -dinari -g -G"
	echo -e "  Flash inari v1.0.1 USR build gaia/gecko\t./auto_flash_from_PVT.sh -v101 -dinari --usr -g -G"
    echo -e "  Flash buri v1.2 USR build 20131007004003 gaia/gecko\t./auto_flash_from_PVT.sh -v120 -dburi --usr -g -G -b20131007004003"
	echo -e "  Flash by interaction GUI mode\t\t\t./auto_flash_from_PVT.sh -w"
	exit 0
}

## Show the available version info
function version_info(){
    print_list
    echo -e "Available version:"
    echo -e "  120|v1.2.0"
    echo -e "  110hd|v1.1.0hd"
    echo -e "  110|v1train"
    echo -e "  101|v1.0.1"
    echo -e "  0|master"
}

## Select the version
function version() {
    local_ver=$1
    case "$local_ver" in
        120|v1.2.0) VERSION_NAME="v120";;
        110hd|v1.1.0hd) VERSION_NAME="v110hd";;
        110|v1train) VERSION_NAME="v110";;
        101|v1.0.1) VERSION_NAME="v101";;
        0|master) VERSION_NAME="master";;
        *) version_info; exit -1;;
    esac
    
}

## Show the available device info
function device_info(){
    echo -e "Available device:"
    echo -e "  otoro"
    echo -e "  unagi"
    echo -e "  hamachi"
    echo -e "  inari"
    echo -e "  leo"
    echo -e "  helix"
    #echo -e "  wasabi"
    #echo -e "  nexus4"
}

## Select the device
function device() {
    local_ver=$1
    case "$local_ver" in
        otoro) DEVICE_NAME="otoro";;
        unagi) DEVICE_NAME="unagi";;
        hamachi) DEVICE_NAME="hamachi";;
        inari) DEVICE_NAME="inari";;
        leo) DEVICE_NAME="leo";;
        helix) DEVICE_NAME="helix";;
#        wasabi) DEVICE_NAME="wasabi";;
#        nexus4) DEVICE_NAME="nexus4";;
        *) device_info; exit -1;;
    esac
}

function select_device_dialog() {
    dialog --backtitle "Select Device from PVT Server " --title "Device List" --menu "Move using [UP] [DOWN],[Enter] to Select" \
    18 80 10 \
    "otoro" "Otoro Device" \
    "unagi" "Unagi Device" \
    "hamachi" "Hamachi/Buri Device" \
    "inari" "Inari/Ikura Device" \
    "leo" "Leo Device" \
    "helix" "Helix Device" 2>${TMP_DIR}/menuitem_device
    ret=$?
    if [ ${ret} == 1 ]; then
        echo "" && echo "byebye." && exit 0
    fi
    menuitem_device=`cat ${TMP_DIR}/menuitem_device`
    case $menuitem_device in
        "") echo ""; echo "byebye."; exit 0;;
        *) DEVICE_NAME=$menuitem_device;;
    esac
}

function select_device_dialog_mac() {
    device_option_list='{"otoro","unagi","hamachi","inari","leo","helix","mako"}'
    eval DEVICE_NAME=\$\(osascript -e \'tell application \"Terminal\" to choose from list $device_option_list with title \"Choose Device\"\'\)
    if [ ${DEVICE_NAME} == false ]; then
        echo ""
        echo "byebye"
        exit 0
    fi
}

function select_version_dialog() {
    MENU_VERSION_LIST=""
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_NAME
        eval VALUE=\$$KEY
        ## if Name contain the DEVICE_NAME, add into List
        if [[ ${VALUE} == *"$DEVICE_NAME" ]]; then
            echo -e "${COUNT}) ${VALUE}"
            MENU_VERSION_LIST+=" ${COUNT} \"${VALUE}\""
        fi
    done
    
    dialog --backtitle "Select Device from PVT Server " --title "Device List" --menu "Move using [UP] [DOWN],[Enter] to Select" \
    18 80 10 ${MENU_VERSION_LIST} 2>${TMP_DIR}/menuitem_version
    ret=$?
    if [ ${ret} == 1 ]; then
        echo "" && echo "byebye." && exit 0
    fi
    menuitem_version=`cat ${TMP_DIR}/menuitem_version`
    case $menuitem_version in
        "") echo ""; echo "byebye."; exit 0;;
        *) TARGET_ID=$menuitem_version; NAME_KEY=DL_${TARGET_ID}_NAME; eval TARGET_NAME=\$$NAME_KEY; VERSION_NAME=`echo $TARGET_NAME | sed "s,PVT\.,,g;s,\.$DEVICE_NAME,,g"`;;
    esac
}

function select_version_dialog_mac() {
    option_list=""
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_NAME
        eval VALUE=\$$KEY
        if [[ ${VALUE} == *"$DEVICE_NAME" ]]; then
            option_list=$option_list,\"${COUNT}-${VALUE}\"
        fi
    done
    local_option_list=${option_list#,*}
    eval ret=\$\(osascript -e \'tell application \"Terminal\" to choose from list \{$local_option_list\} with title \"Select Version\"\'\)
    TARGET_ID=${ret%%-*}
    if [ ${ret} == false ]; then
        echo ""
        echo "byebye"
        exit 0
    fi
}

## adb with flags
function run_adb()
{
    # TODO: Bug 875534 - Unable to direct ADB forward command to inari devices due to colon (:) in serial ID
    # If there is colon in serial number, this script will have some warning message.
	adb $ADB_FLAGS $@
}

## wget with flags
function run_wget() {
    echo "WGET: " $@
    if [ "${HTTPUser}" != "" ] && [ "${HTTPPwd}" != "" ]; then
        wget --http-user="${HTTPUser}" --http-passwd="${HTTPPwd}" $@
    else
        wget $@
    fi
}

## setup the http user account and passwd
function set_wget_acct_pwd() {
    if [ "$HTTP_USER" != "" ]; then
        HTTPUser=$HTTP_USER
    else
        read -p "Enter HTTP Username (LDAP): " HTTPUser
    fi
    if [ "$HTTP_PWD" != "" ]; then
        HTTPPwd=$HTTP_PWD
    else
        read -s -p "Enter HTTP Password (LDAP): " HTTPPwd
    fi
    echo ""
}

function set_wget_acct_pwd_dialog() {
    if [ "$HTTP_USER" != "" ]; then
        HTTPUser=$HTTP_USER
    else
        dialog --backtitle "Setup WGET" --title "HTTP User Name" --inputbox "\n\nEnter HTTP Username (LDAP)\n\nMove using [Tab] to Select\n" 15 80 2>${TMP_DIR}/menuitem_wgetacct
        ret=$?
        if [ ${ret} == 1 ]; then
            echo "" && echo "byebye." && exit 0
        fi
        menuitem_wgetacct=`cat ${TMP_DIR}/menuitem_wgetacct`
        case $menuitem_wgetacct in
            "") echo ""; echo "byebye."; exit 0;;
            *) HTTPUser=$menuitem_wgetacct;;
        esac
    fi
    if [ "$HTTP_PWD" != "" ]; then
        HTTPPwd=$HTTP_PWD
    else
        dialog --backtitle "Setup WGET" --title "HTTP Password" --insecure --passwordbox "\n\nEnter HTTP Password (LDAP)\n\nMove using [Tab] to Select" 15 80 2>${TMP_DIR}/menuitem_wgetpwd
        ret=$?
        if [ ${ret} == 1 ]; then
            echo "" && echo "byebye." && exit 0
        fi
        menuitem_wgetpwd=`cat ${TMP_DIR}/menuitem_wgetpwd`
        case $menuitem_wgetpwd in
            "") echo ""; echo "byebye."; exit 0;;
            *) HTTPPwd=$menuitem_wgetpwd;;
        esac
    fi
}

function set_wget_acct_pwd_dialog_mac() {
    if [ "$HTTP_USER" != "" ]; then
        HTTPUser=$HTTPUser
    else
        ret=$(osascript -e 'tell application "Terminal" to display dialog "Enter LDAP account" default answer "" with title "Account Info"')
        ret=${ret%,*}
        HTTPUser=${ret#*:}
    fi
    if [ "$HTTP_PWD" != "" ]; then
        HTTPPwd=$HTTP_PWD
    else
        ret=$(osascript -e 'tell application "Terminal" to display dialog "Enter LDAP password" default answer "" with hidden answer with title "Account Info"')
        ret=${ret%,*}
        HTTPPwd=${ret#*:}
    fi
    if [ -z '$HTTPUser' ] || [ -z '$HTTPPwd' ] ; then
        echo ""
        echo "byebye"
        exit 0
    fi
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
    MAKE_SURE_MSG+="URL:  ${TARGET_URL}\n"
    MAKE_SURE_MSG+="ENG Ver: ${FLASH_ENG}\n"
    MAKE_SURE_MSG+="Flash: "
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

function replace_url_for_build_id() {
    ## Replace Target URL with BUILD ID
    if [[ ${BUILD_ID} != "" ]]; then
        if [ ${#BUILD_ID} != 14 ]; then
            echo "" && echo "BUILD_ID ($BUILD_ID) should be 14 digits" && exit 0
        fi
        TARGET_URL=${TARGET_URL%latest/}${BUILD_ID:0:4}/${BUILD_ID:4:2}/${BUILD_ID:0:4}-${BUILD_ID:4:2}-${BUILD_ID:6:2}-${BUILD_ID:8:2}-${BUILD_ID:10:2}-${BUILD_ID:12:2}/
    fi
}

## make sure user want to flash/shallow flash
function make_sure() {
    read -p "Are you sure you want to flash your device? [y/N]" isFlash
    test "$isFlash" != "y" && test "$isFlash" != "Y" && echo "byebye." && exit 0
}

function make_sure_dialog() {
    ## Build ID support
    if [[ ${BUILD_ID} == "" ]]; then
        dialog --backtitle "Latest Build or Enter Build ID" --title "Selection" --yesno "\n\n\nDo you want to flash the latest build? \n\nClick [No] to enter the Build ID (YYYYMMDDhhmmss)." 15 80 2>${TMP_DIR}/menuitem_latestbuild
        ret=$?
        ## Enter BuildID
        if [ ${ret} == 1 ]; then
            dialog --backtitle "Latest Build or Enter Build ID" --title "Enter Build ID" --inputbox "\n\nEnter the Build ID you want to flash (YYYYMMDDhhmmss)\n\nMove using [Tab] to Select\n" 15 80 2>${TMP_DIR}/menuitem_buildid
            ret=$?
            if [ ${ret} == 1 ]; then
                echo "" && echo "byebye." && exit 0
            fi
            menuitem_buildid=`cat ${TMP_DIR}/menuitem_buildid`
            case $menuitem_buildid in
                "") echo ""; echo "byebye."; exit 0;;
                *) BUILD_ID=$menuitem_buildid;;
            esac
        fi
    fi

    replace_url_for_build_id
    create_make_sure_msg
    MAKE_SURE_MSG+="\n\nAre you sure you want to flash your device?"
    dialog --backtitle "Confirm the Information" --title "Confirmation" --yesno "${MAKE_SURE_MSG}" 18 80 2>${TMP_DIR}/menuitem_makesure
    ret=$?
    if [ ${ret} == 1 ]; then
        echo "" && echo "byebye." && exit 0
    fi
}

function make_sure_dialog_mac() {
    ret=$(osascript -e 'tell application "Terminal" to display dialog "Do you want to flash the latest build?\n Yes-Latest; No-Enter Build ID" buttons {"Cancel", "No", "Yes"} default button 3 with icon caution')
    if [ "${ret##*:}" == "No" ]; then
        ret=$(osascript -e 'tell application "Terminal" to display dialog "Enter the Build ID you want to flash (YYYYMMDDhhmmss)" default answer "" with title "Build Info"')
        tmp=${ret%,*}
        BUILD_ID=${tmp#*:}
        
        replace_url_for_build_id
    elif [[ "${ret##*:}" != "Yes" ]]; then
        echo "" && echo "byebye" && exit 0
    fi
}


## Loading the download list
function load_list() {
    PVT_DL_LIST=.PVT_DL_LIST.conf
    if [ -f $PVT_DL_LIST ]; then
        . $PVT_DL_LIST
    else
        echo "Cannot found the ${PVT_DL_LIST} file."
        exit -1
    fi
}

## Print download list
function print_list() {
    echo "Available Builds:"
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_NAME
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
    MENU_FLAG=""
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_NAME
        eval VALUE=\$$KEY
        MENU_FLAG+=" ${COUNT} \"${VALUE}\""
    done
    dialog --backtitle "Select Build from PVT Server " --title "Download List" --menu "Move using [UP] [DOWN],[Enter] to Select" \
    18 80 10 ${MENU_FLAG} 2>${TMP_DIR}/menuitem_build
    ret=$?
    if [ ${ret} == 1 ]; then
        echo "" && echo "byebye." && exit 0
    fi
    menuitem_build=`cat ${TMP_DIR}/menuitem_build`
    case $menuitem_build in
        "") echo ""; echo "byebye."; exit 0;;
        *) TARGET_ID=$menuitem_build;;
    esac
}

function select_build_dialog_mac() {
    option_list=""
    for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
    do
        KEY=DL_${COUNT}_NAME
        eval VALUE=\$$KEY

        option_list=$option_list,\"${COUNT}-${VALUE}\"
    done
    local_option_list=#{option_list#,*}
    eval ret=\$\(osascript -e \'tell application \"Terminal\" to choose from list \{$local_option_list\} with title \"Select Build\"\'\)
    echo $ret
    TARGET_ID=${ret%%-*}
    if [ -z "$TARGET_ID" ]; then
        echo "" && echo "byebye." && exit 0
    fi
}


## Select User or Eng build
function if_has_eng_build() {
    TARGET_HAS_ENG=false
    KEY=DL_${TARGET_ID}_ENG
    eval VALUE=\$$KEY
    if [ $VALUE == true ]; then
        TARGET_HAS_ENG=true
    fi
}

function select_user_eng_build() {
    while [ ${FLASH_USER_ENG_DONE} == false ]; do
        echo "User or Eng build:"
        echo "  1) User build"
        echo "  2) Engineer build"
        read -p "What do you want to flash? [Q to exit]" FLASH_USER_ENG
        test ${FLASH_USER_ENG} == "q" || test ${FLASH_USER_ENG} == "Q" && echo "byebye." && exit 0
        case ${FLASH_USER_ENG} in
            1) FLASH_ENG=false; FLASH_USER_ENG_DONE=true;;
            2) FLASH_ENG=true; FLASH_USER_ENG_DONE=true;;
        esac
    done
}

function select_user_eng_build_dialog() {
    if [ ${FLASH_USER_ENG_DONE} == false ]; then
        dialog --backtitle "Select Build from PVT Server " --title "User or Engineer Build" --menu "Move using [UP] [DOWN],[Enter] to Select" \
        18 80 10 1 "User build" 2 "Engineer build" 2>${TMP_DIR}/menuitem_usereng
        ret=$?
        if [ ${ret} == 1 ]; then
            echo "" && echo "byebye." && exit 0
        fi
        menuitem_usereng=`cat ${TMP_DIR}/menuitem_usereng`
        case $menuitem_usereng in
            "") echo ""; echo "byebye."; exit 0;;
            1) FLASH_ENG=false; FLASH_USER_ENG_DONE=true;;
            2) FLASH_ENG=true; FLASH_USER_ENG_DONE=true;;
        esac
    fi
}

function select_user_eng_build_dialog_mac() {
    if [ $TARGET_HAS_ENG == true ]; then
        ret=$(osascript -e 'tell application "Terminal" to choose from list {"0-User Build", "1-Engineer Build"} with title "Choose build type"')
        case ${ret%-*} in
            1) FLASH_ENG=false; FLASH_USER_ENG_DONE=true;;
            2) FLASH_ENG=true; FLASH_USER_ENG_DONE=true;;
        esac

        if [ -z "$ret" ]; then
            echo "" && echo "byebye." && exit 0
        fi
    fi
}

## Select flash mode
function select_flash_mode() {
    # if there are no flash flag, then ask
    GAIA_KEY=DL_${TARGET_ID}${ENG_FLAG}_GAIA
    eval GAIA_VALUE=\$$GAIA_KEY
    GECKO_KEY=DL_${TARGET_ID}${ENG_FLAG}_GECKO
    eval GECKO_VALUE=\$$GECKO_KEY
    while [ ${FLASH_FULL} == false ] && [ ${FLASH_GAIA} == false ] && [ ${FLASH_GECKO} == false ]; do
        echo "Flash Mode:"
        if ! [ -z $GAIA_VALUE ] && ! [ -z $GECKO_VALUE ]; then
            echo "  1) Shallow flash Gaia/Gecko"
        fi
        if ! [ -z $GAIA_VALUE ]; then
            echo "  2) Shallow flash Gaia"
        fi
        if ! [ -z $GECKO_VALUE ]; then
            echo "  3) Shallow flash Gecko"
        fi
        echo "  4) Flash Full Image"
        read -p "What do you want to flash? [Q to exit]" FLASH_INPUT
        test ${FLASH_INPUT} == "q" || test ${FLASH_INPUT} == "Q" && echo "byebye." && exit 0
        case ${FLASH_INPUT} in
            1)  if ! [ -z $GAIA_VALUE ] && ! [ -z $GECKO_VALUE ]; then
                    FLASH_GAIA=true; FLASH_GECKO=true
                fi;;
            2)  if ! [ -z $GAIA_VALUE ]; then
                    FLASH_GAIA=true
                fi;;
            3)  if ! [ -z $GECKO_VALUE ]; then
                    FLASH_GECKO=true
                fi;;
            4) FLASH_FULL=true;;
        esac
    done
}

function select_flash_mode_dialog() {
    # if there are no flash flag, then ask
    if [ ${FLASH_FULL} == false ] && [ ${FLASH_GAIA} == false ] && [ ${FLASH_GECKO} == false ]; then
#        dialog --backtitle "Select Build from PVT Server " --title "Flash Mode" --menu "Move using [UP] [DOWN],[Enter] to Select" \
#        18 80 10 1 "Flash Image" 2 "Shallow flash Gaia/Gecko" 3 "Shallow flash Gaia" 4 "Shallow flash Gecko" 2>${TMP_DIR}/menuitem_flash

        FLASH_MODE_FLAG=""
        GAIA_KEY=DL_${TARGET_ID}${ENG_FLAG}_GAIA
        eval GAIA_VALUE=\$$GAIA_KEY
        GECKO_KEY=DL_${TARGET_ID}${ENG_FLAG}_GECKO
        eval GECKO_VALUE=\$$GECKO_KEY
        if ! [ -z $GAIA_VALUE ] && ! [ -z $GECKO_VALUE ]; then
            COUNT=1
            FLASH_MODE_FLAG+=" $COUNT Shallow_flash_Gaia/Gecko"
        fi
        if ! [ -z $GAIA_VALUE ]; then
            COUNT=2
            FLASH_MODE_FLAG+=" $COUNT Shallow_flash_Gaia"
        fi
        if ! [ -z $GECKO_VALUE ]; then
            COUNT=3
            FLASH_MODE_FLAG+=" $COUNT Shallow_flash_Gecko"
        fi
        COUNT=4
        FLASH_MODE_FLAG+=" $COUNT Flash_Full_Image"

        dialog --backtitle "Select Build from PVT Server " --title "Flash Mode" --menu "Move using [UP] [DOWN],[Enter] to Select" \
        18 80 10 ${FLASH_MODE_FLAG} 2>${TMP_DIR}/menuitem_flash

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
    fi
}

function select_flash_mode_dialog_mac() {
    ret=$(osascript -e 'tell application "Terminal" to choose from list {"1-Flash Gaia and Gecko", "2-Flash Gaia", "3-Flash Gecko", "4-Flash Full"}')
    echo $ret
    case ${ret%%-*} in
        "") echo ""; echo "byebye."; exit 0;;
        1) FLASH_GAIA=true; FLASH_GECKO=true;;
        2) FLASH_GAIA=true;;
        3) FLASH_GECKO=true;;
        4) FLASH_FULL=true;;
    esac
    if [ -z "$ret" ]; then
        echo "" && echo "byebye." && exit 0
    fi
}

## Find the download build's info
function find_download_files_name() {
    TARGET_NAME_KEY=DL_${TARGET_ID}_NAME
    eval TARGET_NAME=\$$TARGET_NAME_KEY

    TARGET_URL_KEY=DL_${TARGET_ID}${ENG_FLAG}_URL
    eval TARGET_URL=\$$TARGET_URL_KEY

    TARGET_IMG_KEY=DL_${TARGET_ID}${ENG_FLAG}_IMG
    eval TARGET_IMG=\$$TARGET_IMG_KEY
    
    TARGET_GAIA_KEY=DL_${TARGET_ID}${ENG_FLAG}_GAIA
    eval TARGET_GAIA=\$$TARGET_GAIA_KEY

    TARGET_GECKO_KEY=DL_${TARGET_ID}${ENG_FLAG}_GECKO
    eval TARGET_GECKO=\$$TARGET_GECKO_KEY
}

## Print flash info
function print_flash_info() {
    echo    ""
    echo    "Your Target Build: ${TARGET_NAME}"
    echo -e "URL:  ${TARGET_URL}"
    echo -e "ENG Ver: ${FLASH_ENG}"
    echo -n "Flash: "
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
    dialog --backtitle "Flash Information " --title "Done" --msgbox "${MAKE_SURE_MSG}" 18 80 2>${TMP_DIR}/menuitem_done
}

function download_file_from_PVT() {
    DL_URL=$1
    DL_FILE=$2
    DEST_DIR=$3
    echo ""
    echo "Download file: ${DL_URL}${DL_FILE}"
    run_wget -P ${DEST_DIR} ${DL_URL}${DL_FILE}
    ret=$?
    if [ ${ret} != 0 ]; then
        echo "Download failed." && echo "byebye." && exit 0
    fi
}

## Shallow flash gaia/gecko
function do_shallow_flash() {
    SHALLOW_FLAG+=$ADB_FLAGS
    if [ ${FLASH_GAIA} == true ]; then
        download_file_from_PVT ${TARGET_URL} ${TARGET_GAIA} ${TMP_DIR}
        GAIA_BASENAME=`basename ${TMP_DIR}/${TARGET_GAIA}`
        case `uname` in
            "Linux") SHALLOW_FLAG+=" -g${TMP_DIR}/${GAIA_BASENAME}";;
            "Darwin") SHALLOW_FLAG+=" -g ${TMP_DIR}/${GAIA_BASENAME}";;
        esac
    fi
    if [ ${FLASH_GECKO} == true ]; then
        download_file_from_PVT ${TARGET_URL} ${TARGET_GECKO} ${TMP_DIR}
        GECKO_BASENAME=`basename ${TMP_DIR}/${TARGET_GECKO}`
        case `uname` in
            "Linux") SHALLOW_FLAG+=" -G${TMP_DIR}/${GECKO_BASENAME}";;
            "Darwin") SHALLOW_FLAG+=" -G ${TMP_DIR}/${GECKO_BASENAME}";;
        esac
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
    download_file_from_PVT ${TARGET_URL} ${TARGET_IMG} ${TMP_DIR}
    IMG_BASENAME=`basename ${TMP_DIR}/${TARGET_IMG}`
    unzip -d ${TMP_DIR} ${TMP_DIR}/${IMG_BASENAME}
    CURRENT_DIR=`pwd`
    cd ${TMP_DIR}/b2g-distro/
    bash ./flash.sh -f
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
    rm -rf ./autoflashfromPVT_temp
    mkdir autoflashfromPVT_temp
    cd autoflashfromPVT_temp
    TMP_DIR=`pwd`
    cd ..
else
    TMP_DIR=`mktemp -d -t autoflashfromPVT.XXXXXXXXXXXX`
fi


#########################
# Download PVT List     #
#########################
load_list


#########################
# Processing Parameters #
#########################

## show helper if nothing specified
if [ $# = 0 ]; then echo "Nothing specified"; helper; exit 0; fi

## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o v::d::s::b::gGfwyh --long version::,device::,build::,usr,eng,gaia,gecko,flash,help \
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
        -b|--buildid) BUILD_ID=$2; shift 2;;
        --usr) FLASH_USR_IF_POSSIBLE=true; FLASH_ENG_IF_POSSIBLE=false; shift;;
        --eng) FLASH_ENG_IF_POSSIBLE=true; FLASH_USR_IF_POSSIBLE=false; shift;;
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


##################################################
# For interaction GUI mode, check dialog package #
##################################################
if [ ${INTERACTION_WINDOW} == true ]; then
    case `uname` in
        "Linux") check_install_dialog;;
        "Darwin") ;;
    esac
fi


#################################
# Prepare the authn of web site #
#################################
source .ldap
if [ "$HTTP_USER" != "" ]; then
    echo -e "Load account [$HTTP_USER] from .ldap"
fi
if [ "$HTTP_PWD" != "" ]; then
    echo -e "Load password from .ldap"
fi

if [ ${INTERACTION_WINDOW} == false ]; then
    set_wget_acct_pwd
else
    case `uname` in
        "Linux") set_wget_acct_pwd_dialog;;
        "Darwin") set_wget_acct_pwd_dialog_mac;;
    esac
fi


#############################################
# Find the B2G.${VERSION}.${DEVICE} in list #
#############################################
FOUND=false
TARGET_NAME=PVT.${VERSION_NAME}.${DEVICE_NAME}
for (( COUNT=0 ; COUNT<${DL_SIZE} ; COUNT++ ))
do
    KEY=DL_${COUNT}_NAME
    eval VALUE=\$$KEY
    
    if [ ${TARGET_NAME} == ${VALUE} ]; then
        echo "${TARGET_NAME} is found!!"
        FOUND=true
        TARGET_ID=${COUNT}
    fi
done

###########################################
# If not select DEVICE, then list DEVICES #
###########################################
if [ ${INTERACTION_WINDOW} == true ] && [ -z $DEVICE_NAME ]; then
    case `uname` in
        "Linux") select_device_dialog; select_version_dialog;;
        "Darwin") select_device_dialog_mac; select_version_dialog_mac;;
    esac

    if ! [ -z $TARGET_ID ]; then
        FOUND=true
    fi
fi

##########################################################################################
# If can NOT find the target from user input parameters, list the download list to user. #
##########################################################################################
if [ ${FOUND} == false ]; then
    echo "Can NOT found the ${TARGET_NAME}"
    echo "Please select one build from following list."
    if [ ${INTERACTION_WINDOW} == false ]; then
        select_build
    else
        case `uname` in
            "Linux") select_build_dialog;;
            "Darwin") select_build_dialog_mac;;
        esac
    fi
fi

#########################
# Select USER/ENG build #
#########################
ENG_FLAG=""
if_has_eng_build
if [ $TARGET_HAS_ENG == true ]; then
    if [ ${FLASH_ENG_IF_POSSIBLE} == true ]; then
        FLASH_ENG=true
    elif [ ${FLASH_USR_IF_POSSIBLE} == true ]; then
        FLASH_ENG=false
    else
        if [ ${INTERACTION_WINDOW} == false ]; then
            select_user_eng_build
        else
            case `uname` in
                "Linux") select_user_eng_build_dialog;;
                "Darwin") select_user_eng_build_dialog_mac;;
            esac
        fi
    fi
else
    FLASH_ENG=false
fi
if [ "$FLASH_ENG" == true ]; then
    ENG_FLAG="_ENG"
fi

###################################################################################
# If can NOT find the flash mode from user input parameters, list the flash mode. #
###################################################################################
if [ ${INTERACTION_WINDOW} == false ]; then
    select_flash_mode
else
    case `uname` in
        "Linux") select_flash_mode_dialog;;
        "Darwin") select_flash_mode_dialog_mac;;
    esac
fi


####################################
# Find the name of download files. #
####################################
find_download_files_name
if [ ${INTERACTION_WINDOW} == false ]; then
    ## Build ID support
    replace_url_for_build_id
    print_flash_info
    if [ ${VERY_SURE} == false ]; then
        make_sure
    fi
else
    if [ ${VERY_SURE} == false ]; then
        case `uname` in
            "Linux") make_sure_dialog;;
            "Darwin") make_sure_dialog_mac;;
        esac
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

###################
# Version          #
####################
if [ ${INTERACTION_WINDOW} == false ]; then
    if [ -e ./check_versions.sh ] && [ ${FLASH_FULL} == true ]; then
        bash ./check_versions.sh
    fi
    print_flash_info
    echo "Done."
else
    case `uname` in
        "Linux") print_flash_info_dialog;;
        "Darwin") ;;
    esac
fi


#########################
# Remove Temp Folder    #
#########################
rm -rf ${TMP_DIR}

