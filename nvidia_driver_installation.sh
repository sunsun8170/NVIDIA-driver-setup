#! /usr/bin/bash

#################################################################
# This is a script for install / reinstall Nvidia driver.       #
# Author:    Young Lin                                          #
# Date:      01/10/2024                                         #
# Tested on: Ubuntu 20.04.6 LTS, Ubuntu 24.04 LTS               #
#################################################################

# Make sure running as root
if [ `id -u` -ne 0 ]; then
    echo "error: permision denied"
    exit 1
fi

echo "Installing Nvidia driver without CUDA and cuDNN. You can manually install them by yourself later."
echo "The following steps will be implemented: "
echo "1. Remove all related Nvidia driver packages completely."
echo "2. Remove CUDA if installed. (optional)"
echo "3. Install specific Nvidia driver choosen by user from a list of options."
echo "Caution: You are running this as root. Make sure what you are doing."
read -p "Do you want to continue? [Y/n] " ans
if [[ "$ans" != "Y" && "$ans" != "y" && "$ans" != "" ]]; then
  echo "error: aborted"
  exit 1
fi

# Remove Nvidia packages
sudo apt remove --purge "*nvidia*" -y

# Find and delete remaining Nvidia files
find /usr/lib -iname "*nvidia*" -delete

# Install Ubuntu desktop
sudo apt-get install ubuntu-desktop -y

# Add 'nouveau' to /etc/modules
echo 'nouveau' | sudo tee -a /etc/modules

# Remove xorg.conf
sudo rm /etc/X11/xorg.conf

# Remove CUDA
sudo /usr/local/cuda/bin/cuda-uninstaller

# Install nvidia-common
sudo apt install nvidia-common

# Add graphics-drivers PPA
echo | sudo add-apt-repository ppa:graphics-drivers

# Update package list
sudo apt update

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
    echo "error: invalid input"
  fi
done

# Install the Nvidia driver choosen by user
sudo apt install $pkg_name -y

# Clean the unused files
sudo apt autoremove

sudo apt autoclean

# Finish
echo
echo "'$selected_driver' was installed successfully. You can manually install CUDA and cuDNN by yourself later."
echo "Reboot your computer and excute 'nvidia-smi' to make sure your driver is working."
read -p "Reboot now? [Y/n] " ans
if [[ "$ans" == "Y" || "$ans" == "y"  || "$ans" == "" ]]; then
  sync; sync; sync; systemctl reboot
else
  read -n 1 -s -r -p "Press any key to exit..."
  echo
fi
