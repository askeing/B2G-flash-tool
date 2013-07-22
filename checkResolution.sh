#!/bin/bash
#==========================================================================
# Copyright 2012, Mozilla Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
Branch=helix
Resolution=1.5
Gaia_Path=

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
        -b|--branch) Branch=$1; shift 2;;
        -p|--gaia_path) Gaia_Path=$1; shift 2;;
        -r|--resolution) Resolution=$1; shift 2;;
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
  unzip $f style/images/* -d $path > /dev/null &> /dev/null
  for images in $(ls $path/style/images/*.png &> /dev/null)
  do
      echo $images >> ../size.txt
      ls -al $images | awk '{print $5}' >> ../size.txt 
  done
done

if true; then
    echo "Use data on altsai respository for comparison"
    git clone http://github.com/altsai/checkResolution.git > /dev/null &> /dev/null
    cd checkResolution
    git checkout $Branch > /dev/null &> /dev/null
    cd ..
    diff -u checkResolution/size.txt ../size.txt > sizeDiff.txt
    fileSize=$(ls -al sizeDiff.txt | awk '{print $5}')
    if [ $fileSize == "0" ]; then
        echo "TEST PASS!"
    else
        cp sizeDiff.txt ../
        echo "output Diff to sizeDiff.txt"
    fi
fi

cd ..
rm -rf dir
