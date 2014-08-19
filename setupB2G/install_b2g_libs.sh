#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for installing requisites library.
#==========================================================================

# Install Java 7
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java7-installer

# Install requisites
sudo apt-get install autoconf2.13 bison bzip2 ccache curl flex gawk gcc g++ g++-multilib git ia32-libs lib32ncurses5-dev lib32z1-dev libgl1-mesa-dev libx11-dev make mercurial

# Create symbolic links for the 32-bit version
sudo ln -s /usr/lib/i386-linux-gnu/libX11.so.6 /usr/lib/i386-linux-gnu/libX11.so
sudo ln -s /usr/lib/i386-linux-gnu/mesa/libGL.so.1 /usr/lib/i386-linux-gnu/libGL.so
