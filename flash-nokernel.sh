#!/bin/bash

OS=`uname -s | tr "[[:upper:]]" "[[:lower:]]"`

ADB=${ADB:-adb}
FASTBOOT=${FASTBOOT:-fastboot}

if [ ! -f "`which \"$ADB\"`" ]; then
	if [ "$OS" != "linux" ]; then
		echo "adb not found on your PATH, and this package does not contain"
		echo "an adb appropriate for your system; see README.txt"
		exit = -1
	fi
	ADB=./adb
fi

if [ ! -f "`which \"$FASTBOOT\"`" ]; then
	if [ "$OS" != "linux" ]; then
		echo "fastboot not found on your PATH, and this package does not contain"
		echo "a fastboot appropriate for your system; see README.txt"
		exit = -1
	fi
	FASTBOOT=./fastboot
fi

fail()
{
  echo "Failed to execute ADB or FASTBOOT command."
  echo "If you got a permissions error, you may need to run this script"
  echo "with sudo."
  exit -1
}

update_time()
{
	echo "Attempting to set the time on the device..."
	sleep 5
	$ADB wait-for-device &&
	$ADB shell toolbox date `date +%s` &&
	$ADB shell setprop persist.sys.timezone `date +%Z%:::z|tr +- -+` || exit -1
}

flash_fastboot()
{
	echo "Rebooting into device bootloader..."
	$ADB reboot bootloader
	$FASTBOOT devices

	if [ $? -ne 0 ]; then
		echo Couldn\'t setup fastboot
		fail
	fi

	echo "Flashing system images..."
	$FASTBOOT erase cache &&
	$FASTBOOT erase userdata &&
	$FASTBOOT flash userdata userdata.img &&
	$FASTBOOT flash system system.img &&
	echo "Rebooting..." &&
	$FASTBOOT reboot || exit -1

	echo "Setting system permissions..."
	sleep 50
	$ADB wait-for-device remount &&
	$ADB shell chmod 755 /system/b2g/b2g &&
	$ADB shell chmod 755 /system/b2g/plugin-container &&
	$ADB shell chmod 755 /system/b2g/updater || exit -1
}

flash_fastboot
update_time

