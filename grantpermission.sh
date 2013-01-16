#!/bin/bash

adb -s full_unagi shell sqlite3 /data/local/permissions.sqlite "UPDATE moz_hosts SET permission=1 WHERE type='geolocation' AND permission!=1;"
adb -s full_unagi reboot
