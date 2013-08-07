#!/bin/bash
#==========================================================================
# Copyright 2012, Mozilla Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#==========================================================================

####################
# Parameter Flags  #
####################
version_flag="central"
device_name="unagi"
sub_folder="/pub/mozilla/b2g/nightly/"
shallow_flag=false
gaia_flag=false
gecko_flag=false
engineer_flag=false
download_file='unagi.zip'
gaia_file='gaia.zip'
gecko_file='b2g-26.0a1.en-US.android-arm.tar.gz'


####################
# Functions        #
####################

## helper function
function helper(){
  echo -e "-g|--gaia\tDownload gaia (zip format)"
  echo -e "-G|--gecko\tDownload gecko (tar.gz format)"
  echo -e "-d|--device\tSelect devices"
  # -e, --eng
  echo -e "-e|--eng\tchange the target build to engineer build."
  # -v, --version
  echo -e "-v|--version, \t give the target build version, ex: -vtef == -v100; show available version if nothing specified."
  # --tef: tef build v1.0.0
  echo -e "--tef\tchange the target build to tef build v1.0.0."
  # --shira: shira build v1.0.1
  echo -e "--shira\tchange the target build to shira build v1.0.1."
  # --v1train: v1-train build
  echo -e "--v1train\tchange the target build to v1train build."
  # --v0: master build
  echo -e "--vmaster\tchange the target build to master build. (Currently, it's only for unagi)"
    
  exit 0
}

## version
function version(){
  local local_ver=$1
  gecko_file='b2g-18.0.en-US.android-arm.tar.gz'
  case "$local_ver" in
    100|tef) version_flag="b2g18_v1_0_0";;
    101|shira) version_flag="b2g18_v1_0_1";;
    110|v1train) version_flag="b2g18";;
    110hd|hd) version_flag="b2g18_v1_1_0_hd";;
    0|master)
      version_flag="central";
      gecko_file='b2g-26.0a1.en-US.android-arm.tar.gz';;
  esac
}

## get device name
function device(){
  local local_dev=$1
  sub_folder="/pvt/mozilla.org/b2gotoro/nightly/"
  case "$local_dev" in
    unagi) device_name="unagi";sub_folder="/pub/mozilla/b2g/nightly/";;
    otoro) device_name="otoro";;
    inari) device_name="inari";;
    leo) device_name="leo";;
    buri|hamachi) device_name="hamachi";;
    helix) device_name="helix";;
  esac
  download_file=$device_name.zip
  filename=$device_name-$version_flag.zip
}

## form URL for download
function form_URL()
{
  url=https://pvtbuilds.mozilla.org/
  moz=mozilla
  url=$url$sub_folder$moz-$version_flag-$device_name 
  if [ $engineer_flag == true ]; then
    url=$url-eng
    filename=${filename%.zip}-eng.zip
  fi
  url=$url/latest/
}

## download target URL
function download_URL()
{
  form_URL
  if [ $gaia_flag == false ] && [ $gecko_flag == false]; then
    echo -e 'Clean...'
    rm -rf $download_file
    wget --http-user="${HTTPUser}" --http-passwd="${HTTPPwd}" $url$download_file
    
    # Check the download is okay
    if [ $? -ne 0 ]; then
      echo -e "Download $download_file failed"
      echo -e "URL: $url"
      exit 1
    fi

    rm -rf $filename
    mv $download_file $filename
    echo "Download file saved as $filename"
  else
    echo -e 'Clean...'
    if [ $gaia_flag == true ]; then
      rm -rf $gaia_file
      wget --http-user="${HTTPUser}" --http-passwd="${HTTPPwd}" $url$gaia_file
    fi
    if [ $gecko_flag == true ]; then
      rm -rf $gecko_file
      wget --http-user="${HTTPUser}" --http-passwd="${HTTPPwd}" $url$gecko_file
    fi
  fi
}


#########################
# Processing Parameters #
#########################

## show helper if nothing specified
if [ $# = 0 ]; then echo "Nothing specified"; helper; exit 0; fi

## distinguish platform
case `uname` in
  "Linux")
    ## add getopt argument parsing
    TEMP=`getopt -o gGd::v::eh --long gaia,gecko,device::,version,eng,help \
    -n 'invalid option' -- "$@"`

    if [ $? != 0 ]; then echo "Try '--help' for more information." >&2; exit 1; fi

    eval set -- "$TEMP";;
  "Darwin");;
esac

while true
do
  case "$1" in
    -g|--gaia) gaia_flag=true; shift;;
    -G|--gecko) gecko_flag=true; shift;;
    -d|--device) device $2; shift 2;;
    -v|--version)
      case "$2" in
        "") version_info; exit 0; shift 2;;
        *) version $2; shift 2;;
      esac;;
    --tef) version "tef"; shift;;
    --shira) version "shira"; shift;;
    --v1train) version "v1train"; shift;;
    --hd) version "hd"; shift;;
    --master) version "master"; shift;;
    -e|--eng) engineer_flag=true; shift;;
    -h|--help) helper; exit 0;;
    --) shift; break;;
    "") shift; break;;
    *) helper; echo error occured; exit 1;;
  esac
done

## Prepare the authn of web site
if [ "$HTTP_USER" != "" ]; then
  HTTPUser=$HTTP_USER
else
  read -p "Enter HTTP Username (LDAP): " HTTPUser
fi
if [ "$HTTP_PWD" != "" ]; then
  HTTPPwd=$HTTP_PWD
else
  read -s -p "Enter HTTP Password (LDAP): " HTTPPwd
fi

download_URL


####################
# Done             #
####################
echo -e "Done!\nbyebye."


