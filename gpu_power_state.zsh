#!/usr/bin/env zsh
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Copyright (c) 2026 Maulik Mistry
#
# nvidia_acpi_calls.zsh - ACPI power control of Nvidia card.
#
# Author: Maulik Mistry
# Please share support: https://www.paypal.com/paypalme/m1st0
#                       https://venmo.com/code?user_id=3319592654995456106&created=1753283702


SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/vendor/tput_shell_colorize/tput_shell_colorize.sh"

gpu_state() {
  local input="$1"
  local state
  local acpi_cmd
  local msg_verb

  # Convert input to lowercase for case-insensitive matching
  state="${input:l}"

  # 1. Validate CLI argument
  case "$state" in
    on)
      acpi_cmd="\_SB_.PCI0.PEG0.PEGP._ON"
      msg_verb="on"
      ;;
    off)
      acpi_cmd="\_SB_.PCI0.PEG0.PEGP._OFF"
      msg_verb="off"
      ;;
    *)
      messenger_std "Error: Unrecognized command '$input'."
      messenger_std "Usage: $0 [on|off]"
      return 1
      ;;
  esac

  linefeed
  messenger_std "Turning $msg_verb NVIDIA GPU..."

  # 2. Ensure acpi_call kernel module is loaded
  if ! sudo modprobe acpi_call 2>/dev/null; then
    messenger_std "Error: Failed to load 'acpi_call' kernel module."
    return 1
  fi

  # 3. Ensure ACPI interface exists
  if [[ ! -w /proc/acpi/call ]]; then
    messenger_std "Error: /proc/acpi/call is not writable or does not exist."
    return 1
  fi

  # 4. Write ACPI command
  if ! sudo tee /proc/acpi/call <<< "$acpi_cmd" >/dev/null; then
    messenger_std "Error: Failed to write to /proc/acpi/call."
    return 1
  fi

  messenger_end "Nvidia GPU powered $msg_verb."
}

gpu_state "$@"
