#!/usr/bin/env zsh
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Copyright (c) 2023-2026 Maulik Mistry
#
# nvidia_wake.zsh - Simplified Nvidia card management 
# on Ubuntu 26.04+ provided drivers are installed correctly 
# from my other script.
#
# Author: Maulik Mistry
# Please share support: https://www.paypal.com/paypalme/m1st0
#                       https://venmo.com/code?user_id=3319592654995456106&created=1753283702


SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/vendor/tput_shell_colorize/tput_shell_colorize.sh"
CONF_DIR="$SCRIPT_DIR/conf.d"

# PCI Device ID of NVIDIA GPU (change if different)
export GPU_DEV="0000:01:00.0"

remove_modules() {
    if ! sudo modprobe -r --wait 5000 nvidia_drm nvidia_modeset nvidia_uvm nvidia; then
        messenger_end "Failed to unload NVIDIA modules."
        return 1
    fi
}

suspend_gpu() {
  linefeed
  messenger_std "Turning off NVIDIA GPU..."
  # Power off the GPU
  printf '%s' "auto" | sudo tee "/sys/bus/pci/devices/$GPU_DEV/power/control" > /dev/null
  linefeed
  messenger_end "PCI control result: "
  sudo cat "/sys/bus/pci/devices/$GPU_DEV/power/control"
  printf '%s' "suspend" | sudo tee /proc/driver/nvidia/suspend > /dev/null
  # If driver unloaded, this won't exist.
  #messenger_end "Driver in /proc suspension: "
  #sudo cat "/proc/driver/nvidia/suspend"

  # Optionally restart the NVIDIA services to ensure proper state
  #sudo systemctl restart nvidia-suspend.service nvidia-resume.service nvidia-powerd.service
  #sudo modprobe acpi_call
  #sudo tee /proc/acpi/call <<<'\_SB_.PCI0.PEG0.PEGP._OFF'

  remove_modules

  linefeed
  messenger_end "NVIDIA GPU is now powered off."
}

activate_gpu() {
  linefeed
  messenger_std "Turning on NVIDIA GPU..."

  # Ensure NVIDIA modules are loaded. Already in "/etc/modules" for now.
  #sudo modprobe nvidia
  #sudo modprobe nvidia_modeset
  #sudo modprobe nvidia_uvm
  # Loads above dependency modules properly rather than with manual modeset failure.
  sudo modprobe nvidia_drm modeset=1
  printf '%s' "resume" | sudo tee /proc/driver/nvidia/suspend > /dev/null

  # Power on the GPU
  printf '%s' "on" | sudo tee /sys/bus/pci/devices/$GPU_DEV/power/control > /dev/null
  sudo cat /sys/bus/pci/devices/$GPU_DEV/power/control

  # Run the specified command on NVIDIA GPU
  linefeed
  messenger_std "Running on NVIDIA GPU: ${(@)argv}"
  
  env_vars=(
    __NV_PRIME_RENDER_OFFLOAD=1
    __GLX_VENDOR_LIBRARY_NAME=nvidia
    GBM_BACKEND=nvidia-drm
    __VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/nvidia
    GDK_BACKEND=wayland
  )
  
  CONF_DIR="$SCRIPT_DIR/conf.d"

  app_name="${1:t}"
  app_conf="$CONF_DIR/${app_name}.conf"

  if [[ -f "$app_conf" ]]; then
    source "$app_conf"
  fi

  env "${env_vars[@]}" "$@" "${app_args[@]}"
}


# If no command is provided, power off the GPU
if [[ -z "$1" ]]; then
  suspend_gpu
# If a command is provided, power on the GPU and run the command
else
  activate_gpu "$@"
  # Power off the GPU once done
  suspend_gpu
fi
