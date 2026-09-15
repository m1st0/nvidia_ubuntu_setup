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
MODPROBE_DIR="$SCRIPT_DIR/modprobe.d"

# PCI Device ID of NVIDIA GPU (change if different)
export GPU_DEV="0000:01:00.0"

remove_modules() {
  # Making sure the card is not suspended to prevent the held DRM busy state.
  if [[ -e /proc/driver/nvidia/suspend ]]; then
    printf '%s' "resume" | sudo tee /proc/driver/nvidia/suspend > /dev/null
  fi

  if ! sudo modprobe -r --wait 3000 nvidia_drm; then
      messenger_end "Failed to unload nvidia_drm."
      return 1
  fi

  if ! sudo modprobe -r --wait 3000 nvidia_modeset; then
      messenger_end "Failed to unload nvidia_modeset."
      return 1
  fi

  if ! sudo modprobe -r --wait 3000 nvidia_uvm; then
      messenger_end "Failed to unload nvidia_uvm."
      return 1
  fi

  if ! sudo modprobe -r --wait 3000 nvidia; then
      messenger_end "Failed to unload nvidia."
      return 1
  fi

  return 0
}

deactivate_gpu() {
  linefeed
  messenger_std "Turning off NVIDIA GPU..."
  # Manage power state itself.
  printf '%s' "auto" | sudo tee "/sys/bus/pci/devices/$GPU_DEV/power/control" > /dev/null
  linefeed
  power_control="$(sudo cat "/sys/bus/pci/devices/$GPU_DEV/power/control")"
  messenger_end "PCI control result: $power_control ."
  
  # If driver unloaded, this won't exist.
  #messenger_end "Driver in /proc suspension: "
  #sudo cat "/proc/driver/nvidia/suspend"

  # Optionally restart the NVIDIA services to ensure proper state
  #sudo systemctl restart nvidia-suspend.service nvidia-resume.service nvidia-powerd.service
  #sudo modprobe acpi_call
  #sudo tee /proc/acpi/call <<<'\_SB_.PCI0.PEG0.PEGP._OFF'

  remove_modules || return 1
    
  linefeed
  messenger_end "Nvidia GPU powered off."
}

activate_gpu() {
  linefeed
  messenger_std "Turning on NVIDIA GPU..."

  gpu_id="$(lspci -n -s "$GPU_DEV" | awk '{print $3}')"
  
  if [[ "$gpu_id" == "10de:1c20" ]]; then
    # Load base driver with GSP firmware disabled (prevents XiD lockup) for
    # GeForce GTX 1060 Mobile. Config includes `modeset=1 fbdev=1`.
    modprobe_conf="$MODPROBE_DIR/nvidia_gtx_1060_mobile.conf"
    sudo modprobe -C "$modprobe_conf" nvidia_drm
  else
    # Wayland needs NVIDIA's DRM/KMS support for the GPU to participate properly in the 
    # graphics stack, therefore modeset and fbdev for framebuffer coordination.
    sudo modprobe nvidia_drm modeset=1 fbdev=1
  fi

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

if [[ -z "$1" ]]; then
  # If no command is provided, deactivate the GPU.
  deactivate_gpu
else
  activate_gpu "$@"
fi

