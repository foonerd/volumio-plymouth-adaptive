# Volumio-Adaptive Plymouth Theme

Universal boot splash theme with adaptive rotation support for Volumio

## Overview

Volumio-adaptive is a Plymouth boot splash theme that solves the display rotation problem for Raspberry Pi systems with rotated displays. Unlike traditional Plymouth themes that require initramfs rebuilds when changing displays, volumio-adaptive reads a `plymouth=` parameter from the kernel command line and dynamically loads pre-rotated images.

**This is the volumio-adaptive theme** which uses pre-rotated image sequences and the `plymouth=` parameter. For the companion volumio-text theme (which uses dynamic text rendering with framebuffer rotation), see the volumio-text-adaptive documentation.

## Dual-Theme System

This repository provides two complementary themes with different rotation approaches:

### volumio-adaptive (This Theme)
- **Rotation method**: Pre-rotated image sequences
- **Parameter**: plymouth=0 or 90 or 180 or 270
- **Content**: Static images (Volumio logo animation)
- **Runtime detection**: Supported (recommended)
- **Parameter location**: /boot/cmdline.txt

### volumio-text (Companion Theme)
- **Rotation method**: Framebuffer rotation
- **Parameter**: video=...,rotate=N or fbcon=rotate:N
- **Content**: Dynamic text rendering
- **Runtime detection**: Not applicable
- **Parameter location**: /boot/cmdline.txt

**CRITICAL**: The plymouth= parameter only works with volumio-adaptive theme. For volumio-text, use video=...,rotate= or fbcon=rotate: parameters instead.

## Key Features

### volumio-adaptive specific features:
- ONE theme works across ALL display orientations
- NO initramfs rebuild needed when changing displays (with runtime detection)
- Supports 0, 90, 180, and 270 degree rotations
- Runtime detection automatically patches rotation value at boot
- Automatic micro/progress sequence selection based on screen size
- Preserves all volumio-player features (messages, debug overlay)
- Self-contained and portable
- Pre-rotated image sequences for each rotation
- plymouth= parameter for rotation control

## Runtime Detection (Recommended)

**NOTE**: Runtime detection patches only the volumio-adaptive theme. It does not apply to volumio-text theme, which uses system-level framebuffer rotation.

The theme includes an optional runtime detection system that eliminates the need for initramfs rebuilds when changing display rotation:

- **Init-premount script** patches the theme script before Plymouth loads at boot
- **Systemd service** patches the installed theme for shutdown/reboot
- **One-time setup** required during initial installation
- **Zero maintenance** after setup - rotation changes only require editing cmdline.txt and rebooting

With runtime detection installed:
1. Edit rotation in /boot/cmdline.txt (update plymouth= parameter)
2. Reboot
3. Done - no theme reinstall or initramfs rebuild

See `runtime-detection/RUNTIME-DETECTION-INSTALL.md` for installation instructions.

Without runtime detection, the theme still works but requires manually editing the script and rebuilding initramfs for each rotation change.

## The Problem It Solves

Standard Plymouth themes fail on Raspberry Pi with rotated displays because:
1. Kernel rotation (rotate=270) affects console but NOT Plymouth
2. Plymouth sees raw framebuffer dimensions
3. Fixed-orientation images display incorrectly
4. Each display change requires new theme + initramfs rebuild

**Solution (volumio-adaptive)**: Pre-rotate images for all orientations, let script select at runtime using plymouth= parameter.

**Alternative Solution (volumio-text)**: Use framebuffer rotation to rotate the entire display before Plymouth renders, eliminating the need for pre-rotated content.

## Package Contents

- `volumio-adaptive.script` - Main Plymouth script with rotation support
- `volumio-adaptive.plymouth` - Theme configuration file
- `generate-rotated-sequences.sh` - Image generation script
- `runtime-detection/` - Optional runtime detection scripts (recommended)
  - `00-plymouth-rotation` - Init-premount script for boot phase
  - `plymouth-rotation.sh` - Systemd script for shutdown phase
  - `plymouth-rotation.service` - Systemd service unit
  - `RUNTIME-DETECTION-INSTALL.md` - Installation guide
- `INSTALLATION.md` - Detailed installation instructions
- `QUICK_REFERENCE.md` - Quick command reference
- `README.md` - This file

## Quick Start

### 1. Install ImageMagick (if not present)

```bash
sudo apt-get install imagemagick
```

### 2. Create theme directory

```bash
sudo mkdir -p /usr/share/plymouth/themes/volumio-adaptive
sudo chown volumio:volumio /usr/share/plymouth/themes/volumio-adaptive
```

### 3. Copy theme files

```bash
sudo cp volumio-adaptive.script /usr/share/plymouth/themes/volumio-adaptive/
sudo cp volumio-adaptive.plymouth /usr/share/plymouth/themes/volumio-adaptive/
```

### 4. Generate rotated images

```bash
chmod +x generate-rotated-sequences.sh
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
```

