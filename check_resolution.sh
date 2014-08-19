#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for checking using the correct resolution icons.
#
# Author: Al Tsai[:atsai] atsai@mozilla.com
# History:
#   2013/07/22 Al: v1.0 First release (only for helix).
#==========================================================================

####################
# Parameter Flags
####################
Branch="helix"
Resolution="@1.5x"
Gaia_Path=
Base_File=

####################
# Functions
####################
function helper(){
    echo "[checkResolution.sh] Coming soon..."
}

####################
# Executions
####################
## distinguish platform
case `uname` in
    "Linux")
        ## add getopt argument parsing
        TEMP=`getopt -o b::p::r:: --long branch::,gaia_path::,resolution -n 'error occured' -- "$@"`
        if [ $? != 0 ]; then echo "Terminating..." >&2; exit 1; fi

        eval set -- "$TEMP";;
    "Darwin");;
esac

while true
do
    case "$1" in
        -b|--branch) Branch=$2; shift 2;;
        -p|--gaia_path) Gaia_Path=$2; shift 2;;
        -r|--resolution) 
            case "$2" in
                "1.5") Resolution="@1.5x"; shift 2;;
                "2.0"|"2") Resolution="@2x"; shift 2;;
            esac;;
        -h|--help) helper; exit 0;;
        --) shift;break;;
        "") shift;break;;
        *) echo error occured; exit 1;;
    esac
done

rm -rf dir > /dev/null &> /dev/null
rm size.txt > /dev/null &> /dev/null
rm sizeDiff.txt > /dev/null &> /dev/null

mkdir dir > /dev/null &> /dev/null

echo "Pull data from device"
adb wait-for-device
adb pull /data/local/webapps/ dir/ > /dev/null &> /dev/null
cd dir


for f in $(ls */application.zip)
do
  path=${f%.*}
  unzip $f style/images/* -d $path > /dev/null 2>&1
  for images in $(ls $path/style/images/*.png 2> /dev/null)
  do
      echo $images >> ../size.txt
      ls -al $images | awk '{print $5}' >> ../size.txt 
  done
done

if [ -d "${Gaia_Path}" ]; then
    echo "Use path: "${Gaia_Path}
    for images in $(ls $Gaia_Path/apps/*/style/images/*$Resolution.png 2> /dev/null)
    do
        suffix="${images##*/apps/}"
        prefix="${suffix%/style*}"
        fn=$(basename $images)
        echo $prefix.gaiamobile.org/application/style/images/${fn%%$Resolution*}.png >> ../gaiaPngSize.txt
        ls -al $images | awk '{print $5}' >> ../gaiaPngSize.txt
    done
    Base_File="../gaiaPngSize.txt"
else
    echo "Use data on altsai respository for comparison"
    git clone http://github.com/altsai/checkResolution.git
    cd checkResolution
    git checkout $Branch 2>&1
    cd ..
    Base_File="checkResolution/size.txt"
fi

echo "diff -u $Base_File ../size.txt > sizeDiff.txt"
diff -u $Base_File ../size.txt > sizeDiff.txt
fileSize=$(ls -al sizeDiff.txt | awk '{print $5}')
if [ $fileSize == "0" ]; then
    echo "TEST PASS!"
else
    cp sizeDiff.txt ../
    echo "output Diff to sizeDiff.txt"
fi

cd ..
rm -rf dir
