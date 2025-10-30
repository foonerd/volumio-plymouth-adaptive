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
   - Automatically detects rotate= parameter from /boot/cmdline.txt
   - Transforms layout for 0, 90, 180, 270 degree rotation
   - Maintains proper text orientation and centering

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

Theme reads rotation from /boot/cmdline.txt automatically.

Example cmdline.txt with rotation:

dwc_otg.lpm_enable=0 console=serial0,115200 console=tty3 
rootwait plymouth.ignore-serial-consoles quiet splash 
logo.nologo vt.global_cursor_default=0 rotate=90 
plymouth=volumio-text-90.png

Supported rotations:
- rotate=0   (default, no rotation)
- rotate=90  (portrait right)
- rotate=180 (upside down)
- rotate=270 (portrait left)

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
- Higher storage requirements
- Requires sequence generation

volumio-text (this theme):
- Text rendering only
- No animation
- Minimal storage
- No generation needed
- Fallback for constrained environments

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
Rotation Detection: /proc/cmdline parsing
Coordinate System: Transformed per rotation
Text Rendering: Plymouth Image.Text API
Z-ordering: Title/Message=10, Password=100

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
