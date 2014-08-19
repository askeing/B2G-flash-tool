#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Internal Tool
# Description:
#   This script was written for mounting the fs1 server.
#==========================================================================

# Install nfs-common
sudo apt-get install nfs-common

# Create fs1 folder under home
DEST=$HOME/fs1
mkdir $DEST

# Append the setting of fs1 into /et/fstab
sudo echo -e "\nfs1.mozilla.com.tw:/Public\t$DEST\tnfs" >> /etc/fstab

# Mount fs1
sudo mount -a

# Show information of disk space
df
