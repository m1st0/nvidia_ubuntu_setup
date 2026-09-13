<!--
SPDX-FileCopyrightText: Copyright (c) 2023–2026 Maulik Mistry
SPDX-License-Identifier: Apache-2.0
-->
# nvidia_ubuntu_setup

This project helps install proper Nvidia drivers while avoiding service conflicts on Wayland.  
It also allows you to toggle the discrete GPU on or off depending on whether a program needs it.  
The included `nvidia_wake.zsh` script dynamically loads and unloads Nvidia kernel modules to save power when the GPU is not in use.

Please share support: 
- [PayPal](https://www.paypal.com/paypalme/m1st0)
- [Venmo](https://venmo.com/code?user_id=3319592654995456106&created=1753283702)


Copyright (c) 2023-2026 Maulik Mistry

This project is licensed under the Apache License 2.0. See the [LICENSE.txt](LICENSE.txt) file for details.

## Scripts

### nvidia_module_install.zsh

Purpose:
- Installs the correct Nvidia drivers for Wayland.
- Prevents service conflicts by disabling unnecessary daemons or services that may interfere with Wayland session handling.
- Optional configuration for PRIME or dynamic GPU switching.

Usage:
- `./nvidia_module_install.zsh`

### nvidia_wake.zsh

Purpose:
- Loads Nvidia kernel modules.
- Runs a specified program directly on the discrete GPU.
- Unloads Nvidia modules after the program exits (optional, for power saving).

Usage Example:
- `./nvidia_wake.zsh glxinfo`
- `./nvidia_wake.zsh kdenlive`
- `./nvidia_wake.zsh blender`
- `./nvidia_wake.zsh` turns off Nvidia card (hopefully with your hardware)

The script detects if modules are already loaded. If not, it loads them, runs the program, and cleans up afterward.

**NOTE:**
Module unloading uses kmod's native busy-module retry. On the author's GTX 1060 system, nvidia_drm remains busy 
after KMS is enabled, so complete module removal still fails. Other NVIDIA GPUs and driver configurations may unload 
successfully. If unloading fails on your system, comment out the `remove_modules` call after a reboot.

### nvidia-kernel-common.conf

Retains version of Nvidia package installation for my system since later versions extensively modify Ubuntu breaking 
functionality.

## Requirements

- Ubuntu or other Debian-based Linux distro.
- Zsh shell for scripts or modify for Bash.
- sudo privileges for driver installation and module management.

## Known Limitations

- May require manual tweaking for hybrid-GPU laptops with unusual power management firmware.
- May require nvidia-kernel-common.conf to be updated for newer Nvidia packages.

