#!/bin/bash
#==========================================================================
# Description:
#   This script was written for download latest build from
#   https://releases.mozilla.com/b2g/
#   acct/pw: b2g/6 Parakeets in three bushes
#
# Author: Askeing fyen@mozilla.com
# History:
#   2012/11/30 Askeing: v1.0 First release (only for unagi).
#   2012/12/03 Askeing: v2.0 Added -F flag for no-download-only-flash
#
#==========================================================================


####################
# Helper
####################
if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-?" ]; then
	echo -e "v 2.0"
	echo -e "This script will download latest release nightly build.\n(only for unagi now)\n"
	echo -e "Usage: [ADB_PATH=your adb path] {script_name} [-fF]\n"
	# -f, --flash
	echo -e "-f, --flash\tFlash your device (unagi) after downlaod finish."
	echo -e "\t\tYou may have to input root password when you add this argument."
	echo -e "\t\tYour PATH should has adb path, or you can setup the ADB_PATH."
	# -F, --flash-only
	echo -e "-F, --flash-only\tFlash your device (unagi) from downloaded zipped build."
	# -h, --help
	echo -e "-h, --help\tDisplay help."
	echo -e "-?\t\tDisplay help."
	exit 0
fi

####################
# Flags
####################
# Default: download, no flash
Download_Flag=true
Flash_Flag=false
# -f, --flash: download, flash
if [ "$1" == "-f" ] || [ "$1" == "--flash" ]; then
	Download_Flag=true
	Flash_Flag=true
# -F, --flash-only: no download, flash
elif [ "$1" == "-F" ] || [ "$1" == "--flash-only" ]; then
	Download_Flag=false
	Flash_Flag=true
fi


####################
# Check date
####################
Yesterday=$(date --date='1 days ago' +%Y-%m-%d)
Today=$(date +%Y-%m-%d)
Filename=unagi_$Yesterday.zip
URL=https://releases.mozilla.com/b2g/$Yesterday/$Filename


####################
# Download task
####################
if [ $Download_Flag == true ]; then
	# Clean file
	echo -e "Clean..."
	rm -f unagi_$Yesterday.zip
	
	# Download file
	echo -e "Download latest build..."
	wget --http-user=b2g --http-passwd="6 Parakeets in three bushes" $URL
	
	# Check the download is okay
	if [ $? -ne 0 ]; then
		echo -e "Download $URL failed."
		exit 1
	fi
fi


####################
# Decompress task
####################
# Check the file is exist
test ! -f $Filename && echo -e "The file $Filename DO NOT exist." && exit 1

# Delete folder
echo -e "Delete old build folder: b2g-distro"
rm -rf b2g-distro/

# Unzip file
echo -e "Unzip..."
unzip $Filename


####################
# Flash device task
####################
if [ $Flash_Flag == true ]; then
	# make sure
	read -p "Are you sure you want to flash your device? [y/N]" isFlash
	if [ "$isFlash" != "y" ] && [ "$isFlash" != "Y" ]; then
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

####################
# Done
####################
echo -e "Done!\nbyebye."

