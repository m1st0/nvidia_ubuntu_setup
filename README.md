# nvidia_ubuntu_setup

This project helps install proper Nvidia drivers while avoiding service conflicts on Wayland.  
It also allows you to toggle the discrete GPU on or off depending on whether a program needs it.  
The included `nvidia_wake.zsh` script dynamically loads and unloads Nvidia kernel modules to save power when the GPU is not in use.

If you find this project useful and would like to support its development, consider donating via:

- PayPal: https://www.paypal.com/paypalme/m1st0
- Venmo: https://venmo.com/code?user_id=3319592654995456106

© 2025 Maulik Mistry

This project is licensed under the Apache License 2.0. See the [LICENSE.txt](LICENSE.txt) file for details.

## Scripts

### nvidia_module_install.zsh
Purpose:
- Installs the correct Nvidia drivers for Wayland.
- Prevents service conflicts by disabling unnecessary daemons or services that may interfere with Wayland session handling.
- Optional configuration for PRIME or dynamic GPU switching.

Usage Example:
    ./nvidia_module_install.zsh

### nvidia_wake.zsh

Purpose:
- Loads Nvidia kernel modules.
- Runs a specified program directly on the discrete GPU.
- Unloads Nvidia modules after the program exits (optional, for power saving).

Usage Example:
    ./nvidia_wake.zsh glxinfo
    ./nvidia_wake.zsh blender
    ./nvidia_wake.zsh

The script detects if modules are already loaded. If not, it loads them, runs the program, and cleans up afterward. If 
ran without parameteres it attempts to conserve power by 


## Requirements

- Ubuntu or other Debian-based Linux distro.
- Zsh shell (for nvidia_wake.zsh) or modify for Bash.
- sudo privileges for driver installation and module management.

## Known Limitations

- Requires secure boot to be disabled (for kernel module signing issues).
- May require manual tweaking for hybrid-GPU laptops with unusual power management firmware.


