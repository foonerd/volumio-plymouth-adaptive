# Volumio Adaptive Themes

Dynamic boot splash and UI themes for Volumio that adapt to display rotation without requiring initramfs rebuilds.

## Project Status

- **volumio-plymouth-adaptive**: Complete and tested (v1.0)
- **volumio-text-adaptive**: Planned

## Overview

This repository contains adaptive themes for Volumio systems running on Raspberry Pi with rotated displays. The themes solve a fundamental problem: changing display orientation traditionally requires rebuilding the initramfs, a time-consuming process. These adaptive themes read rotation parameters from the kernel command line and dynamically select pre-rotated assets, making display changes as simple as editing a configuration file and rebooting.

## Components

### volumio-plymouth-adaptive

A Plymouth boot splash theme that dynamically adapts to display rotation.

**Problem Solved**: Plymouth boot splash fails on rotated Raspberry Pi displays because kernel rotation affects the console but not Plymouth's framebuffer access. Traditional solutions require rebuilding initramfs for each display change.

**Solution**: Pre-rotates images for all orientations (0, 90, 180, 270 degrees) and dynamically loads the correct set based on the `plymouth=` kernel parameter.

**Features**:
- Dynamic rotation detection from kernel command line
- Pre-rotated image sequences for all orientations
- No initramfs rebuild required for display changes
- Preserves all volumio-player theme features
- Debug overlay with rotation information
- Supports both micro (6 frame) and progress (90 frame) sequences

**Status**: Complete, tested on Raspberry Pi 5 with Waveshare 11.9" LCD

See [volumio-plymouth-adaptive/README.md](volumio-plymouth-adaptive/README.md) for details.

### volumio-text-adaptive

Adaptive text-based UI theme for Volumio.

**Status**: Planned, awaiting specifications

## Volumio Configuration Hierarchy

Volumio uses a specific configuration file hierarchy. Understanding this is critical for proper installation:

1. `/boot/cmdline.txt` - Kernel command line parameters
   - `plymouth=` parameter goes here
   
2. `/boot/config.txt` - Build process managed (DO NOT MODIFY)
   - System managed, changes may be overwritten
   
3. `/boot/volumioconfig.txt` - Volumio player defaults (DO NOT MODIFY)
   - System managed defaults
   
4. `/boot/userconfig.txt` - User configuration (MODIFY THIS)
   - `rotate=` and `video=` parameters go here
   - User changes are preserved across updates

**Example Configuration**:

`/boot/userconfig.txt`:
```
video=HDMI-A-1:320x1480M@60,rotate=270
```

`/boot/cmdline.txt`:
```
console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 fsck.repair=yes rootwait plymouth=90 quiet splash
```

## Installation

See individual theme directories for installation instructions:
- [volumio-plymouth-adaptive/INSTALLATION.md](volumio-plymouth-adaptive/INSTALLATION.md)

## Requirements

- Raspberry Pi (tested on Pi 5)
- Raspberry Pi OS Bookworm or compatible
- Plymouth boot splash system
- Volumio installed

## License

GPL v2 - See [LICENSE](LICENSE)

## Contributing

Contributions welcome. Please see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

## Authors

See [AUTHORS](AUTHORS)

## Change Log

### Version 1.0 (October 30, 2025)
- Initial release
- volumio-plymouth-adaptive complete
- Dynamic rotation detection from kernel command line
- Pre-rotated image support for 0, 90, 180, 270 degrees
- Complete documentation suite
- Installation and quick reference guides

### Future Updates
- This section will track additions and changes
- volumio-text-adaptive development
- Additional features and improvements
- Bug fixes and optimizations
