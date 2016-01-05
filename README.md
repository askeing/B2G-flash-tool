# Script tools for B2G project


The `B2G-flash-tool` was **deprecated** after pvtbuild sever down.

And some b2g tools were moved to `b2g_util` package, ex. check_versions, shallow_flash, get_crashreposts, and so on.

For taskcluster, there are CLI (for automation) and GUI (for human) tools in `taskcluster_util` package.

* https://pypi.python.org/pypi/b2g_util
* https://pypi.python.org/pypi/taskcluster_util


## flash_pvt.py
The flash_pvt.py is a flash tool for B2G PVT Nightly builds which is written by Python.

Usage helper: 
```
$ ./flash_pvt.py --help
```

### PREREQUISITE
Linux or MAC
You will need adb and fastboot installed on your machine.

Android-SDK can be downloaded from http://developer.android.com/sdk/index.html 

Require git installed.
Require Python installed.
Optional, Python Tkinter installed for interactive mode.
  In ubuntu:
```
sudo apt-get install python-tk
```
  In fedora:
```
sudo yum install tkinter
```

### GUI Mode
```
$ ./flash_pvt.py -w
```

### Usage 
```
Usage: flash_pvt.py [-h] [-v VERSION] [-d DEVICE] [-s SERIAL] [-f] [-g] [-G]
                    [--usr] [--eng] [-b BUILD_ID] [-w] [-u USERNAME]
                    [-p PASSWORD] [--dl_home DL_HOME]

B2G Flash Tool by TWQA

optional arguments:
  -h, --help            show this help message and exit
  -v VERSION, --version VERSION
                        target build version
  -d DEVICE, --device DEVICE
                        target device codename
  -s SERIAL, --serial SERIAL
                        directs command to device with the given serial number
  -f, --full_flash      flash full image of device
  -g, --gaia            shallow flash gaia into device
  -G, --gecko           shallow flash gaia into device
  --usr                 specify user build
  --eng                 specify engineer build
  -b BUILD_ID, --build_id BUILD_ID
                        specify target build YYYYMMDDhhmmss
  -w, --window          interaction GUI mode
  -u USERNAME, --username USERNAME
                        LDAP account (will load from .flash_pvt file if
                        exists)
  -p PASSWORD, --password PASSWORD
                        LDAP password (will load from .flash_pvt file if
                        exists)
  --dl_home DL_HOME     specify download forlder
  --keep_profile        keep the user profile (BETA)
```

For example, flash the Gaia and Gecko of mozilla-central Flame latest Engineer build:
```
 $ ./flash_pvt.py -d flame -v central --eng -g -G
```

### Keep User Profile
If you want to keep your profile on the phone, you can enable this feature by command line or by GUI.

