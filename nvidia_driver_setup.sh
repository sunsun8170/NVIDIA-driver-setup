#! /usr/bin/bash

############################################################################################
# This is a script for removing, installing, or reinstalling the Nvidia driver on Ubuntu.  #
# Author:         Young Lin                                                                #
# Last edited:    08/27/2024                                                               #
# Tested on:      Ubuntu 20.04.6 LTS, Ubuntu 24.04 LTS                                     #
############################################################################################

# Make sure running as root
if [ `id -u` -ne 0 ]; then
    echo "Error: This file has to be run with superuser privileges (under the root user on most systems)."
    exit 1
fi

# Create a log file
LOGFILE="/var/log/nvidia_driver_setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Tell the user what the script does
echo "Installing the Nvidia driver without CUDA and cuDNN. You can manually install them later if needed."
echo "The following steps will be executed: "
echo "1. Completely remove all files and packages related to Nvidia driver."
echo "2. Completely remove CUDA if installed."
echo "3. Install the specific Nvidia driver selected by the user from a list of available options."
echo "Caution: You are executing this script as root. Ensure that you fully understand the actions being performed."
read -p "Do you want to continue? [Y/n] " ans
if [[ "$ans" != "Y" && "$ans" != "y" && "$ans" != "" ]]; then
  echo "Error: Operation canceled."
  exit 1
fi

# Remove CUDA if installed
/usr/local/cuda/bin/cuda-uninstaller

# Remove Nvidia packages
apt-get remove --purge "*nvidia*" -y

# Find and delete remaining Nvidia files
find /usr/lib -iname "*nvidia*" -delete

# Add 'nouveau' to /etc/modules
# echo 'nouveau' | sudo tee -a /etc/modules

# Remove xorg.conf
rm /etc/X11/xorg.conf

# A function to ask whether to reboot or not
reboot() {
  read -p "Reboot now? [Y/n] " ans
  if [[ "$ans" == "Y" || "$ans" == "y"  || "$ans" == "" ]]; then
    sync; sync; sync; systemctl reboot
  else
    read -n 1 -s -r -p "Press any key to exit..."
    echo
  fi
  exit 0
}

# Ask the user if they want to reinstall Nvidia drivers
echo "The Nvidia drivers and CUDA have been completely removed from the system." 
read -p "Do you want to continue with the installation steps? [Y/n] " ans
if [[ "$ans" != "Y" && "$ans" != "y" && "$ans" != "" ]]; then
  echo "Nvidia driver installation has been skipped. Using the Nouveau driver instead."
  echo "See the log file at $LOGFILE"
  reboot
fi

# Install nvidia-common
apt-get install nvidia-common

# Add graphics-drivers PPA
echo | add-apt-repository ppa:graphics-drivers

# Update package list
apt-get update

# Check available drivers
echo
echo "Fetching available options for the driver. Please wait..."
echo
driver_info=$(ubuntu-drivers devices)

# Show options
devices_info=()
while IFS= read -r line; do
  devices_info+=("$line")
done <<< "$driver_info"

echo "Driver options:"
for ((i=4; i<${#devices_info[@]}; i++)); do
  option="${devices_info[$i]#*: }"
  echo "($((i-3))) $option"
done

while true; do
  read -p "Please select which to install: " choice

  if [[ $choice =~ ^[1-9][0-9]*$ && $choice -le $(( ${#devices_info[@]} - 4 )) ]]; then
    selected_driver=$(echo "${devices_info[$((choice+3))]}" | awk '{for(i=3;i<=NF;i++)printf "%s ", $i; print ""}')
    pkg_name=$(echo "${devices_info[$((choice+3))]}" | awk '{print $3}')
    read -p "Installing '$selected_driver', is that what you want? [Y/n] " ans

    if [[ "$ans" == "Y" || "$ans" == "y" || "$ans" == "" ]]; then
      break
    fi

  else
    echo "Error: Invalid input."
  fi
done

# Install the Nvidia driver choosen by user
apt-get install $pkg_name -y

# Clean the unused files
apt-get autoremove
apt-get autoclean

# Finish
echo
echo "'$selected_driver' was installed successfully. You can manually install CUDA and cuDNN later if needed."
echo "See the log file at $LOGFILE"
echo "Reboot your computer and run 'nvidia-smi' to ensure your driver is working."
reboot
