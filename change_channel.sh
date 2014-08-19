#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================

# setup a FxOS device for QA by forcing the 'nightly' update channel
set -e

while [ $# -gt 0 ]; do
  case "$1" in
    "-v")
      VERSION="$2"
      shift
      ;;
    "-h")
      echo "
      Help:
          -v <version> : version to update to (nightly, aurora, nightly-b2g32 for 2.0, nightly-b2g30 for 1.4)
          -h : this help menu
      "
      ;;
    *)
      ;;
  esac
  shift
done

case "$VERSION" in
  "nightly")
    ;;
  "aurora")
    ;;
  "nightly-b2g32")
    ;;
  "nightly-b2g30")
    ;;
  *)
    echo "Please specify the version : -v (nightly, aurora, nightly-b2g32, nightly-b2g30)"
    exit
    ;;
esac

UPDATE_CHANNEL=${UPDATE_CHANNEL:-$VERSION}

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
