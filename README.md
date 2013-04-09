autoflash.sh
=========

for fast flashing images to devices

v 11.0
This script will download latest release build from pvt server. (only for unagi now)

Usage: [Environment] ./autoflash.sh [parameters]
Environment:
  HTTP_USER={username} HTTP_PWD={pw} ADB_PATH=adb_path

-f|--flash	Flash your device (unagi) after downlaod finish.
		You may have to input root password when you add this argument.
		Your PATH should has adb path, or you can setup the ADB_PATH.
-F|--flash-only	Flash your device from local zipped build(ex: -F{file name}); default: use latest downloaded
-e|--eng	change the target build to engineer build.
-v|--version, 	 give the target build version, ex: -vtef == -v100; show available version if nothing specified.
--tef	change the target build to tef build v1.0.0.
--shira	change the target build to shira build v1.0.1.
--v1train	change the target build to v1train build.
-b|--backup	backup and recover the origin profile.
		(it will work with -f anf -F)
-B|--backup-only:	backup the phone to local machine
-R|--recover-only:	recover the phone from local machine
-d|--device:	choose device, default for unagi
-y	auto flash the image without asking askeing (it's a joke)
-h|--help	Display help.
Example:
  Download build.		            ./autoflash.sh
  Download engineer build.  	  HTTP_USER=dog@foo.foo HTTP_PWD=foo ./autoflash.sh -e
  Download and flash build.	    ./autoflash.sh -f
  Flash engineer build.	      	./autoflash.sh -e -F
  Flash engineer build, backup profile.	  	  ./autoflash.sh -e -F -b
  Flash engineer build, don't update kernel.	./autoflash.sh -e -F --no-kernel
  Flash build on leo devices.		 ./autoflash.sh -d=leo
