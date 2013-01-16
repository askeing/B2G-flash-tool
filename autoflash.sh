#!/bin/bash
#============================================================
# Description:
#   This script was written for download latest build from
#   https://releases.mozilla.com/b2g/
#   acct/pw: b2g/6 Parakeets in three bushes
#
# Author: Askeing fyen@mozilla.com
# History:
#   2012/11/30 Askeing: v1.0 First release (only for unagi).
#
#============================================================

# Helper
if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-?" ]; then
	echo -e "v 1.0"
	echo -e "This script was written for download latest release nightly build.\n(only for unagi now)\n"
	echo -e "Usage: [ADB_PATH=your adb path] {script_name} [-f]\n"
	# -f, --flash
	echo -e "-f, --flash\tFlash your device (unagi) after downlaod finish."
	echo -e "\t\tYou may have to input root password when you add this argument."
	echo -e "\t\tYour PATH should has adb path, or you can setup the ADB_PATH."
	# -h, --help
	echo -e "-h, --help\tDisplay help."
	echo -e "-?\t\tDisplay help."
	exit
fi

# Date
Yesterday=$(date --date='1 days ago' +%Y-%m-%d)
Today=$(date +%Y-%m-%d)
Filename=unagi_$Yesterday.zip

# Delete folder
echo -e "Delete old build folder: b2g-distro"
rm -rf b2g-distro/

# Clean file
echo -e "Clean..."
rm -f unagi_$Yesterday.zip

# Download file
echo -e "Download latest build from\nhttps://releases.mozilla.com/b2g/\n"
wget --http-user=b2g --http-passwd="6 Parakeets in three bushes" https://releases.mozilla.com/b2g/$Yesterday/$Filename

# Unzip file
echo -e "Unzip..."
unzip $Filename


# Flash device
if [ "$1" == "-f" ] || [ "$1" == "--flash" ]; then
	# make sure
	read -p "Are you sure you want to flash your device? [Y/n]" isFlash
	if [ "$isFlash" == "n" ] || [ "$isFlash" = "N" ]; then
		echo -e "byebye."
		exit
	fi

	# ADB PATH
	if [ "$ADB_PATH" == "" ]; then
		echo -e 'No ADB_PATH, using PATH'
	else
		echo -e "Using ADB_PATH = $ADB_PATH"
		PATH=$PATH:$ADB_PATH
		export PATH
	fi

	echo -e "flash your device..."
	cd ./b2g-distro
	pwd
	sudo env PATH=$PATH ./flash.sh
fi

# Done
echo -e "Done!\nbyebye."

