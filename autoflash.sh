#!/bin/bash
#==========================================================================
# 
# IMPORTANT: only for internal use!
# 
# Description:
#   This script was written for download latest build from pvt server.
#
# Author: Askeing fyen@mozilla.com
# History:
#   2012/11/30 Askeing: v1.0 First release (only for unagi).
#   2012/12/03 Askeing: v2.0 Added -F flag for no-download-only-flash
#   2012/12/03 Askeing: v3.0 Added -e flag for engineer build
#   2012/12/03 Al:      V3.1 Change flag checker
#   2012/12/05 Askeing: v4.0 Added -b flag for backup the old profile
#                            (Backup/Recover script from Timdream)
#   2012/12/13 Askeing: v5.0 Added nightly user build site.
#			     https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-beta-unagi/latest/unagi.zip
#   2012/12/13 Askeing: v5.1 Added the build version information. (gecko, gaia)
#   2012/12/19 Askeing: v5.2 Added the -r flag for recover only.
#   2012/12/21 Askeing: v5.3 Added no kernel script "flash-nokernel.sh", 
#			     due to the kernel is unagi-kernelupdate3 not 4.
#   2012/12/21 Askeing: v6.0 Modified the download URL and automatically change the filename by mtime. 
#   2012/12/27 Askeing: v7.0 Added the date build (B2G shira v1.01).
#   2013/01/16 Askeing: v8.0 Removed the no-kernel option.
#   2013/01/16 Askeing: v8.1 Updated the description.
#   2013/01/23 Askeing: v8.2 Removed sudo command.
#==========================================================================


####################
# Parameter Flags
####################
# Default: download, no flash, nightly build, no backup
Engineer_Flag=0
Download_Flag=true
Flash_Flag=false
Backup_Flag=false
RecoverOnly_Flag=false

for x
do
	# -h, --help, -?: help
	if [ "$x" = "--help" ] || [ "$x" = "-h" ] || [ "$x" = "-?" ]; then
		echo -e "v 8.2"
		echo -e "This script will download latest release build from pvt server. (only for unagi now)\n"
		echo -e "Usage: [Environment] ./autoflash.sh [parameters]"
		echo -e "Environment:\n\tHTTP_USER={username} HTTP_PWD={pw} ADB_PATH=adb_path\n"
		# -f, --flash
		echo -e "-f, --flash\tFlash your device (unagi) after downlaod finish."
		echo -e "\t\tYou may have to input root password when you add this argument."
		echo -e "\t\tYour PATH should has adb path, or you can setup the ADB_PATH."
		# -F, --flash-only
		echo -e "-F, --flash-only\tFlash your device (unagi) from latest downloaded zipped build."
		# -e, --eng
		echo -e "-e, --eng\tchange the target build to engineer build."
		# -11, --date: date build (B2G shira v1.01)
		echo -e "-11, --date\tchange the target build to date build (B2G shira v1.01)."
		# -b, --backup
		echo -e "-b, --backup\tbackup and recover the origin profile."
		echo -e "\t\t(it will work with -f anf -F)"
		# -r, --recover-only
		echo -e "-r, --recover-only:\trecover the phone from local machine"
		# -h, --help
		echo -e "-h, --help\tDisplay help."
		echo -e "-?\t\tDisplay help.\n"
		echo -e "Example:"
		echo -e "  Download build.\t\t./autoflash.sh"
		echo -e "  Download engineer build.\tHTTP_USER=dog@foo.foo HTTP_PWD=foo ./autoflash.sh -e"
		echo -e "  Download and flash build.\t./autoflash.sh -f"
		echo -e "  Flash engineer build.\t\t./autoflash.sh -e -F"
		echo -e "  Flash engineer build, backup profile.\t\t./autoflash.sh -e -F -b"
		echo -e "  Flash engineer build, don't update kernel.\t./autoflash.sh -e -F --no-kernel"
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
		Engineer_Flag=1

	# -11, --date: date build (B2G shira v1.01)
	elif [ "$x" = "-11" ] || [ "$x" = "--date" ]; then
		Engineer_Flag=2

	# -b, --backup: backup and recover the phone
	elif [ "$x" = "-b" ] || [ "$x" = "--backup" ]; then
		Backup_Flag=true
	# -r, --recover-only: recover the phone from local machine
	elif [ "$x" = "-r" ] || [ "$x" = "--recover-only" ]; then
		RecoverOnly_Flag=true	
	else
		echo -e "'$x' is an invalid command. See '--help'."
		exit 0
	fi
