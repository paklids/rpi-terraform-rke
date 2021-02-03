#!/bin/bash
# tested on OSX (Big Sur)
# be sure to `brew install pv` before starting
# and edit vars as needed below:
sdcard="/dev/disk2"
imgfile="$HOME/Downloads/ubuntu-20.10-preinstalled-server-arm64+raspi.img"
userdatafile="$HOME/Desktop/user-data"
networkconfigfile="$HOME/Desktop/network-config"
#
layout="$(df -h)"
imgsize=$(ls -la $imgfile | awk '{ print $5 }')
#
echo -e "$layout\n\n\t SD Card is at $sdcard\n"
#
read -p "Are you sure that you want to write $imgfile of $imgsize to $sdcard? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo -e "\n\tUnmounting disk\n"
    diskutil unmountDisk $sdcard
    echo -e "\n\tWriting to SDcard now...\n"
    dd if=$imgfile bs=524288 | pv -s $imgsize | dd of=$sdcard bs=524288
fi

read -p "Would you like to copy network-config and user-data to $sdcard? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mntlocation=$(df -h | grep $sdcard | awk '{ print $9 }')
    cp -f $userdatafile $mntlocation/
    cp -f $networkconfigfile $mntlocation/
fi
