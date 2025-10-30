Volumio Text Adaptive Plymouth Theme
=====================================

OVERVIEW
--------

Rotation-adaptive text-based Plymouth boot theme for Volumio.

This theme serves as a lightweight fallback when full graphical themes
cannot be displayed. It provides essential boot feedback using only
text rendering, with automatic adaptation to display rotation.

Purpose: Fallback/test theme for minimal environments
Type: Text-based (no image sequences)
Rotation: Fully adaptive (0/90/180/270 degrees)
Storage: Minimal footprint

FEATURES
--------

1. Rotation Adaptation
   - Runtime detection automatically patches rotation value at boot
   - Supports 0, 90, 180, 270 degree rotation
   - Maintains proper text orientation and centering
   - No initramfs rebuild needed for rotation changes (with runtime detection)

2. Text Display
   - "Volumio Player" title centered on screen
   - Single-line system messages from init
   - Responsive font sizing based on screen dimensions

3. Screen Size Adaptation
   - Font sizes adjust for small displays (<240px, <480px)
   - Text truncation for narrow screens
   - Layout optimization for various resolutions

4. Minimal Resource Usage
   - No pre-rendered images
   - No animation sequences
   - Pure text rendering
   - Small storage footprint

5. Runtime Detection Support (Optional)
   - Shares runtime detection system with volumio-plymouth-adaptive
   - Init-premount script patches rotation before boot
   - Systemd service patches for shutdown/reboot
   - One-time setup, zero maintenance

INSTALLATION
------------

1. Copy theme to Plymouth themes directory:

   sudo cp -r volumio-text /usr/share/plymouth/themes/

2. Set as active theme:

   sudo plymouth-set-default-theme volumio-text

3. Update initramfs:

   sudo update-initramfs -u

4. Configure rotation in /boot/cmdline.txt if needed:

   Add rotate=90, rotate=180, or rotate=270 to single line

ROTATION CONFIGURATION
----------------------

Theme uses rotate= parameter for coordinate transformation.

IMPORTANT: cmdline.txt location varies by OS:
- Volumio 3.x/4.x: /boot/cmdline.txt
- Raspberry Pi OS Bookworm: /boot/firmware/cmdline.txt

Edit cmdline.txt (must be single line, space-separated):

For Volumio (real example format):
console=serial0,115200 console=tty1 root=PARTUUID=ea7d04d6-02 rootfstype=ext4 elevator=noop rootwait splash plymouth.ignore-serial-consoles imgpart=/dev/mmcblk0p2 imgfile=/volumio_current.sqsh use_kmsg=no quiet loglevel=0 logo.nologo vt.global_cursor_default=0 rotate=270

For Raspberry Pi OS:
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootwait rotate=270

Supported rotations:
- rotate=0   (default, landscape, no rotation)
- rotate=90  (portrait right)
- rotate=180 (upside down)
- rotate=270 (portrait left)

Runtime Detection (Recommended):
With runtime detection installed, changing rotation only requires:
1. Edit rotate= value in cmdline.txt
2. Reboot
3. Done - no manual script edits or initramfs rebuilds

See volumio-plymouth-adaptive/runtime-detection/RUNTIME-DETECTION-INSTALL.md
for installation instructions.

COORDINATE TRANSFORMATION
-------------------------

Theme automatically transforms all text positions based on rotation:

- 0 degrees:   No transformation
- 90 degrees:  Coordinates swapped, Y inverted
- 180 degrees: Both coordinates inverted
- 270 degrees: Coordinates swapped, X inverted

All text remains properly centered and oriented regardless of
physical display rotation.

LAYOUT STRUCTURE
----------------

Screen layout (in logical orientation):

+----------------------------------+
|                                  |
|          Volumio Player          | (Title, centered)
|                                  |
|    Starting system services...   | (Message, centered)
|                                  |
+----------------------------------+

PASSWORD PROMPTS
----------------

Theme supports Plymouth password prompts for encrypted systems.
Prompt and input bullets displayed centered on screen.

TESTING
-------

Test theme without reboot:

1. Set theme:
   sudo plymouth-set-default-theme volumio-text

2. Preview:
   sudo plymouthd --debug --debug-file=/tmp/plymouth.log
   sudo plymouth show-splash
   
3. Test message:
   sudo plymouth message --text="Test message"

4. Quit:
   sudo plymouth quit

5. Check debug log:
   cat /tmp/plymouth.log

TROUBLESHOOTING
---------------

Theme not displaying:
- Verify Plymouth installation: dpkg -l | grep plymouth
- Check theme files exist: ls /usr/share/plymouth/themes/volumio-text
- Verify initramfs updated: check modification date of initrd.img
- Check cmdline.txt has splash parameter

Text appears rotated incorrectly:
- Verify rotate= parameter matches physical display orientation
- Check /proc/cmdline shows correct rotate value after boot
- Remember: plymouth= and rotate= are independent parameters

Text not visible:
- Check background color not conflicting with text
- Verify font packages installed
- Test with plymouth --debug mode

COMPARISON TO IMAGE THEME
--------------------------

volumio-plymouth-adaptive (image-based):
- Pre-rendered PNG sequences
- Smooth animation
- Higher storage requirements (~400MB for 4 rotations)
- Requires sequence generation
- Uses plymouth= parameter
- With runtime detection: rotation changes require reboot only

volumio-text (this theme):
- Text rendering only
- No animation
- Minimal storage (<10KB)
- No generation needed
- Uses rotate= parameter
- With runtime detection: rotation changes require reboot only
- Fallback for constrained environments

Both themes support the same runtime detection system and can be
installed simultaneously.

FONT ADAPTATION
---------------

Theme automatically adjusts font sizes:

| Screen Height | Title Font    | Message Font |
|---------------|---------------|--------------|
| >= 480px      | Sans Bold 16  | Sans 10      |
| 240-479px     | Sans Bold 12  | Sans 8       |
| < 240px       | Sans Bold 10  | Sans 6       |

CHARACTER TRUNCATION
--------------------

Messages truncated based on screen width:

| Screen Width | Max Characters |
|--------------|----------------|
| >= 640px     | 60             |
| 320-639px    | 40             |
| < 320px      | 30             |


TECHNICAL DETAILS
-----------------

Script Language: Plymouth Script
Rotation Detection: Runtime patching via init-premount script
Coordinate System: Transformed per rotation at runtime
Text Rendering: Plymouth Image.Text API
Z-ordering: Title/Message=10, Password=100

Note: Plymouth APIs for reading /proc/cmdline are broken in current versions.
Runtime detection solves this by patching the script before Plymouth loads it.

FILES
-----

volumio-text.script   - Main theme script (rotation-adaptive)
volumio-text.plymouth - Theme configuration file

COMPATIBILITY
-------------

Tested on:
- Raspberry Pi 3/4/5
- Volumio 3.x
- Plymouth 0.9.x

Display types:
- HDMI displays (all orientations)
- DSI touchscreens (all orientations)
- Composite video

LICENSE
-------

Copyright (C) 2025 Volumio Srl

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

See LICENSE file in repository root for full GPL v2 text.

SUPPORT
-------

For issues or questions:
https://github.com/foonerd/volumio-adaptive-themes/issues

Documentation:
https://github.com/foonerd/volumio-adaptive-themes
