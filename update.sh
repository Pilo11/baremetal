e#!/bin/zsh
# This script will install or update the current baremetal OS

# Save current user as variable
CURRUSER="$USER"

# check if script executed with root rights
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# change to home directroy
echo "Change working dir to home directory of the current user..."
cd ~

# 1. Update all pacman updates without asking for anything
pacman -Syyu
# 2. install base-devel
pacman -Sy base-devel
# 3. change to build directory (if not exist, create one)
mkdir -p build
cd build
# 4. clone yay repo and install it
git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u $CURRUSER makepkg -sri --skippgpcheck --noconfirm
cd ..
rm -rf yay
# TODO
