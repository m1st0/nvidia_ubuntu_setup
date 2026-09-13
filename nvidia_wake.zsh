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

activate_gpu() {
  linefeed
  messenger_std "Turning on NVIDIA GPU..."

  # Ensure NVIDIA modules are loaded. Already in "/etc/modules" for now.
  # Loads all dependency modules properly, so we don't need to manually load each nvidia module due to
  # funtional modeset=1.
  sudo modprobe nvidia_drm modeset=1
  printf '%s' "resume" | sudo tee /proc/driver/nvidia/suspend > /dev/null

  # Power on the GPU
  printf '%s' "on" | sudo tee /sys/bus/pci/devices/$GPU_DEV/power/control > /dev/null
  sudo cat /sys/bus/pci/devices/$GPU_DEV/power/control

  # Run the specified command on NVIDIA GPU
  linefeed
  messenger_std "Running on NVIDIA GPU: ${(@)argv}"
 
  # Default
  env_vars=(
    __NV_PRIME_RENDER_OFFLOAD=1
    __GLX_VENDOR_LIBRARY_NAME=nvidia
    __VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
    GBM_BACKEND=nvidia-drm
    GDK_BACKEND=wayland 
  )
  
  app_name="${1:t}"
  app_conf="$CONF_DIR/${app_name}.conf"
  app_args=()

  if [[ -f "$app_conf" ]]; then
    source "$app_conf"
  fi

  env "${env_vars[@]}" "$app_name" "${app_args[@]}"
}

activate_gpu "$@"

