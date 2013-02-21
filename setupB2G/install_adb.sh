#!/bin/bash

# Create temp folder
TEMP_DIR=$(mktemp -d)

# Clone adb fastboot install project
cd $TEMP_DIR
git clone https://github.com/teamblueridge/adb-fastboot-install.git

# Install adb into system
cd adb-fastboot-install
./ADB-Install-Linux.sh

# Clean temp folder
cd ~
rm -rf $TEMP_DIR