done

####################
# Recover Only task
####################
if [ $RecoverOnly_Flag == true ]; then
	echo -e "Recover your profiles..."
	adb shell stop b2g 2> ./mozilla-profile/recover.log &&\
	adb shell rm -r /data/b2g/mozilla 2> ./mozilla-profile/recover.log &&\
	adb push ./mozilla-profile/profile /data/b2g/mozilla 2> ./mozilla-profile/recover.log &&\
	adb push ./mozilla-profile/data-local /data/local 2> ./mozilla-profile/recover.log &&\
	adb reboot
	sleep 30
	echo -e "Recover done."
	exit 0
fi

####################
# Check date and Files
####################
Yesterday=$(date --date='1 days ago' +%Y-%m-%d)
Today=$(date +%Y-%m-%d)

DownloadFilename=unagi.zip
if [ $Engineer_Flag == 1 ]; then
	URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18-unagi-eng/latest/${DownloadFilename}
elif [ $Engineer_Flag == 2 ]; then
	URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/date-unagi/latest/${DownloadFilename}
else
	URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18-unagi/latest/${DownloadFilename}
fi

####################
# Download task
####################
if [ $Download_Flag == true ]; then
	# Clean file
	echo -e "Clean..."
	rm -f $DownloadFilename

	# Prepare the authn of web site
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
	
	# Download file
	echo -e "Download latest build..."
	wget --http-user="${HTTPUser}" --http-passwd="${HTTPPwd}" $URL

	# Check the download is okay
	if [ $? -ne 0 ]; then
		echo -e "Download $URL failed."
		exit 1
	fi

	# Modify the downloaded filename
	filetime=`stat -c %y unagi.zip | sed 's/\s.*$//g'`
	if [ $Engineer_Flag == 1 ]; then
		Filename=unagi_${filetime}_eng.zip
	elif [ $Engineer_Flag == 2 ]; then
		Filename=unagi_${filetime}_date.zip
	else
		Filename=unagi_${filetime}_usr.zip
	fi
	rm -f $Filename
	mv $DownloadFilename $Filename
else
	# Setup the filename for -F
	if [ $Engineer_Flag == 1 ]; then
		Filename=`ls -tm unagi_*_eng.zip | sed 's/,.*$//g' | head -1`
	elif [ $Engineer_Flag == 2 ]; then
		Filename=`ls -tm unagi_*_date.zip | sed 's/,.*$//g' | head -1`
	else
		Filename=`ls -tm unagi_*_usr.zip | sed 's/,.*$//g' | head -1`
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
echo -e "Unzip $Filename ..."
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
	#sudo env PATH=$PATH ./flash.sh
	./flash.sh
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
		adb wait-for-device
		echo -e "Recover done."
	fi
fi

####################
# Retrieve Version info
####################
#if [ $Engineer_Flag == 1 ]; then
#	grep '^.*path=\"gecko\" remote=\"mozillaorg\" revision=' ./b2g-distro/default.xml | sed 's/^.*path=\"gecko\" remote=\"mozillaorg\" revision=/gecko revision: /g' | sed 's/\/>//g' > VERSION
#	grep '^.*path=\"gaia\" remote=\"mozillaorg\" revision=' ./b2g-distro/default.xml | sed 's/^.*path=\"gaia\" remote=\"mozillaorg\" revision=/gaia revision: /g' | sed 's/\/>//g' >> VERSION
#else
#	grep '^.*path=\"gecko\".*revision=' ./b2g-distro/sources.xml | sed 's/^.*path=\"gecko\".*revision=/gecko revision: /g' | sed 's/\/>//g' > VERSION
#	grep '^.*path=\"gaia\".*revision=' ./b2g-distro/sources.xml | sed 's/^.*path=\"gaia\".*revision=/gaia revision: /g' | sed 's/\/>//g' >> VERSION
#fi

grep '^.*path=\"gecko\".*revision=' ./b2g-distro/sources.xml > VERSION
grep '^.*path=\"gaia\".*revision=' ./b2g-distro/sources.xml >> VERSION

echo -e "===== VERSION ====="
cat VERSION

####################
# Done
####################
echo -e "Done!\nbyebye."

