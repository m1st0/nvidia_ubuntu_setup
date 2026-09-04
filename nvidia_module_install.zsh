#!/usr/bin/env zsh
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2023-2026 Maulik Mistry
#
# Install NVIDIA kernel modules and configure Wayland compatibility on Ubuntu.
#
# If you find this project useful and would like to support its development:
# PayPal: https://www.paypal.com/paypalme/m1st0
# Venmo: https://venmo.com/code?user_id=3319592654995456106


SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/vendor/tput_shell_colorize/tput_shell_colorize.sh"

# NVIDIA driver version.
# Update this value when intentionally moving driver generations.
#
# If upgrading this value (for example 580 -> 585), previous apt-mark holds
# will remain on the old NVIDIA package names. Check existing holds with:
#
#     apt-mark showhold | grep 'nvidia-'
#
# Remove old holds before migrating if needed:
#
#     sudo apt-mark unhold <package-name>
driver_version=580

# Build NVIDIA kernel package list for every installed kernel.
# This allows a kernel upgrade to require only one reboot.
packages=()
kernel_packages=()

for kernel in /lib/modules/*; do
    kernel=${kernel##*/}

    kernel_packages+=(
        "linux-modules-nvidia-${driver_version}-${kernel}"
        "linux-objects-nvidia-${driver_version}-${kernel}"
        "linux-signatures-nvidia-${kernel}"
    )
done

packages+=("${kernel_packages[@]}")

packages+=(
    "nvidia-utils-${driver_version}"
    "libnvidia-gl-${driver_version}"
)

is_installed() {
    dpkg-query -W -f='${Status}\n' "$1" 2>/dev/null | \
        grep -q '^install ok installed$'
}

missing_packages=()

for package in "${packages[@]}"; do
    if is_installed "$package"; then
        messenger_std "✓ $package is installed."
    else
        messenger_end "✗ $package is missing."
        missing_packages+=("$package")
    fi
done

if (( ${#missing_packages[@]} > 0 )); then
    linefeed
    messenger_std "Installing missing NVIDIA packages..."

    if sudo apt install -y "${missing_packages[@]}"; then
        linefeed
        messenger_std "Holding NVIDIA kernel packages..."
        sudo apt-mark hold "${kernel_packages[@]}"
    else
        messenger_end "NVIDIA package installation failed."
        exit 1
    fi
else
    linefeed
    messenger_end "All NVIDIA packages are already installed."

    linefeed
    messenger_std "Holding NVIDIA kernel packages..."
    sudo apt-mark hold "${kernel_packages[@]}"
fi

# Prevent NVIDIA modules from automatically loading.
# This avoids SDDM failures on some Optimus laptops under Wayland.
sudo tee /etc/modprobe.d/blacklist-nvidia.conf > /dev/null << 'EOF'
blacklist nvidia
blacklist nvidia-drm
blacklist nvidia-modeset
blacklist nvidia-uvm
EOF

# Disable NVIDIA services that interfere with manual Optimus activation.
sudo ln -sf /dev/null \
    /etc/systemd/system/systemd-hibernate.service.requires/nvidia-hibernate.service

sudo systemctl mask \
    nvidia-hibernate.service \
    nvidia-suspend.service \
    sys-bus-pci-drivers-nvidia.device \
    nvidia-resume.service \
    nvidia-fabricmanager.service \
    nvidia-persistenced.service \
    nvidia-suspend-then-hibernate.service

sudo systemctl daemon-reload

linefeed
messenger_std "✓ NVIDIA ${driver_version} modules installed and configured.
Use nvidia_wake.zsh to run programs on the discrete GPU.
Run it without parameters to turn the discrete GPU off."
linefeed
messenger_std "If changing NVIDIA driver versions in the future, review existing holds:
  apt-mark showhold | grep 'nvidia-'"
linefeed
messenger_std "Remove outdated holds with:
  sudo apt-mark unhold <package-name>"
