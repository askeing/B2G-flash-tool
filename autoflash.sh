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
#   2013/01/23 Askeing: v8.3 Fixed backup/recover bug.
#   2013/02/27 Askeing: v9.0 Modified the code for version changed.
#   2013/03/01 Askeing: v9.1 Added backup-only.
#   2013/03/05 Paul:    v10.0 refactor arg pasring, refine argument
#   2013/03/08 Al:      v10.1 Remove unnecessary date command.
#   2013/03/08 Al:      v10.2 Add support of Mac OS X
#   2013/03/11 Al:      v10.3 Add auto prompt
#   2013/04/09 Al:      v11.0 Add new devices leo, inari
#   2013/04/10 Al:      v11.1 Add new devices hamachi (a.k.a. buri)
#
# = = = = = = = = = = = Backlog = = = = = = = = = = = = = = = = = = = = = =
#   2013/04/09 Al:      Need to refactor "Check File" section
#==========================================================================


####################
# Parameter Flags
####################
# Default: download, no flash, nightly build, no backup
Version_Flag="v1train"
Device_Flag="unagi"
Engineer_Flag=0
Download_Flag=true
Flash_Flag=false
Backup_Flag=false
BackupOnly_Flag=false
RecoverOnly_Flag=false

## helper function
## no input arguments, simply print helper descirption to std out
function helper(){
	echo -e "v 11.0"
	echo -e "This script will download latest release build from pvt server. (only for unagi now)\n"
	echo -e "Usage: [Environment] ./autoflash.sh [parameters]"
	echo -e "Environment:\n\tHTTP_USER={username} HTTP_PWD={pw} ADB_PATH=adb_path\n"
	# -f, --flash
	echo -e "-f|--flash\tFlash your device (unagi) after downlaod finish."
	echo -e "\t\tYou may have to input root password when you add this argument."
	echo -e "\t\tYour PATH should has adb path, or you can setup the ADB_PATH."
	# -F, --flash-only
    echo -e "-F|--flash-only\tFlash your device from local zipped build(ex: -F{file name}); default: use latest downloaded"
	# -e, --eng
	echo -e "-e|--eng\tchange the target build to engineer build."
    # -v, --version
    echo -e "-v|--version, \t give the target build version, ex: -vtef == -v100; show available version if nothing specified."
	# --tef: tef build v1.0.0
	echo -e "--tef\tchange the target build to tef build v1.0.0."
	# --shira: shira build v1.0.1
	echo -e "--shira\tchange the target build to shira build v1.0.1."
	# --v1train: v1-train build
	echo -e "--v1train\tchange the target build to v1train build."
	# -b, --backup
	echo -e "-b|--backup\tbackup and recover the origin profile."
	echo -e "\t\t(it will work with -f anf -F)"
	# -B, --backup-only
	echo -e "-B|--backup-only:\tbackup the phone to local machine"
	# -R, --recover-only
	echo -e "-R|--recover-only:\trecover the phone from local machine"
	# -d, --choose device
	echo -e "-d|--device:\tchoose device, default for unagi"
	# -y,
	echo -e "-y\tauto flash the image without asking askeing (it's a joke)"
	# -h, --help
	echo -e "-h|--help\tDisplay help."
	echo -e "Example:"
	echo -e "  Download build.\t\t./autoflash.sh"
	echo -e "  Download engineer build.\tHTTP_USER=dog@foo.foo HTTP_PWD=foo ./autoflash.sh -e"
	echo -e "  Download and flash build.\t./autoflash.sh -f"
	echo -e "  Flash engineer build.\t\t./autoflash.sh -e -F"
	echo -e "  Flash engineer build, backup profile.\t\t./autoflash.sh -e -F -b"
	echo -e "  Flash engineer build, don't update kernel.\t./autoflash.sh -e -F --no-kernel"
	echo -e "  Flash build on leo devices.\t\t ./autoflash.sh -d=leo"
	exit 0
}

## version parsing
## arg1: version for flash, if the version is not specified then default option will be taken
## output: set version to global $Version_Flag
function version(){
    local_ver=$1
    case "$local_ver" in
        100|tef) Version_Flag="tef";;
        101|shira) Version_Flag="shira";;
        110|v1train) Version_Flag="v1train";;
    esac
}

function version_info(){
    echo -e "Available version:"
    echo -e "\t100|tef"
    echo -e "\t101|shira"
    echo -e "\t110|v1train"
}
function device(){
	local_dev=$1
	case "$local_dev" in
		unagi) Device_Flag="unagi";;
		otoro) Device_Flag="otoro";;
		inari) Device_Flag="inari";;
		leo) Device_Flag="leo";;
		buri) Device_Flag="buri";;
		hamachi) Device_Flag="hamachi";;
	esac
}

