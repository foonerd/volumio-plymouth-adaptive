# Volumio Adaptive Themes

Dynamic boot splash and UI themes for Volumio that adapt to display rotation without requiring initramfs rebuilds.

## Project Status

- **volumio-plymouth-adaptive**: Complete and tested (v1.02)
- **volumio-text-adaptive**: Complete and tested (v1.0)

## Overview

This repository contains adaptive themes for Volumio systems running on Raspberry Pi with rotated displays. The themes solve a fundamental problem: changing display orientation traditionally requires rebuilding the initramfs, a time-consuming process. These adaptive themes read rotation parameters from the kernel command line and dynamically select pre-rotated assets, making display changes as simple as editing a configuration file and rebooting.

## Components

### volumio-plymouth-adaptive

A Plymouth boot splash theme that dynamically adapts to display rotation with transparent message overlays.

**Problem Solved**: Plymouth boot splash fails on rotated Raspberry Pi displays because kernel rotation affects the console but not Plymouth's framebuffer access. Traditional solutions require rebuilding initramfs for each display change. Additionally, Plymouth's dynamic text rendering produces severe clipping artifacts when rotated, making boot messages unreadable.

**Solution**: Pre-rotates images for all orientations (0, 90, 180, 270 degrees) and dynamically loads the correct set based on the `plymouth=` kernel parameter. Boot messages use pre-rendered transparent PNG overlays with pattern matching for reliable display at all rotations.

**Features**:
- Runtime rotation detection (no initramfs rebuild required)
- Pre-rotated image sequences for all orientations
- Transparent message overlay system (13 Volumio boot messages)
- Pattern matching with OEM compatibility (handles version variables)
- Adaptive sizing based on display dimensions (400px breakpoint)
- Z-index layering (logo visible through transparent overlays)
- Works with Volumio OTA updates
- Debug overlay with rotation information
- Supports both micro (6 frame) and progress (90 frame) sequences
- Init-premount and systemd service for boot/shutdown detection

**Status**: Complete, tested on Raspberry Pi 5 with Waveshare 11.9" LCD (v1.02)

See [volumio-plymouth-adaptive/README.md](volumio-plymouth-adaptive/README.md) for details.

### volumio-text-adaptive

**INTEGRATION NOTE**: When integrated into volumio-os, this theme becomes `volumio-text` and uses framebuffer rotation (`video=` or `fbcon=` parameters) instead of theme-level coordinate transformation. See "Integration Changes" section below for details.

A rotation-adaptive text-based Plymouth boot theme for Volumio.

**Problem Solved**: Provides a lightweight fallback boot splash when full graphical themes cannot be used or when minimal resource usage is required. Adapts to display rotation without pre-rendered image sequences.

**Solution**: Runtime coordinate transformation based on kernel rotation parameter. Dynamically repositions text elements for proper display at any orientation.

**Features**:
- Runtime rotation detection (no initramfs rebuild required)
- Runtime coordinate transformation for 0, 90, 180, 270 degrees
- Text-only rendering (no image sequences)
- Minimal storage footprint
- Screen size adaptation (font sizing, text truncation)
- Single-line system message display
- Password prompt support
- No generation script needed
- Works with Volumio OTA updates

**Use Cases**:
- Fallback/test environments
- Minimal installations
- Low storage situations
- Quick deployment scenarios

**Status**: Complete, tested on Raspberry Pi 5 with Waveshare 11.9" LCD

See [volumio-text-adaptive/README.md](volumio-text-adaptive/README.md) for details.

## Volumio Configuration Hierarchy

Volumio uses a specific configuration file hierarchy. Understanding this is critical for proper installation:

1. `/boot/config.txt` - Build process managed (DO NOT MODIFY)
   - System managed, changes may be overwritten
   
2. `/boot/volumioconfig.txt` - Volumio player defaults (DO NOT MODIFY)
   - System managed defaults
   
3. `/boot/userconfig.txt` - Hardware configuration (MODIFY THIS)
   - dtoverlay parameters
   - hdmi_group, hdmi_mode settings
   - User changes are preserved across updates
   
4. `/boot/cmdline.txt` - Kernel command line (MODIFY THIS)
   - `video=` parameter (display mode and fbcon rotation)
   - `plymouth=` parameter (volumio-adaptive theme rotation)
   - `fbcon=` parameter (alternative console font rotation)
   - Must be single line, space-separated

**Example Configuration**:

`/boot/userconfig.txt`:
```
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 1480 60 6 0 0 0
```

`/boot/cmdline.txt`:
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

**Parameter Usage**:
- `plymouth=90` - For volumio-adaptive theme (selects pre-rotated image sequence)
- `video=HDMI-A-1:...,rotate=270` - For volumio-text rotation via framebuffer
- Both parameters can coexist - each theme uses its appropriate method

