#!/bin/bash
# Plymouth rotation detection script
# Patches installed Plymouth scripts based on kernel command line parameters
# Only volumio-adaptive theme uses the plymouth= parameter

CMDLINE=$(cat /proc/cmdline)
ROTATION=0

# Detect plymouth= parameter (for volumio-adaptive)
if echo "$CMDLINE" | grep -q "plymouth=90"; then ROTATION=90; fi
if echo "$CMDLINE" | grep -q "plymouth=180"; then ROTATION=180; fi
if echo "$CMDLINE" | grep -q "plymouth=270"; then ROTATION=270; fi

# Patch image theme (volumio-adaptive) - uses plymouth_rotation variable
ADAPTIVE_SCRIPT="/usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script"
if [ -f "$ADAPTIVE_SCRIPT" ]; then
  sed -i "s/^plymouth_rotation = [0-9]*;/plymouth_rotation = ${ROTATION};/" "$ADAPTIVE_SCRIPT"
fi
