# Volumio-Adaptive Plymouth Theme

Universal boot splash theme with adaptive rotation support for Volumio

## Overview

Volumio-adaptive is a Plymouth boot splash theme that solves the display rotation problem for Raspberry Pi systems with rotated displays. Unlike traditional Plymouth themes that require initramfs rebuilds when changing displays, volumio-adaptive reads a `plymouth=` parameter from the kernel command line and dynamically loads pre-rotated images.

## Key Features

- ONE theme works across ALL display orientations
- NO initramfs rebuild needed when changing displays
- Supports 0, 90, 180, and 270 degree rotations
- Automatic micro/progress sequence selection based on screen size
- Preserves all volumio-player features (messages, debug overlay)
- Self-contained and portable

## The Problem It Solves

Standard Plymouth themes fail on Raspberry Pi with rotated displays because:
1. Kernel rotation (rotate=270) affects console but NOT Plymouth
2. Plymouth sees raw framebuffer dimensions
3. Fixed-orientation images display incorrectly
4. Each display change requires new theme + initramfs rebuild

**Solution**: Pre-rotate images for all orientations, let script select at runtime.

## Package Contents

- `volumio-adaptive.script` - Main Plymouth script with rotation parsing
- `volumio-adaptive.plymouth` - Theme configuration file
- `generate-rotated-sequences.sh` - Image generation script
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

## Changing Displays

When you change to a display with different rotation:

1. Edit `/boot/cmdline.txt`
2. Update `video=`, `rotate=`, and `plymouth=` parameters on the existing line
3. Reboot

**NO theme reinstall or initramfs rebuild needed!**

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

## Technical Details

### How It Works

1. Plymouth script parses `plymouth=XX` from kernel command line
2. Script builds image path: `sequenceXX/`
3. All Image() calls load from selected directory
4. For portrait modes (90, 270), dimensions are swapped for sequence logic
5. Micro sequence activates when (width <= 640) && (height <= 640)

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

- Verify `plymouth=` matches your display
- Use formula: `plymouth = (360 - rotate) % 360`
- Try different values: 0, 90, 180, 270

### Missing images

- Verify generation completed: `ls /usr/share/plymouth/themes/volumio-adaptive/sequence*/`
- Each directory should have 97 files
- Re-run `generate-rotated-sequences.sh` if needed

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed troubleshooting.

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

## Requirements

- Raspberry Pi OS Bookworm or later
- Plymouth (pre-installed)
- ImageMagick (for image generation)
- Source images from volumio-player theme
- Root access

## Limitations

- Supports four fixed rotations (0, 90, 180, 270)
- Requires initramfs rebuild only for theme installation
- Image generation requires disk space (4x source images)
- Custom rotations require manual image creation

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
2. Review [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for commands
3. Enable debug overlay to diagnose issues
4. Report to Volumio development team with debug log

## Project Status

- **Status**: Production ready
- **Version**: 1.0
- **Last updated**: October 2025
- **Tested on**: Raspberry Pi 5, Raspberry Pi OS Bookworm

## Future Enhancements

Potential improvements:
- Auto-detection of rotation from `rotate=` parameter
- Support for arbitrary rotation angles
- Integration with Volumio settings UI
- Automatic image generation during theme installation

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
