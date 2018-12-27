#!/bin/zsh
# This script will install or update the current baremetal OS
# parameters:
# 1. username of the main user (NOT ROOT)

# Save current user as variable
CURRUSER="$1"

# check parameter
if [[ -z "$1" ]]; then
  echo "No parameter is not allowed. Please enter parameter: username"
  exit 1
else
  # check if username exists
  id -u $1 > /dev/null
  RETVAL=$?
  if [[ $RETVAL -ne 0 ]]; then
    echo "user $1 not found"
    exit 1
  fi
fi

# check if script executed with root rights
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# change to home directroy
echo "Change working dir to home directory of the current user..."
cd /home/$CURRUSER

# 1. Update all pacman updates without asking for anything
echo "1. Update all installed packages"
pacman -Syyu --needed --noconfirm > /dev/null
# 2. install base-devel
echo "2. Install base-devel if needed"
pacman -Sy base-devel --needed --noconfirm > /dev/null
# 3. change to build directory (if not exist, create one)
echo "3. Change to build directory"
mkdir -p build
cd build
# 4. clone yay repo and install it
echo "4. Install yay if needed"
# Check if yay is installed
pacman -Qi yay > /dev/null
YAY_CHECK=$?
if [ $YAY_CHECK -ne 0 ]; then
  sudo -u $CURRUSER git clone https://aur.archlinux.org/yay.git > /dev/null
  cd yay
  sudo -u $CURRUSER makepkg -sri --skippgpcheck --noconfirm > /dev/null
  cd ..
  rm -rf yay
else
  echo "YAY already exist"
fi
# TODO: install oh-my-zsh
# TODO: remove packaging from pacman.conf
# TODO: remove nouveau and install nvidia + X11 conf + lightdm conf
# TODO: install gnome-terminals + feh for i3 config
# TODO: add i3 config + status bar + images + xrandr settings
