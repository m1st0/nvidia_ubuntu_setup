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
        echo "✓ $package is installed."
    else
        echo "✗ $package is missing."
        missing_packages+=("$package")
    fi
done

if (( ${#missing_packages[@]} > 0 )); then
    echo
    echo "Installing missing NVIDIA packages..."

    if sudo apt install -y "${missing_packages[@]}"; then
        echo
        echo "Holding NVIDIA kernel packages..."
        sudo apt-mark hold "${kernel_packages[@]}"
    else
        echo "NVIDIA package installation failed."
        exit 1
    fi
else
    echo
    echo "All NVIDIA packages are already installed."

    echo
    echo "Holding NVIDIA kernel packages..."
    sudo apt-mark hold "${kernel_packages[@]}"
fi

# Prevent NVIDIA modules from automatically loading.
# This avoids SDDM failures on some Optimus laptops under Wayland.
sudo tee /etc/modprobe.d/blacklist-nvidia.conf >/dev/null <<EOF
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

echo
echo "✓ NVIDIA ${driver_version} modules installed and configured."
echo "Use nvidia_wake.zsh to run programs on the discrete GPU."
echo "Run it without parameters to turn the discrete GPU off."
echo
echo "If changing NVIDIA driver versions in the future, review existing holds:"
echo "  apt-mark showhold | grep 'nvidia-'"
echo
echo "Remove outdated holds with:"
echo "  sudo apt-mark unhold <package-name>"
