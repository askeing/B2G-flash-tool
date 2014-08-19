#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for installing libraries of gaia-ui-tests.
#==========================================================================

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

