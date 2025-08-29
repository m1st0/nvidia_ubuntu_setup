#!/usr/bin/env zsh
# Simplified Nvidia card management on Ubuntu 25.04 provided drivers are 
# installed correctly from my other script.

# Author and Copyright (c) 2023–2025 Maulik Mistry <mistry01@gmail.com>
# If you find this project useful and would like to support its development, consider donating via
# Paypal: https://www.paypal.com/paypalme/m1st0
# Venmo: https://venmo.com/code?user_id=3319592654995456106

# License: Apache License 2.0
# All rights reserved.

# PCI Device ID of NVIDIA GPU (change if different)
GPU_DEV="0000:01:00.0"

remove_modules() {
  sudo rmmod nvidia_drm
  sudo rmmod nvidia_modeset
  sudo rmmod nvidia_uvm
  sudo rmmod nvidia
  #sudo rmmod nvidia_nvlink
}

suspend_gpu() {
  echo "Turning off NVIDIA GPU..."

  # Power off the GPU
  echo auto | sudo tee /sys/bus/pci/devices/$GPU_DEV/power/control
  sudo cat /sys/bus/pci/devices/$GPU_DEV/power/control
  echo "suspend" | sudo tee /proc/driver/nvidia/suspend

  # Optionally restart the NVIDIA services to ensure proper state
  #sudo systemctl restart nvidia-suspend.service nvidia-resume.service nvidia-powerd.service
  #sudo modprobe acpi_call
  #sudo tee /proc/acpi/call <<<'\_SB_.PCI0.PEG0.PEGP._OFF'

  # Run the Bash script in a subshell and call the function
  remove_modules
  echo "NVIDIA GPU is now powered off."
}

activate_gpu() {
  echo "Turning on NVIDIA GPU..."

  # Ensure NVIDIA modules are loaded. Already in "/etc/modules" for now.
  sudo modprobe nvidia nvidia_modeset nvidia_uvm nvidia_drm
  echo "resume" | sudo tee /proc/driver/nvidia/suspend

  # Power on the GPU
  echo on | sudo tee /sys/bus/pci/devices/$GPU_DEV/power/control
  sudo cat /sys/bus/pci/devices/$GPU_DEV/power/control

  # Run the specified command on NVIDIA GPU
  echo "Running on NVIDIA GPU: ${(@)argv}"
  GBM_BACKEND=nvidia-drm __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json "$@"
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
