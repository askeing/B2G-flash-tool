B2G-Flash-Tool
==

The tool is used for quick flashing the latest PVTBUILDs from Mozilla pvtbuild server. You'll need an LDAP account and accessibility to the folder to access it.

Usage
--

##### Usage: [Environment] ./autoflash.sh [--flash][--flash-only][--eng][-v=<version>][--backup][--backup-only][--recover-only][--device][-y][-h]


#### Environment:
        HTTP_USER={username} HTTP_PWD={password} ADB_PATH=<adb_path>

Environment is not a necessary condition. The script has an interaction mode if you leave it blank.

#### Parameters:

* -f|--flash
 * Flash your device (unagi) after downlaod finish.
		You may have to input root password when you add this argument.
		Your PATH should has adb path, or you can setup the ADB_PATH.
* -F|--flash-only
 * Flash your device from local zipped build(ex: -F{file name}); default: use latest downloaded
* -e|--eng
 * change the target build to engineer build.
* -v|--version &lt;version&gt;
 * give the target build version, ex: -vtef == -v100; show available version if nothing specified.
 * Or, you can give the version directly
> --tef<br>
> --shira<br>
> --v1train<br>
* -b|--backup
 * backup and recover the origin profile. (it will work with -f anf -F)
* -B|--backup-only:
 * backup the phone to local machine
* -R|--recover-only
 * recover the phone from local machine
* -d|--device &lt;device&gt;
 * choose device, default for unagi
* -y
 * auto flash the image without asking askeing (it's a joke)
* -h|--help
 * Display help.

#### Example:

To download an unagi Engineer build and auto flash into the device without prompt

    ./autoflash.sh -e -f -y

Download an leo user build and auto flash

    ./autoflash.sh -f -d=leo