### 5. Install theme

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

### 6. Configure display rotation

Volumio uses a specific configuration hierarchy. Edit cmdline.txt:

**Edit `/boot/cmdline.txt`** (single line, add parameters):

Add to the existing line (space-separated):
```
video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

Example complete line:
```
splash plymouth.ignore-serial-consoles ... quiet ... nodebug use_kmsg=no video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

**Important**: The plymouth= parameter is specific to volumio-adaptive theme. If using volumio-text theme instead, omit plymouth= and rely on video=...,rotate= or fbcon=rotate: for rotation.

### 7. Reboot

```bash
sudo reboot
```

## Volumio Configuration Hierarchy

Volumio uses multiple configuration files with different purposes:

- **`/boot/config.txt`** - DO NOT MODIFY (build process managed)
- **`/boot/volumioconfig.txt`** - DO NOT MODIFY (Volumio defaults)
- **`/boot/userconfig.txt`** - USER EDITABLE (hardware config: dtoverlay, hdmi_group, hdmi_mode)
- **`/boot/cmdline.txt`** - USER EDITABLE (kernel parameters: video=, rotate=, plymouth=, fbcon=)

**Important**: Display rotation (`video=`, `rotate=`) and Plymouth parameters (`plymouth=`) go in `/boot/cmdline.txt` as a single line with space-separated parameters.

## Rotation Values

Use these `plymouth=` values based on your kernel `rotate=` setting:

| Kernel rotate= | plymouth= | Display Orientation |
|----------------|-----------|---------------------|
| (none)         | 0         | Landscape (default) |
| rotate=90      | 270       | Portrait (270 CW)   |
| rotate=180     | 180       | Upside-down         |
| rotate=270     | 90        | Portrait (90 CW)    |

**Formula**: `plymouth_rotation = (360 - kernel_rotation) % 360`

**Note**: This formula applies only to volumio-adaptive theme. volumio-text theme uses framebuffer rotation and does not need the plymouth= parameter.

## Parameter Usage By Theme

| Theme | Required Parameter | Purpose |
|-------|-------------------|---------|
| volumio-adaptive | plymouth=0 or 90 or 180 or 270 | Select pre-rotated image sequence |
| volumio-text | video=...,rotate=N | Rotate framebuffer for text |
| volumio-text | fbcon=rotate:N | Rotate framebuffer for text (alternative) |

**Do not mix parameters**: plymouth= only works with volumio-adaptive. video=...,rotate= and fbcon=rotate: are used by volumio-text.

## Changing Displays

When you change to a display with different rotation:

**With runtime detection installed** (recommended):
1. Edit `/boot/cmdline.txt`
2. Update `video=`, `rotate=`, and `plymouth=` parameters on the existing line
3. Reboot

**NO theme reinstall or initramfs rebuild needed!**

**Without runtime detection**:
1. Edit `/boot/cmdline.txt` (update parameters)
2. Edit `/usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script` (change plymouth_rotation value)
3. Rebuild initramfs: `sudo update-initramfs -u`
4. Reboot

Example: Change from landscape to portrait:
```
video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

## Directory Structure

After installation, the theme directory contains:

```
/usr/share/plymouth/themes/volumio-adaptive/
  volumio-adaptive.script        - Main script
  volumio-adaptive.plymouth      - Configuration
  sequence0/                     - 0 degree images (480x270 landscape)
    progress-1.png through progress-90.png
    micro-1.png through micro-6.png
    layout-constraint.png
  sequence90/                    - 90 degree CW images (270x480 portrait)
    (same file names, rotated 90 degrees)
  sequence180/                   - 180 degree images (480x270 upside-down)
    (same file names, rotated 180 degrees)
  sequence270/                   - 270 degree CW images (270x480 portrait)
    (same file names, rotated 270 degrees)
