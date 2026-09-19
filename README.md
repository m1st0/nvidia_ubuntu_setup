<!--
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: Copyright (c) 2023–2026 Maulik Mistry
-->
# nvidia_ubuntu_setup

This project installs and manages NVIDIA drivers for Ubuntu systems using Wayland.

It provides `nvidia_wake.zsh`, which loads the NVIDIA kernel modules, and launches a specified application using the discrete NVIDIA GPU.

An separate hardware-level power management `gpu_power_state.zsh` is included separate from actuall use of `nvidia_wake.zsh` .

Please share support:

* [PayPal](https://www.paypal.com/paypalme/m1st0)
* [Venmo](https://venmo.com/code?user_id=3319592654995456106&created=1753283702)

Copyright (c) 2023-2026 Maulik Mistry

This project is licensed under the Apache License 2.0. See the [LICENSE.txt](LICENSE.txt) file for details.

## Scripts

### nvidia_module_install.zsh

Installs the NVIDIA driver packages and kernel modules required by this setup.

The script also configures the system to avoid NVIDIA services and other components that can interfere with the intended Wayland configuration.

The NVIDIA driver version is defined in one place in the script and is used when selecting the NVIDIA packages and kernel modules.

Usage:

`./nvidia_module_install.zsh`

### nvidia_wake.zsh

Loads the NVIDIA kernel modules and runs a specified application using the discrete NVIDIA GPU.

Usage:

`./nvidia_wake.zsh glxinfo`

`./nvidia_wake.zsh kdenlive`

`./nvidia_wake.zsh blender`

The script:

1. Loads `nvidia_drm` with KMS enabled.
2. Powers on the NVIDIA GPU.
3. Applies the default NVIDIA Wayland/PRIME environment.
4. Loads an optional application-specific configuration from `conf.d/`.
5. Loads optional GPU-specific module parameters from `modprobe.d/`.
6. Runs the requested application.
7. Attempts to unload the NVIDIA modules after the application exits.

The default NVIDIA environment is:

* `__NV_PRIME_RENDER_OFFLOAD=1`
* `__GLX_VENDOR_LIBRARY_NAME=nvidia`
* `__VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json`
* `GBM_BACKEND=nvidia-drm`
* `GDK_BACKEND=wayland`

Application-specific settings can be added under `conf.d/`.
GPU-specific settings can be added under `modprobe.d/` and appropriate logic added to the script.

#### Module unloading

Module unloading uses kmod's native busy-module retry.

On the author's NVIDIA GTX 1060 system, `nvidia_drm` can remain busy after KMS is enabled, preventing complete module removal. 
Therefore the code has been removed. Other NVIDIA GPUs and driver configurations may unload successfully.

The NVIDIA modules can remain loaded and subsequent executions of `nvidia_wake.zsh` will continue to use the already-loaded modules.

#### GPU suspend

The previous GPU suspend path has been removed because the author's GTX 1060 experienced GPU lockups when the suspend operation was used.

The script therefore does not currently use the `/proc/driver/nvidia/suspend` interface as part of its normal application workflow.

### nvidia-kernel-common.conf

Retains the NVIDIA package version used by this setup.

This configuration is important for newer NVIDIA GPUs where later package versions can make extensive changes to Ubuntu's NVIDIA configuration 
and cause functionality to break.

### gpu_power_state.zsh

Direct hardware-level control of the NVIDIA GPU power state via ACPI calls, primarily used for aggressive power savings. Kept separate from `nvidia_wake.zsh` to isolate low-level power toggles, as improper state changes can lock the PCI bus and require a system reboot.

Usage:

`./gpu_power_state.zsh [on|off]`

## Requirements

* Ubuntu or another Debian-based Linux distribution.
* Zsh.
* Sudo privileges for driver installation and kernel module management.
* An NVIDIA GPU supported by the installed driver version.
* A Wayland session for the intended application environment.

## Known Limitations

* Hybrid-GPU laptops may require additional configuration depending on their firmware and power-management implementation.
* NVIDIA kernel modules may remain busy and prevent complete unloading on some hardware.
* GPU power-management behavior may vary between NVIDIA GPU generations and driver versions.
* Within `nvidia_module_install.zsh`, the `driver_version` may need to be updated if newer NVIDIA packages are useful.

