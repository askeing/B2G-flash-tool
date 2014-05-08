#!/bin/bash
# setup a FxOS device for QA by forcing the 'nightly' update channel
set -e

while [ $# -gt 0 ]; do
  case "$1" in
    "-d")
      DEVICE="$2"
      shift
      ;;
    "-v")
      VERSION="$2"
      shift
      ;;
    "-h")
      echo "
      Help:
          -d <device>  : specify a device (leo, tarako, hamachi, helix, inari) to update
          -v <version> : version to update to (1.4.0, 1.3.0, 1.2.0, 1.1.1)
          -h : this help menu
      "
      ;;
    *)
      ;;
  esac
  shift
done

case "$DEVICE" in
  "leo")
    ;;
  "hamachi")
    ;;
  "helix")
    ;;
  "inari")
    ;;
  "tarako")
    ;;
  "flame")
    ;;
  *)
    echo "You must specify a device: leo, hamachi, helix or inari"
    exit
    ;;
esac

case "$VERSION" in
  "2.0.0")
    ;;
  "1.5.0")
    ;;
  "1.4.0")
    ;;
  "1.3.0")
    ;;
  "1.3.0t")
    ;;
  "1.2.0")
    ;;
  "1.1.1")
    ;;
  *)
    echo "You must specify a version : 2.0.0, 1.5.0, 1.4.0, 1.3.0t, 1.3.0, 1.2.0, 1.1.1 (1.1.1 for 1.1hd)"
    exit
    ;;
esac

UPDATE_CHANNEL=${UPDATE_CHANNEL:-$DEVICE/$VERSION/nightly}

ADB=${ADB:-adb}
$ADB wait-for-device

B2G_PREF_DIR=/system/b2g/defaults/pref
TMP_DIR=/tmp/channel-prefs
rm -rf $TMP_DIR
mkdir $TMP_DIR

cat >$TMP_DIR/updates.js <<UPDATES
pref("app.update.channel", "$UPDATE_CHANNEL");
UPDATES

$ADB root
$ADB remount
$ADB push $TMP_DIR/updates.js $B2G_PREF_DIR/updates.js

$ADB shell "stop b2g; start b2g"
