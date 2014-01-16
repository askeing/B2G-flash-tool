#!/bin/bash

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
