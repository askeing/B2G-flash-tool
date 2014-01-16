#!/bin/bash

# Install python-virtualenv
sudo apt-get install git python-virtualenv python-dev bluez libbluetooth-dev

# Install adb and fastboot
echo ""
read -p "### Install \"adb\" & \"fastboot\" for Linux? [y/N]" REPLY
if [[ ${REPLY} == "Y" ]] || [[ ${REPLY} == "y" ]] ; then
    sudo add-apt-repository ppa:nilarimogard/webupd8
    sudo apt-get update
    sudo apt-get install android-tools-adb android-tools-fastboot
    echo -e "### Please edit \"/etc/udev/rules.d/51-android.rules\" to fit your requirements!"
else
    echo "Goodbye!"
fi

