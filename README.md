# Script tools for B2G project


## autoflash.sh

This script will download latest release build from pvt server. You'll need an LDAP account and accessibility to the folder to access it.

**Usage: [Environment] ./autoflash.sh [--flash][--flash-only][--eng][-v=<version>][--backup][--backup-only][--recover-only][--device][-y][-h]**


### Environment:

```
HTTP_USER={username} HTTP_PWD={password} ADB_PATH=<adb_path>
```

Environment is not a necessary condition. The script has an interaction mode if you leave it blank.

### Parameters:

```
-f|--flash      Flash your device (unagi) after downlaod finish.
                You may have to input root password when you add this argument.
                Your PATH should has adb path, or you can setup the ADB_PATH.
-F|--flash-only Flash your device from local zipped build(ex: -F{file name}); default: use latest downloaded
-e|--eng        change the target build to engineer build.
-v|--version,    give the target build version, ex: -vtef == -v100; show available version if nothing specified.
--tef   change the target build to tef build v1.0.0.
--shira change the target build to shira build v1.0.1.
--v1train       change the target build to v1train build.
--vmaster       change the target build to master build. (Currently, it's only for unagi)
-b|--backup     backup and recover the origin profile.
                (it will work with -f anf -F)
-B|--backup-only:       backup the phone to local machine
-R|--recover-only:      recover the phone from local machine
-d|--device:    choose device, default for unagi
-y      auto flash the image without asking askeing (it's a joke)
-h|--help       Display help.
```

### Example:

To download an unagi Engineer build and auto flash into the device without prompt

    ./autoflash.sh -e -f -y

Download an leo user build and auto flash

    ./autoflash.sh -f -d=leo


## check_versions.sh

Checking the version of B2G on devices.
Please make sure your devices can be detected by ADB tool.


## enable_captiveportal.sh

This script was written for enable Captive Portal detection for v1.0.1 and above.

Please create the config file `.enable_captiveportal.conf` first.

ex:
```
CONF_URL=http://this.is.example/index.html
CONF_CONTENT=TEST_VALUE\\n
```
The [Bug 869394](https://bugzil.la/869394) turn on Captive Portal detection by default after 2013/05/09.


## download_desktop_client.sh

This script was written for download last desktop from server.

Please create the config file `.download_desktop_client.conf` first.

ex:
```
CONF_LINUX_32_URL=https://path.to.linux32bit.desktopclient.file/
CONF_LINUX_64_URL=https://path.to.linux64bit.desktopclient.file/
CONF_MAC_URL=https://path.to.mac.desktopclient.file/
```

Visit [MDN: Using the B2G desktop client](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox_OS/Using_the_B2G_desktop_client) for more detail information.


## get_crashreports.sh

This is to get the crash reports of submitted/pending.


## grant_geo_permission.sh

This script was written for grant the geolocation permission of unagi.

