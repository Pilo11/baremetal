#!/bin/zsh
# This script will install or update the current baremetal OS
# parameters:
# 1. username of the main user (NOT ROOT)
# 2. profile of installing (LAPTOP, DESKTOP, SERVER)

# Save current user as variable
CURRUSER="$1"
PROFILE="$2"
CURRPATH="$PWD"

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

if [[ -z "$2" ]]; then
  echo "You did not choose any profile, so it will only do the standard installation"
fi

# check if script executed with root rights
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# methods and functions

COUNTER=0

# Increment counter
function inc {
  COUNTER=$((COUNTER + 1))
}

# This method updates all pacman packages without asking
function update {
  pacman -Syyu --needed --noconfirm > /dev/null
}

# This method updates all AUR packages without asking
function yupdate {
  sudo -u $CURRUSER yay -Syyu --needed --noconfirm > /dev/null
}

# This method checks if it is necessary to install a package and do it if needed.
function install {
  pacman -Sy $1 --needed --noconfirm > /dev/null
}

# This method checks if it is necessary to install an AUR package and do it if needed.
function yinstall {
  sudo -u $CURRUSER yay -Sy $1 --needed --noconfirm > /dev/null
}

# This method checks if a package is installed
function check {
  pacman -Qi $1 > /dev/null
}

# This methods checks the init things like yay, base-devel etc and install and configure it if needed
function init {
  # Update all pacman updates without asking for anything
  inc
  echo "$COUNTER. Update all installed packages"
  update
  # Install base-devel
  inc
  echo "$COUNTER. Install base-devel if needed"
  install "base-devel"
  # Change to build directory (if not exist, create one)
  inc
  echo "$COUNTER. Change to build directory"
  mkdir -p build
  cd build
  # Clone yay repo and install it
  inc
  echo "$COUNTER. Install yay if needed"
  # Check if yay is installed
  check yay
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
  # Install oh my zsh
  inc
  echo "$COUNTER. Install oh-my-zsh"
  # Check if it is installed already
  if [ -d "/home/$CURRUSER/.oh-my-zsh" ]; then
    echo "oh my zsh already found."
  else
    # Clone the git repo
    sudo -u $CURRUSER git clone https://github.com/robbyrussell/oh-my-zsh.git /home/$CURRUSER/.oh-my-zsh > /dev/null
    # Backup original zsh file
    sudo -u $CURRUSER cp /home/$CURRUSER/.zshrc /home/$CURRUSER/.zshrc.orig > /dev/null
    # Copy new zsh config
    sudo -u $CURRUSER cp /home/$CURRUSER/.oh-my-zsh/templates/zshrc.zsh-template /home/$CURRUSER/.zshrc > /dev/null
    # Set ZSH as new standard console
    chsh -s /bin/zsh > /dev/null
  fi
  # Patch makeconf file to prevent COMPRESSING AUR packages when installing
  inc
  echo "$COUNTER. Patch makepkg.conf for preventing COMPRESSION of AUR packages"
  patch -N /etc/makepkg.conf < $CURRPATH/patches/makepkg.conf.patch
}

# Blacklist nouveau and install nvidia driver
function nvidia {
  touch /etc/modprobe.d/blacklist.conf
  TEMP_DATA=$( cat /etc/modprobe.d/blacklist.conf | grep nouveau )
  if [ -n "$TEMP_DATA" ]; then
    echo "Nouveau already blacklisted"
  else
    # Blacklist nouveau driver
    echo "Blacklist nouveau driver"
    touch /etc/modprobe.d/blacklist.conf
    patch -N /etc/modprobe.d/blacklist.conf < $CURRPATH/patches/blacklist.conf.patch
    # Install nvidia and nvidia utils
    echo "Install nvidia and nvidia utils"
    yinstall nvidia
    yinstall nvidia-utils
    # Copy display script
    echo "Copy display script"
    cp $CURRPATH/display_script.sh /home/$CURRUSER/display_script.sh
    # Copy X11 config
    echo "Copy nvidia X11 configuration"
    cp $CURRPATH/20-intel.conf /etc/X11/xorg.conf.d/20-intel.conf
    # Apply lightdm patch
    echo "Apply patch for lightdm config"
    cat $CURRPATH/patches/lightdm.conf.patch | sed "s|%user%|$CURRUSER|g" > $CURRPATH/patches/lightdm.conf.patch.tmp
    patch -N /etc/lightdm/lightdm.conf < $CURRPATH/patches/lightdm.conf.patch.tmp
    rm -f $CURRPATH/patches/lightdm.conf.patch.tmp
    # Rebuild kernel boot image
    echo "Rebuild kernel boot image"
    mkinitcpio -p linux > /dev/null
  fi
}

# ---------------------------
# ----- code execution ------
# ---------------------------

# change to home directory
inc
echo "$COUNTER. Change working dir to home directory of the current user..."
cd /home/$CURRUSER

# These have to be called for all profiles
init

inc
# The following have to be called only if needed for the specific profiles
case "$PROFILE" in
'LAPTOP')
  echo "$COUNTER. Do profile work: $PROFILE"
  inc
  echo "$COUNTER. Install nvidia stuff and blacklist nouveau"
  nvidia
  ;;
'DESKTOP')
  echo "$COUNTER. Do profile work: $PROFILE"
  ;;
'SERVER')
  echo "$COUNTER. Do profile work: $PROFILE"
  ;;
*)
  echo "No profile was chosen, so nothing to do..."
  ;;
esac

# TODO: add i3 config + status bar + images + xrandr settings (gnome-terminals + feh)
# TODO: vmware install + preferences (LIKE Keyboard shortcuts)
# TODO: check multigesture availability and create multigesture shortcut mapping (3 finger tap)
