#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# 
# IMPORTANT: only for internal use!
# 
# Description:
#   This script was written for grant the geolocation permission of unagi.
#
# Author: Askeing fyen@mozilla.com
# History:
#   2013/01/16 Askeing: Added the description of script.
# 
#==========================================================================

for x
do
	# -h, --help, -?: help
	if [ "$x" = "--help" ] || [ "$x" = "-h" ] || [ "$x" = "-?" ]; then
		echo -e "This script was written for grant the geolocation permission of unagi."
		# -h, --help
		echo -e "-h, --help\tDisplay help."
		echo -e "-?\t\tDisplay help."
		exit 0
	else
		echo -e "'$x' is an invalid command. See '--help'."
		exit 0
	fi
done

adb -s full_unagi shell sqlite3 /data/local/permissions.sqlite "UPDATE moz_hosts SET permission=1 WHERE type='geolocation' AND permission!=1;"
adb -s full_unagi reboot