**PS:** Due to [Bug 1026531](https://bugzilla.mozilla.org/show_bug.cgi?id=1026531) is not fixed now, we can not guarantee it always works fine.
```
 $ ./flash_pvt.py {YOUR_OPTIONS} --keep_profile
```

### Flash without downloading again
If you want to flash other phones without download again, the screen will show you the commands to help you flash again. 
```
ex:
 ### INFO: !!NOTE!! Following commands can help you to flash packages into other device WITHOUT download again.
 ./shallow_flash.sh -y -gpvt/mozilla-central-flame-eng/latest/gaia.zip -Gpvt/mozilla-central-flame-eng/latest/b2g-33.0a1.en-US.android-arm.tar.gz
```

### LDAP
If you want to skip the step of enter LDAP account, please executing flash_pvt.py once, then filling your LDAP account information into .flash_pvt file. 
```
$ {YOUR_EDITOR} .flash_pvt
{
  "account": "",
  "password": "",
  "download_home": "pvt",
  "base_url": "https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/"
}
```

See Mozilla Intra-Wiki for more detail information.

### Note:
If you are **MAC OS X User**, and got the error while trying to get the build from server.

```bash
Connecting to path.to.server|xxx.xxx.xxx.xxx|:443... connected.
ERROR: The certificate of 'path.to.server' is not trusted.
ERROR: The certificate of 'path.to.server' hasn't got a known issuer.
Download https://path.to.server/xxx/xxx/xxx.zip failed.
```

Please do the following steps to fix the wget problem, and try again.

```bash
sudo port install curl-ca-bundle
echo CA_CERTIFICATE=/opt/local/share/curl/curl-ca-bundle.crt >> ~/.wgetrc
```

----

## auto_flash_from_twci.sh
This script was written for download builds from TW-CI server.

### Usage:
```
Usage: ./auto_flash_from_twci.sh [parameters]
  -v|--version  the target build version.
  -d|--device   the target device.
  -s <serial number>    directs command to device with the given serial number.
  -f|--full     flash full image into device.
  -g|--gaia     shallow flash gaia into device.
  -G|--gecko    shallow flash gecko into device.
  -w            interaction GUI mode.
  -y            Assume "yes" to all questions
  -h|--help     display help.
Environment:
  UNINSTALL_COMRIL=true         uninstall the com-ril when shallow flash gecko. (Keep com-ril by default)
Example:
  Flash by interaction GUI mode         ./auto_flash_from_twci.sh -w
  (Linux) Flash wasabi v1.2.0 image             ./auto_flash_from_twci.sh -vv1.2.0 -dwasabi -f
  (MAC)   Flash wasabi v1.2.0 image             ./auto_flash_from_twci.sh -v v1.2.0 -d wasabi -f
  (Linux) Flash nexus4 master gaia/gecko        ./auto_flash_from_TWCI.sh --version=master --device=nexus4 -g -G
  (MAC)   Flash nexus4 master gaia/gecko        ./auto_flash_from_TWCI.sh --version master --device nexus4 --gaia --gecko
```

----

## backup_restore_profile.py
This script was written for backup and restore user profile. (BETA)

**PS:** Due to [Bug 1026531](https://bugzilla.mozilla.org/show_bug.cgi?id=1026531) is not fixed now, we can not guarantee it always works fine.

### Usage:
```
usage: backup_restore_profile.py [-h] [-s SERIAL] [-b] [-r] [--sdcard]
                                 [--no-reboot] [-p PROFILE_DIR] [--debug]

Backup and restore Firefox OS profiles. (BETA)

optional arguments:
  -h, --help            show this help message and exit
  -s SERIAL, --serial SERIAL
                        Directs command to the device or emulator with the
                        given serial number. Overrides ANDROID_SERIAL
                        environment variable. (default: None)
  -b, --backup          Backup user profile. (default: False)
  -r, --restore         Restore user profile. (default: False)
  --sdcard              Also backup/restore SD card. (default: False)
  --no-reboot           Do not reboot B2G after backup/restore. (default:
                        False)
  -p PROFILE_DIR, --profile-dir PROFILE_DIR
                        Specify the profile folder. (default: mozilla-profile)
  --debug               Debug mode. (default: False)
  ```

----

## change_channel.sh
Setup a FxOS device for QA by forcing the 'nightly' update channel

### Usage:
```
Help:
    -v <version> : version to update to (nightly, aurora, nightly-b2g32 for 2.0, nightly-b2g30 for 1.4)
    -h : this help menu
      
Please specify the version : -v (nightly, aurora, nightly-b2g37, nightly-b2g34, nightly-b2g32, nightly-b2g30)
nightly-b2g37 is 2.2 ; nightly-b2g34 is 2.1; nightly-b2g32 is 2.0, nightly-b2g30 is 1.4

```

----

## change_ota_url.sh
This script is used to change OTA update URL to a local or a specific URL.

### Usage:
```
-h, --help      Show usage.
-p              Show prefs file of device.
-u, --url       The update.xml URL.
```

### Example:
Change the OTA update URL to http://update.server/update.xml.

    ./change_OTA_URL.sh --url http://update.server/update.xml

----

## check_versions.py
Checking the version of B2G on devices.

Please make sure your devices can be detected by ADB tool.

### Usage:
```
usage: check_versions.py [-h] [--no-color] [-s SERIAL] [--log-text LOG_TEXT]
                         [--log-json LOG_JSON]

Check the version information of Firefox OS.

optional arguments:
  -h, --help            show this help message and exit
  --no-color            Do not print with color. NO_COLOR will overrides this
                        option. (default: False)
  -s SERIAL, --serial SERIAL
                        Directs command to the device or emulator with the
                        given serial number. Overrides ANDROID_SERIAL
                        environment variable. (default: None)
  --log-text LOG_TEXT   Text ouput. (default: None)
  --log-json LOG_JSON   JSON output. (default: None)
```

----

## disable_ftu.py
Disable FTU for Firefox OS.

----

## enable_certified_apps_for_devtools.sh
Enable the Certified Apps support for WebIDE development tool.

### Usage
```
Please enable "ADB and Devtools" of your device before using App Manager.

Usage: ./enable_certified_apps_for_devtools.sh [parameters]
  -s <serial number>    directs command to device with the given serial number.
  -h|--help     display help.
```

----

## flash_local.py
The GUI mode for shallow-flashing Gaia and/or Gecko. (It will use the `shallow_flash.sh` script.)

----

## flash_tbpl.py
The flash_tbpl.py is a flash tool for B2G PVT Tinderbox builds which is written by Python.

### Usage
```
usage: flash_tbpl.py [-h] [-v VERSION] [-d DEVICE] [-s SERIAL] [-f] [-g] [-G]
                     [--usr] [--eng] [--debug] [-b BUILD_ID] [-w]
                     [-u USERNAME] [-p PASSWORD] [--dl_home DL_HOME]
                     [--keep_profile]

B2G Flash Tool by TWQA

optional arguments:
  -h, --help            show this help message and exit
  -v VERSION, --version VERSION
                        target build version
  -d DEVICE, --device DEVICE
                        target device codename
  -s SERIAL, --serial SERIAL
                        directs command to device with the given serial number
  -f, --full_flash      flash full image of device
  -g, --gaia            shallow flash gaia into device
  -G, --gecko           shallow flash gaia into device
  --usr                 specify user build
  --eng                 specify engineer build
  --debug               specify debug build
  -b BUILD_ID, --build_id BUILD_ID
                        specify target build YYYYMMDDhhmmss
  -w, --window          interaction GUI mode
  -u USERNAME, --username USERNAME
                        LDAP account (will load from .flash_pvt file if exists)
  -p PASSWORD, --password PASSWORD
                        LDAP password (will load from .flash_pvt file if exists)
  --dl_home DL_HOME     specify download forlder
  --keep_profile        keep the user profile (BETA)

example:
  $ ./flash_pvt.py -d flame -v mozilla-central --eng -g -G 
  $ ./flash_pvt.py -d hamachi -v mozilla-b2g30_v1_4 -b 20140718000231 --usr -g -G
```

----

## get_crashreports.sh
This is to get the crash reports of submitted/pending.

It will get reports under `/data/b2g/mozilla/Crash Reports/` on device.

----

## install_comril.sh
This script was written for uninstall/install com-ril.

### Usage:
```
Usage: ./install_comril.sh [parameters]
  -u|--uninstall        uninstall the com-ril.
  -r|--ril      install the com-ril from the file.
  -d|--ril-debug        turn on ril debugging.
  -s <serial number>    directs command to device with the given serial number.
  -y            Assume "yes" to all questions
  -h|--help     display help.

```

----

## reset_phone.sh
This script was written to reset the Firefox OS phone.

### Usage
```
Usage: ./reset_phone.sh [parameters]
  -s <serial number>    directs command to device with the given serial number.
  -h|--help     display help.
```

----

## shallow_flash.sh
This script was written for shallow flash the gaia and/or gecko.

### Usage:
```
Usage: ./shallow_flash.sh [parameters]
-g|--gaia       Flash the gaia (zip format) into your device.
-G|--gecko      Flash the gecko (tar.gz format) into your device.
--keep_profile  Keep the user profile on your device. (BETA)
-s <serial number>      directs command to device with the given serial number.
-y              flash the file without asking askeing (it's a joke...)
-h|--help       Display help.
Example:
  Flash gaia.           ./shallow_flash.sh --gaia=gaia.zip
  Flash gecko.          ./shallow_flash.sh --gecko=b2g-18.0.en-US.android-arm.tar.gz
  Flash gaia and gecko. ./shallow_flash.sh -ggaia.zip -Gb2g-18.0.en-US.android-arm.tar.gz
```

----

## update_system_fonts.sh
Update the system fonts of B2G v2.1 (Bug 1032874).

### Usage:
```
Usage: ./update_system_fonts.sh
```

----


