#!/bin/zsh
# This script will install or update the current baremetal OS
# parameters:
# 1. username of the main user (NOT ROOT)

# Save current user as variable
CURRUSER="$1"

# check if script executed with root rights
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# change to home directroy
echo "Change working dir to home directory of the current user..."
cd /home/$CURRUSER

# 1. Update all pacman updates without asking for anything
echo "Update all installed packages"
pacman -Syyu --needed --noconfirm > /dev/null
# 2. install base-devel
echo "Install base-devel if needed"
pacman -Sy base-devel --needed --noconfirm > /dev/null
# 3. change to build directory (if not exist, create one)
mkdir -p build
cd build
# 4. clone yay repo and install it
echo "Install yay if needed"
sudo -u $CURRUSER git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u $CURRUSER makepkg -sri --skippgpcheck --noconfirm
cd ..
rm -rf yay
# TODO