**Key Points**:
- `video=`, `plymouth=`, and `fbcon=` ALL go in `/boot/cmdline.txt`
- `/boot/userconfig.txt` is for hardware config only (dtoverlay, hdmi settings)
- cmdline.txt must be single line with no line breaks
- volumio-adaptive uses `plymouth=` parameter
- volumio-text uses `video=...,rotate=` or `fbcon=rotate:` parameter

**Important**: cmdline.txt location varies by OS:
- Volumio 3.x/4.x: `/boot/cmdline.txt`
- Raspberry Pi OS Bookworm: `/boot/firmware/cmdline.txt`

## Integration Changes

When integrated into volumio-os, the themes undergo specific adaptations due to Plymouth Script API limitations:

### volumio-adaptive Integration

- **Theme name**: `volumio-adaptive` (new theme added to volumio-os)
- **Rotation method**: Theme-level using `plymouth=` parameter
- **Implementation**: Pre-rotated image sequences (sequence0/, sequence90/, sequence180/, sequence270/)
- **Runtime detection**: Patches theme script via 00-plymouth-rotation and plymouth-rotation.sh
- **Status**: No changes from development version

### volumio-text Integration

- **Theme name**: `volumio-text` (replaces existing volumio-text in volumio-os)
- **Rotation method**: System-level using framebuffer rotation
- **Implementation**: Simple theme relying on `video=...,rotate=` or `fbcon=rotate:` parameters
- **Runtime detection**: None needed - framebuffer handles rotation
- **Changes from development version**:
  - Removed coordinate transformation logic
  - Removed `rotate=` parameter support
  - Simplified from 227 lines to 174 lines
  - Uses fbcon rotation instead of theme-level rotation

### Why The Change?

Plymouth Script API does not support rotating text images at runtime:
- No `Image.Rotate()` function exists
- `Image.Text()` creates horizontal text only
- Cannot rotate dynamic text at runtime

**Evidence**: volumio-player-ccw theme disables text messages with comment "plymouth is unable to rotate properly in init"

**Solution**:
- volumio-adaptive: Pre-rotated images work (static content)
- volumio-text: Framebuffer rotation required (dynamic text)

### Parameter Summary

| Theme | Parameter | Purpose |
|-------|-----------|---------|
| volumio-adaptive | `plymouth=0\|90\|180\|270` | Select pre-rotated image sequence |
| volumio-text | `video=...,rotate=90` or `fbcon=rotate:1` | Rotate framebuffer |

**Note**: `plymouth=` and framebuffer rotation parameters are NOT interchangeable. Each theme uses its appropriate method.

## Installation

See individual theme directories for installation instructions:
- [volumio-plymouth-adaptive/INSTALLATION.md](volumio-plymouth-adaptive/INSTALLATION.md)
- [volumio-text-adaptive/INSTALLATION.md](volumio-text-adaptive/INSTALLATION.md)

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

### Version 1.02 (November 2, 2025)
- volumio-plymouth-adaptive: Transparent message overlay system
  - 13 Volumio boot message overlays with pattern matching
  - OEM compatibility (handles version variables in messages)
  - Adaptive sizing based on display dimensions (400px breakpoint)
  - Z-index layering (logo visible through transparent overlays)
  - 104 pre-rendered overlay images (13 messages × 2 sizes × 4 rotations)
  - Overlays placed directly in sequence directories alongside animations
  - Why overlays: Plymouth Image.Text.Rotate() produces severe clipping artifacts
  - generate-overlays.sh script for regenerating custom overlays

### Version 1.0 (October 30, 2025)
- Initial release
- volumio-plymouth-adaptive complete
  - Runtime rotation detection (init-premount + systemd solution)
  - Pre-rotated image support for 0, 90, 180, 270 degrees
  - No initramfs rebuild required for rotation changes
  - Compatible with Volumio OTA updates
  - Complete documentation suite
  - Installation and quick reference guides
- volumio-text-adaptive complete
  - Rotation-adaptive text-based Plymouth theme
  - Runtime coordinate transformation
  - Minimal storage footprint
  - Fallback/test theme for constrained environments
  - Complete documentation suite

### Technical Notes
- Tested on Raspberry Pi OS Bookworm and Volumio 4.x
- Works on all architectures (ARM, amd64)
- Plymouth API limitations bypassed with init-premount scripting
- Supports both boot and shutdown rotation adaptation
- v1.02: Overlay system solves Plymouth text rotation clipping issue

### Future Updates
- This section will track additions and changes
- Bug fixes and optimizations
- Additional features and improvements
