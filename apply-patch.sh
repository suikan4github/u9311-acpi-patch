#!/bin/sh

# Include the patch functions from the lib directory.
. ./lib/patch-fedora.sh
. ./lib/patch-ubuntu.sh

# Validate the vender. 
# Check the hostnamectl command and make sure the "Hadware Vendor" field contains "FUJITSU".
if ! hostnamectl | grep -q "Hardware Vendor: FUJITSU"; then
    echo "This script is only for Fujitsu laptops. Exiting."
    exit 1
fi  


# Check if it is Fedora Workstation or Fedora Silverblue.
if [ -f /etc/fedora-release ]; then
    patch-fedora
# Elese if it is Ubuntu.
elif [ -f /etc/lsb-release ]; then
    patch-ubuntu
else
    echo "Unsupported Linux distribution. Exiting."
    exit 1
fi