function device_info(){
	echo -e "Available device:"
	echo -e "\tunagi (default)"
	echo -e "\totoro"
	echo -e "\tinari"
	echo -e "\tleo"
	echo -e "\tburi"
}

## show helper if nothing specified
if [ $# = 0 ]; then echo "Nothing specified"; helper; exit 0; fi

## distinguish platform
case `uname` in
	"Linux")
		## add getopt argument parsing
		TEMP=`getopt -o fF::ebryhv::d:: --long flash,flash-only::,eng,version::,device::,tef,shira,v1train,backup,recover-only,help \
	    -n 'error occured' -- "$@"`

		if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi

		eval set -- "$TEMP";;
	"Darwin");;
esac

### TODO: -f can get an optional argument and download with build number or something
### write Filename and prevent for future modification

while true
do
    case "$1" in
        -f|--flash) Download_Flag=true; Flash_Flag=true; shift;;
        -F|--flash-only) Download_Flag=false; Flash_Flag=true;
           case "$2" in
            "") shift 2;;
             *) Filename=$2; shift 2;;
           esac ;;
        -e|--eng) Engineer_Flag=1; shift;;
        -v|--version) 
           case "$2" in
            "") version_info; exit 0; shift 2;;
             *) version $2; shift 2;;
           esac;;
        --tef) version "tef"; shift;;
        --shira) version "shira"; shift;;
        --v1train) version "v1train"; shift;;
        -b|--backup) Backup_Flag=true; shift;;
        -B|--backup-only) BackupOnly_Flag=true; shift;;
        -r|--recover-only) RecoverOnly_Flag=true; shift;;
		-d|--device)
			case "$2" in
			 "") device_info; exit 0; shift2;;
			 *) device $2; shift 2;;
			esac;;
		-y) AgreeFlash_Flag=true; shift;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
		"") shift;break;;
        *) echo error occured; exit 1;;
    esac
done

