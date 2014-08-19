#!/bin/bash
#==========================================================================
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#==========================================================================
# Description:
#   This script was written for installing Oracle Java7 on Ubuntu.
#==========================================================================

# Install Oracle Java7
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java7-installer

update-java-alternatives -l
echo -e "You can run \"update-java-alternatives\" to update the alternatives of Java."