```

Each sequence directory contains 97 image files.

**Note**: volumio-text theme does not use image sequences - it generates text dynamically.

## Technical Details

### How It Works

**With runtime detection** (recommended):
1. Init-premount script reads plymouth= from /proc/cmdline before Plymouth loads
2. Script patches plymouth_rotation value in volumio-adaptive.script
3. Plymouth loads pre-patched script with correct rotation
4. Script builds image path: `sequenceXX/`
5. All Image() calls load from selected directory
6. For portrait modes (90, 270), dimensions are swapped for sequence logic
7. Micro sequence activates when (width <= 640) && (height <= 640)

**Without runtime detection**:
1. Theme script has hardcoded plymouth_rotation value
2. Must manually edit and rebuild initramfs for each rotation change
3. Rest of process same as above

**Runtime detection scope**: Only applies to volumio-adaptive theme. volumio-text uses framebuffer rotation which is handled by the kernel, not the theme script.

See `docs/TECHNICAL.md` for detailed information on Plymouth API limitations and runtime detection implementation.

### Performance

- All images loaded once during initialization
- No runtime overhead for rotation logic
- Memory usage: ~800KB for progress, ~50KB for micro sequence

### Compatibility

- Tested on Raspberry Pi OS Bookworm
- Works with all Raspberry Pi models
- Compatible with VC4 KMS driver
- No modifications needed for different displays

## Testing

### Quick test without reboot

```bash
sudo plymouthd --debug
sudo plymouth show-splash
# Wait 10 seconds
sudo plymouth quit
```

### Full boot test

```bash
sudo reboot
```

### Debug mode (shows dimensions and rotation)

1. Edit `/usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script`
2. Line ~100: `enable_debug_overlay = (Window.GetWidth() > -1);`
3. Rebuild: `sudo plymouth-set-default-theme -R volumio-adaptive`
4. Reboot

## Troubleshooting

### Plymouth not showing

- Check theme: `sudo plymouth-set-default-theme`
- Check cmdline has "quiet splash"
- Check services: `systemctl status plymouth-start.service`

### Wrong orientation

- Verify active theme matches parameter type
- For volumio-adaptive: verify `plymouth=` matches your display
- For volumio-text: verify `video=...,rotate=` or `fbcon=rotate:` configured
- Use formula: `plymouth = (360 - rotate) % 360` (volumio-adaptive only)
- Try different values: 0, 90, 180, 270

### Parameter not working

- Verify active theme: `sudo plymouth-set-default-theme`
- If using volumio-text, plymouth= parameter has no effect - use video=...,rotate= or fbcon=rotate: instead
- If using volumio-adaptive without plymouth= parameter, images won't rotate - add plymouth= parameter

### Missing images

- Verify generation completed: `ls /usr/share/plymouth/themes/volumio-adaptive/sequence*/`
- Each directory should have 97 files
- Re-run `generate-rotated-sequences.sh` if needed

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed troubleshooting including theme-specific issues.

## Maintenance

### Updating Volumio logo

1. Update source images in `volumio-player/sequence/`
2. Re-run `generate-rotated-sequences.sh`
3. Rebuild: `sudo plymouth-set-default-theme -R volumio-adaptive`
4. Reboot

### Reverting to original theme

```bash
sudo plymouth-set-default-theme -R volumio-player
```

### Switching between themes

To switch to volumio-text:
```bash
sudo plymouth-set-default-theme -R volumio-text
# Edit cmdline.txt: remove plymouth=, ensure video=...,rotate= or fbcon=rotate: present
sudo reboot
```

To switch back to volumio-adaptive:
```bash
sudo plymouth-set-default-theme -R volumio-adaptive
# Edit cmdline.txt: add plymouth= parameter
sudo reboot
```

## Requirements

- Raspberry Pi OS Bookworm or later
- Plymouth (pre-installed)
- ImageMagick (for image generation)
- Source images from volumio-player theme
- Root access

## Limitations

- Supports four fixed rotations (0, 90, 180, 270)
- Requires one-time initramfs rebuild for initial theme installation
- With runtime detection: rotation changes only require reboot (no rebuild)
- Without runtime detection: each rotation change requires manual script edit and initramfs rebuild
- Image generation requires disk space (4x source images)
- Custom rotations require manual image creation
- plymouth= parameter only applies to volumio-adaptive theme
- Runtime detection only patches volumio-adaptive theme

## Credits

- Original volumio-player theme: Andrew Seredyn, Volumio Srl
- Adaptive rotation support: Nerd
- Based on Plymouth script engine by Freedesktop.org

## License

GNU General Public License v2 or later

Copyright (C) 2025 Volumio Srl

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2, or (at your option) any later version.

## Support

For issues or questions:
1. Check [INSTALLATION.md](INSTALLATION.md) for detailed steps
2. Review [runtime-detection/RUNTIME-DETECTION-INSTALL.md](runtime-detection/RUNTIME-DETECTION-INSTALL.md) for runtime detection setup
3. Review [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for commands
4. Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues
5. Enable debug overlay to diagnose issues
6. Verify correct theme is active for your parameter type
7. Report to Volumio development team with debug log

## Project Status

- **Status**: Production ready
- **Version**: 1.0
- **Last updated**: October 2025
- **Tested on**: Raspberry Pi 5, Raspberry Pi OS Bookworm
- **Dual-theme system**: volumio-adaptive + volumio-text

## Future Enhancements

Potential improvements:
- Support for arbitrary rotation angles
- Integration with Volumio settings UI
- Automatic image generation during theme installation
- Unified configuration interface for both themes
- Auto-detection of optimal theme for display type

## Additional Resources

- [Plymouth documentation](https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/)
- [Raspberry Pi display configuration](https://www.raspberrypi.com/documentation/computers/configuration.html)
- [Volumio project](https://volumio.com/)

## Acknowledgments

Thanks to:
- Raspberry Pi Foundation for excellent hardware
- Freedesktop.org for Plymouth
- Volumio team for the audio distribution
- Community members for testing and feedback
- Contributors to both volumio-adaptive and volumio-text themes
