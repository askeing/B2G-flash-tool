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
#   2012/12/03 Askeing: v3.0 Added -e flag for engineer build
#   2012/12/03 Al:      V3.1 Change flag checker
#   2012/12/05 Askeing: v4.0 Added -b flag for backup the old profile
#                            (Backup/Recover script from Timdream)
#
#==========================================================================


####################
# Parameter Flags
####################
# Default: download, no flash, nightly build, no backup
Download_Flag=true
Flash_Flag=false
Engineer_Flag=false
Backup_Flag=false

for x
do
	# -h, --help, -?: help
	if [ "$x" = "--help" ] || [ "$x" = "-h" ] || [ "$x" = "-?" ]; then
		echo -e "v 4.0"
		echo -e "This script will download latest release nightly build.\n(only for unagi now)\n"
		echo -e "Usage: [ADB_PATH=your adb path] {script_name} [-fFebh?]\n"
		# -f, --flash
		echo -e "-f, --flash\tFlash your device (unagi) after downlaod finish."
		echo -e "\t\tYou may have to input root password when you add this argument."
		echo -e "\t\tYour PATH should has adb path, or you can setup the ADB_PATH."
		# -F, --flash-only
		echo -e "-F, --flash-only\tFlash your device (unagi) from downloaded zipped build."
		# -e, --eng
		echo -e "-e, --eng\tchange the target build to engineer build."
		# -b, --backup
		echo -e "-b, --backup\tbackup and recover the origin profile."
		echo -e "\t\t(it will work with -f anf -F)"
		# -h, --help
		echo -e "-h, --help\tDisplay help."
		echo -e "-?\t\tDisplay help."
		echo -e "Example:"
		echo -e "Download build.\t\t\t\t{script_name}"
		echo -e "Download and flash build.\t\t{script_name} -f"
		echo -e "Flash engineer build.\t\t\t{script_name} -e -F"
		echo -e "Flash engineer build, backup profile.\t{script_name} -e -F -b"
		exit 0

	# -f, --flash: download, flash
	elif [ "$x" = "-f" ] || [ "$x" = "--flash" ]; then
		Download_Flag=true
		Flash_Flag=true

	# -F, --flash-only: no download, flash
	elif [ "$x" = "-F" ] || [ "$x" = "--flash-only" ]; then
		Download_Flag=false
		Flash_Flag=true

	# -e, --eng: engineer build
	elif [ "$x" = "-e" ] || [ "$x" = "--eng" ]; then
		Engineer_Flag=true

	# -b, --backup: engineer build
	elif [ "$x" = "-b" ] || [ "$x" = "--backup" ]; then
		Backup_Flag=true

	else
		echo -e "Usage: [ADB_PATH=your adb path] {script_name} [-fF]\n"
		echo -e "Use --help for help"
		exit 0
	fi
done

####################
# Check date
####################
Yesterday=$(date --date='1 days ago' +%Y-%m-%d)
Today=$(date +%Y-%m-%d)
if [ $Engineer_Flag == true ]; then
	Filename=unagi_${Yesterday}_eng.zip
else
	Filename=unagi_${Yesterday}.zip
fi
URL=https://releases.mozilla.com/b2g/${Yesterday}/${Filename}


####################
# Download task
####################
if [ $Download_Flag == true ]; then
	# Clean file
	echo -e "Clean..."
	rm -f $Filename
	
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
		exit 0
	fi

	# ADB PATH
	if [ "$ADB_PATH" == "" ]; then
		echo -e 'No ADB_PATH, using PATH'
	else
		echo -e "Using ADB_PATH = $ADB_PATH"
		PATH=$PATH:$ADB_PATH
		export PATH
	fi

	####################
	# Backup task
	####################
	if [ $Backup_Flag == true ]; then
		echo -e "Backup your profiles..."
		adb shell stop b2g 2> ./mozilla-profile/backup.log &&\
		rm -rf ./mozilla-profile/* &&\
		mkdir -p mozilla-profile/profile &&\
		adb pull /data/b2g/mozilla ./mozilla-profile/profile 2> ./mozilla-profile/backup.log &&\
		mkdir -p mozilla-profile/data-local &&\
		adb pull /data/local ./mozilla-profile/data-local 2> ./mozilla-profile/backup.log &&\
		rm -rf mozilla-profile/data-local/webapps
		echo -e "Backup done."
	fi

	echo -e "flash your device..."
	cd ./b2g-distro
	pwd
	sudo env PATH=$PATH ./flash.sh
	cd ..

	####################
	# Recover task
	####################
	if [ $Backup_Flag == true ]; then
		sleep 5
		echo -e "Recover your profiles..."
		adb shell stop b2g 2> ./mozilla-profile/recover.log &&\
		adb shell rm -r /data/b2g/mozilla 2> ./mozilla-profile/recover.log &&\
		adb push ./mozilla-profile/profile /data/b2g/mozilla 2> ./mozilla-profile/recover.log &&\
		adb push ./mozilla-profile/data-local /data/local 2> ./mozilla-profile/recover.log &&\
		adb reboot
		sleep 50
		adb wait-for-device
		echo -e "Recover done."
	fi
fi

####################
# Done
####################
echo -e "Done!\nbyebye."

