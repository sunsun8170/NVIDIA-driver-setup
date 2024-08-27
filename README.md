# NVIDIA Driver Setup Bash Script

## What is this?

This is an **EXPERIMENTAL** bash script designed for the easy removal, installation, or reinstallation of Nvidia drivers. **THIS SCRIPT IS FOR UBUNTU ONLY!**

## Uh-Huh, Then?

The script will first remove all files and packages related to Nvidia and CUDA. It will then prompt the user to continue with the installation process. If the user chooses to proceed, the script will fetch the list of available drivers and install the version selected by the user. If the user opts not to continue, the script will exit and the Nouveau driver will be used instead.

The log file will be stored at `/var/log/nvidia_driver_setup.log`.

## How to use?

This script requires sudo privileges.

```bash=
chmod +x nvidia_driver_setup.sh
sudo bash nvidia_driver_setup.sh
```

## Tested Environment


* Ubuntu 20.04.2 LTS + NVIDIA GeForce GTX 1060 6GB

