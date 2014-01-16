#!/bin/bash

# Install Oracle Java7
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java7-installer

update-java-alternatives -l
echo -e "You can run \"update-java-alternatives\" to update the alternatives of Java."