####################
# Backup Only task
####################
if [ $BackupOnly_Flag == true ]; then
	if [ ! -d mozilla-profile ]; then
		echo "no backup folder, creating..."
		mkdir mozilla-profile
	fi
	echo -e "Backup your profiles..."
	adb shell stop b2g 2> ./mozilla-profile/backup.log &&\
	rm -rf ./mozilla-profile/* &&\
	mkdir -p mozilla-profile/profile &&\
	adb pull /data/b2g/mozilla ./mozilla-profile/profile 2> ./mozilla-profile/backup.log &&\
	mkdir -p mozilla-profile/data-local &&\
	adb pull /data/local ./mozilla-profile/data-local 2> ./mozilla-profile/backup.log &&\
	rm -rf mozilla-profile/data-local/webapps
	adb shell start b2g 2> ./mozilla-profile/backup.log
	echo -e "Backup done."
	exit 0
fi

####################
# Recover Only task
####################
if [ $RecoverOnly_Flag == true ]; then
	echo -e "Recover your profiles..."
	if [ ! -d mozilla-profile/profile ] || [ ! -d mozilla-profile/data-local ]; then
		echo "no recover files."
		exit -1
	fi
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
# Check Files
####################
if [ $Device_Flag == "unagi" ]; then
	DownloadFilename=unagi.zip
	# tef v1.0.0: only user build
	if [ $Version_Flag == "tef" ]; then
		Engineer_Flag=0
		URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18_v1_0_0-unagi/latest/${DownloadFilename}
	# shira v1.0.1: eng/user build
	elif [ $Version_Flag == "shira" ] && [ $Engineer_Flag == 1 ]; then
		URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18_v1_0_1-unagi-eng/latest/${DownloadFilename}
	elif [ $Version_Flag == "shira" ] && [ $Engineer_Flag == 0 ]; then
		URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18_v1_0_1-unagi/latest/${DownloadFilename}
	# v1-train: eng/user build
	elif [ $Version_Flag == "v1train" ] && [ $Engineer_Flag == 1 ]; then
		URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18-unagi-eng/latest/${DownloadFilename}
	elif [ $Version_Flag == "v1train" ] && [ $Engineer_Flag == 0 ]; then
		URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18-unagi/latest/${DownloadFilename}
	else
		URL=https://pvtbuilds.mozilla.org/pub/mozilla.org/b2g/nightly/mozilla-b2g18_v1_0_1-unagi/latest/${DownloadFilename}
	fi
elif [ $Device_Flag == "leo" ]; then
	DownloadFilename=leo.zip
	Engineer_Flag=0
	# there is v1-train for leo device only
	if [ $Version_Flag == "v1train" ]; then
		URL=https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g18-leo/latest/${DownloadFilename}
	else
		echo -e "There is v1-train (v1.1.0) for leo device only"
		exit 0
	fi
elif [ $Device_Flag == "inari" ]; then
	DownloadFilename=inari.zip
	Engineer_Flag=0
	# there are shira and v1-train available for inari device
	if [ $Version_Flag == "shira" ]; then
		URL=https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g18_v1_0_1-inari/latest/${DownloadFilename}
	elif [ $Version_Flag == "v1train" ]; then
		URL=https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g18-inari/latest/${DownloadFilename}
	else
		echo -e "There are v1-train (v1.1.0) and shira (v1.0.1) available for inari device"
	fi
elif [ $Device_Flag == "otoro" ]; then
	DownloadFilename=otoro.zip
	Engineer_Flag=0
	# shira v1.0.1: eng/user build
	if [ $Version_Flag == "shira" ]; then
		URL=https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g18_v1_0_1-otoro/latest/${DownloadFilename}
	# v1-train: eng/user build
	elif [ $Version_Flag == "v1train" ]; then
		URL=https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g18-otoro/latest/${DownloadFilename}
	else
		echo -e "There are v1-train (v1.1.0) and shira (v1.0.1) available for otoro device"
	fi
elif [ $Device_Flag == "buri" ] || [ $Device_Flag == "hamachi" ]; then
	DownloadFilename=hamachi.zip
	Engineer_Flag=0
	# v1-train: eng/user build
	if [ $Version_Flag == "v1train" ]; then
		URL=https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g18-hamachi/latest/${DownloadFilename}
	else
		echo -e "There is v1-train (v1.1.0) for buri device"
	fi
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
	[ $Engineer_Flag == 0 ] && Build_SRT="User" || Build_SRT="Engineer"
	echo -e "\n\nDownload latest ${Version_Flag} ${Build_SRT} build..."
	wget --http-user="${HTTPUser}" --http-passwd="${HTTPPwd}" $URL

	# Check the download is okay
	if [ $? -ne 0 ]; then
		echo -e "Download $URL failed."
		exit 1
	fi

	# Modify the downloaded filename
	filetime=`stat -c %y `+${DownloadFilename}+` | sed 's/\s.*$//g'`
	if [ $Engineer_Flag == 1 ]; then
		Filename=${Device_Flag}_${filetime}_${Version_Flag}_eng.zip
	elif [ $Engineer_Flag == 0 ]; then
		Filename=${Device_Flag}_${filetime}_${Version_Flag}_usr.zip
	fi

	rm -f $Filename
	mv $DownloadFilename $Filename

else
	# Setup the filename for -F
    if ! [ -z $Filename ]; then
        echo "File name is $Filename"
    elif [ $Engineer_Flag == 1 ]; then
		Filename=`ls -tm `+${Device_Flag}+`_*_`+${Version_Flag}+`_eng.zip | sed 's/,.*$//g' | head -1`
	elif [ $Engineer_Flag == 0 ]; then
		Filename=`ls -tm `+${Device_Flag}+`_*_`+${Version_Flag}+`_usr.zip | sed 's/,.*$//g' | head -1`
	fi
fi

####################
# Decompress task
####################
# Check the file is exist
if ! [ -z $Filename ]; then
    test ! -f $Filename && echo -e "The file $Filename DO NOT exist." && exit 1
else
    echo -e "The file DO NOT exist." && exit 1
fi

# Delete folder
echo -e "Delete old build folder: b2g-distro"
rm -rf b2g-distro/

# Unzip file
echo -e "Unzip $Filename ..."
unzip $Filename || exit -1


####################
# Flash device task
####################
if [ $Flash_Flag == true ]; then
	if [ $AgreeFlash_Flag != true ]; then
		# make sure
		read -p "Are you sure you want to flash your device? [y/N]" isFlash
		if [ "$isFlash" != "y" ] && [ "$isFlash" != "Y" ]; then
			echo -e "byebye."
			exit 0
		fi
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
		if [ ! -d mozilla-profile ]; then
			echo "no backup folder, creating..."
			mkdir mozilla-profile
		fi
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
	if [ $Backup_Flag == true ] && [ -d mozilla-profile/profile ] && [ -d mozilla-profile/data-local ];  then
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

