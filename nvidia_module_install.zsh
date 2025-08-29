#!/usr/bin/zsh
# Install the proper Nvidia drivers against service conflicts for Wayland.

# Author and Copyright (c) 2023–2025 Maulik Mistry <mistry01@gmail.com>
# If you find this project useful and would like to support its development, consider donating via
# Paypal: https://www.paypal.com/paypalme/m1st0
# Venmo: https://venmo.com/code?user_id=3319592654995456106

# License: Apache License 2.0
# All rights reserved.


# Prevent conflicting services from being installed in newer packages.
# Define where the source file is (your custom preference file)
SOURCE_FILE="nvidia-kernel-common-570.conf"

# Define the target path
TARGET_PATH="/etc/apt/preferences.d/nvidia-kernel-common-570"

# Check if source file exists
if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Source file $SOURCE_FILE does not exist. Please create it first."
  exit 1
fi

# Need root permissions to symlink into /etc
echo "Creating symlink as root..."
sudo cp "$SOURCE_FILE" "$TARGET_PATH"

if [[ $? -eq 0 ]]; then
  echo "Nvidia conflicting package services prevented from install: "
  ls -la $TARGET_PATH
else
  echo "Failed to create symlink."
fi

kernel_name=$(uname -r)

# Define the packages to check
packages=(
    "linux-modules-nvidia-570-${kernel_name}"
    "linux-objects-nvidia-570-${kernel_name}"
    "linux-signatures-nvidia-${kernel_name}"
    "nvidia-utils-570"
    "libnvidia-gl-570"
    # Until we have X11 gone.
    "xserver-xorg-video-nvidia-570"
)

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -q "^ii  $1"
}

# Check if each package is installed
all_installed=true
for package in "${packages[@]}"; do
    if ! is_installed "$package"; then
        echo "$package is not installed."
        all_installed=false
    else
        echo "$package is already installed."
    fi
done

# Install packages if any are missing
if [ "$all_installed" = false ]; then
    echo "Installing missing packages..."
    sudo apt install "${packages[@]}"
else
    echo "All packages are already installed."
fi

# To prevent Nvidia modules from taking precedence on load during Ubuntu 25.04
# which results in SDDM failing, add a blacklist file for the modules so they
# only load on demand. This was an issue when testing Hyprland.
sudo tee /etc/modprobe.d/blacklist-nvidia.conf > /dev/null <<EOF
blacklist nvidia
blacklist nvidia-drm
blacklist nvidia-modeset
blacklist nvidia-uvm
EOF

# Turn off nvidia services that are causing conflicts on my system. Your mileage may vary.
sudo ln -sf /dev/null ./system/systemd-hibernate.service.requires/nvidia-hibernate.xserver-xorg-video-nvidia-570
sudo systemctl mask nvidia-hibernate.service nvidia-suspend.service sys-bus-pci-drivers-nvidia.device nvidia-resume.service nvidia-fabricmanager.service nvidia-persistenced.service nvidia-suspend-then-hibernate.service

echo "✅ NVIDIA modules installed and blacklisted for manual loading.  Use nvidia_wake.zsh to run programs on the discrete card or to turn the card off if no parameters are given."
