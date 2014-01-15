#!/bin/bash

# Install python-virtualenv
sudo apt-get install git python-virtualenv python-dev bluez libbluetooth-dev

# Install adb and fastboot
SOURCE=https://github.com/askeing/adb-fastboot-install.git
echo ""
read -p "### Install \"adb\" & \"fastboot\" for Linux from ${SOURCE} repo? [y/N]" REPLY
if [[ ${REPLY} == "Y" ]] || [[ ${REPLY} == "y" ]] ; then
    if ! which mktemp > /dev/null; then
        echo "Package \"mktemp\" not found!"
        rm -rf ./autoflashfromPVT_temp
        mkdir autoflashfromPVT_temp
        cd autoflashfromPVT_temp
        TMP_DIR=`pwd`
        cd ..
    else
        TMP_DIR=`mktemp -d`
    fi
    CURRENT_DIR=`pwd`
    
    cd ${TMP_DIR}
    echo -e "### Clone repo ${SOURCE} to ${TMP_DIR}"
    git clone ${SOURCE}
    cd adb-fastboot-install
    ./ADB-Install-Linux.sh
    cd ${CURRENT_DIR}
    echo -e "### Remove ${TMP_DIR}"
    rm -rf ${TMP_DIR}
    echo -e "### Please edit \"/etc/udev/rules.d/51-android.rules\" to fit your requirements!"
else
    echo "Goodbye!"
fi

