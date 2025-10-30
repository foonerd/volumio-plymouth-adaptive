#!/bin/bash
# Plymouth rotation detection script
# Patches installed Plymouth scripts based on kernel command line parameters
# Supports both image theme (plymouth=) and text theme (rotate=)

CMDLINE=$(cat /proc/cmdline)
PLYMOUTH_ROTATION=0
TEXT_ROTATION=0

# Detect plymouth= parameter (for image theme)
if echo "$CMDLINE" | grep -q "plymouth=90"; then PLYMOUTH_ROTATION=90; fi
if echo "$CMDLINE" | grep -q "plymouth=180"; then PLYMOUTH_ROTATION=180; fi
if echo "$CMDLINE" | grep -q "plymouth=270"; then PLYMOUTH_ROTATION=270; fi

# Detect rotate= parameter (for text theme)
if echo "$CMDLINE" | grep -q "rotate=90"; then TEXT_ROTATION=90; fi
if echo "$CMDLINE" | grep -q "rotate=180"; then TEXT_ROTATION=180; fi
if echo "$CMDLINE" | grep -q "rotate=270"; then TEXT_ROTATION=270; fi

# Patch image theme (volumio-adaptive) - uses plymouth_rotation variable
ADAPTIVE_SCRIPT="/usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script"
if [ -f "$ADAPTIVE_SCRIPT" ]; then
  sed -i "s/^plymouth_rotation = [0-9]*;/plymouth_rotation = ${PLYMOUTH_ROTATION};/" "$ADAPTIVE_SCRIPT"
fi

# Patch text theme (volumio-text) - uses global.rotation variable
TEXT_SCRIPT="/usr/share/plymouth/themes/volumio-text/volumio-text.script"
if [ -f "$TEXT_SCRIPT" ]; then
  sed -i "s/^global\.rotation = [0-9]*;/global.rotation = ${TEXT_ROTATION};/" "$TEXT_SCRIPT"
fi

