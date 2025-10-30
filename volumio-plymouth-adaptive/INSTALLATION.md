# Volumio-Adaptive Plymouth Theme Installation

Complete installation and testing instructions

## Overview

This package provides a universal Plymouth boot splash theme that adapts to different display rotations. With the optional runtime detection system (recommended), rotation changes require only editing cmdline.txt and rebooting - no initramfs rebuilds needed. The theme uses pre-rendered image sequences for each rotation (0, 90, 180, 270 degrees).

## Package Contents

1. `volumio-adaptive.script` - Main Plymouth script with rotation support
2. `volumio-adaptive.plymouth` - Theme configuration file
3. `generate-rotated-sequences.sh` - Image generation script
4. `runtime-detection/` - Optional runtime detection system (recommended)
   - `00-plymouth-rotation` - Init-premount script
   - `plymouth-rotation.sh` - Systemd script
   - `plymouth-rotation.service` - Service unit
   - `RUNTIME-DETECTION-INSTALL.md` - Installation guide

## Prerequisites

- Raspberry Pi OS Bookworm or later
- Plymouth installed (should be present by default)
- ImageMagick for image rotation
- Access to volumio-player theme source images
- Root access for installation

### Install ImageMagick (if needed)

```bash
sudo apt-get install imagemagick
```

## Installation Steps

### Step 1: Create Theme Directory

```bash
sudo mkdir -p /usr/share/plymouth/themes/volumio-adaptive
sudo chown volumio:volumio /usr/share/plymouth/themes/volumio-adaptive
```

### Step 2: Copy Theme Files

```bash
sudo cp volumio-adaptive.script /usr/share/plymouth/themes/volumio-adaptive/
sudo cp volumio-adaptive.plymouth /usr/share/plymouth/themes/volumio-adaptive/
```

### Step 3: Generate Rotated Image Sequences

Make the generation script executable:

```bash
chmod +x generate-rotated-sequences.sh
```

Run the script to generate all four rotation directories:

```bash
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
```

This will create:
- `/usr/share/plymouth/themes/volumio-adaptive/sequence0/`
- `/usr/share/plymouth/themes/volumio-adaptive/sequence90/`
- `/usr/share/plymouth/themes/volumio-adaptive/sequence180/`
- `/usr/share/plymouth/themes/volumio-adaptive/sequence270/`

**Expected output**: 97 files per directory (90 progress + 6 micro + 1 layout-constraint)

### Step 4: Set Permissions

```bash
sudo chown -R volumio:volumio /usr/share/plymouth/themes/volumio-adaptive
sudo chmod 644 /usr/share/plymouth/themes/volumio-adaptive/*.script
sudo chmod 644 /usr/share/plymouth/themes/volumio-adaptive/*.plymouth
sudo chmod 644 /usr/share/plymouth/themes/volumio-adaptive/sequence*/*.png
```

### Step 5: Install Theme

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

This command:
- Sets volumio-adaptive as the default theme
- Rebuilds initramfs with the new theme (-R flag)

**IMPORTANT**: Wait for initramfs rebuild to complete (may take 1-2 minutes)

### Step 6: Install Runtime Detection (Recommended)

Runtime detection eliminates the need for manual script edits and initramfs rebuilds when changing display rotation. This is a one-time setup.

**See [runtime-detection/RUNTIME-DETECTION-INSTALL.md](runtime-detection/RUNTIME-DETECTION-INSTALL.md) for detailed instructions.**

Quick summary:
1. Copy `00-plymouth-rotation` to `/etc/initramfs-tools/scripts/init-premount/`
2. Copy `plymouth-rotation.sh` to `/usr/local/bin/`
3. Copy `plymouth-rotation.service` to `/etc/systemd/system/`
4. Enable the service: `systemctl enable plymouth-rotation.service`
5. Rebuild initramfs: `sudo update-initramfs -u`

After runtime detection is installed:
- Rotation changes only require editing cmdline.txt and rebooting
- No manual script edits needed
- No repeated initramfs rebuilds needed

**Without runtime detection**, you must manually edit the script and rebuild initramfs for each rotation change.

## Configuration

Volumio uses a specific configuration file hierarchy:

### Configuration File Hierarchy

- **`/boot/config.txt`** - DO NOT MODIFY (build process managed)
- **`/boot/volumioconfig.txt`** - DO NOT MODIFY (Volumio defaults)
- **`/boot/userconfig.txt`** - USER EDITABLE (hardware: dtoverlay, hdmi_group, hdmi_mode)
- **`/boot/cmdline.txt`** - USER EDITABLE (kernel parameters: ALL display and Plymouth settings)

### Kernel Command Line Configuration

All display rotation and Plymouth parameters go in `/boot/cmdline.txt` as a **single line** with space-separated parameters.

Edit `/boot/cmdline.txt`:

```bash
sudo nano /boot/cmdline.txt
```

**IMPORTANT**: cmdline.txt must be a single line. Do not add line breaks.

### Adding Display and Plymouth Parameters

To the existing line in cmdline.txt, add:

**For landscape displays (no rotation)**:
```
plymouth=0
```
(Or omit plymouth= parameter, defaults to 0)

**For portrait display rotated 90 degrees clockwise**:
```
video=HDMI-A-1:1080x1920M@60,rotate=90 plymouth=270
```

**For portrait display rotated 270 degrees clockwise (90 CCW)**:
```
video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

**For upside-down display (180 degrees)**:
```
video=HDMI-A-1:1920x1080M@60,rotate=180 plymouth=180
```

### Understanding the Parameters

- **`video=INTERFACE:WIDTHxHEIGHTM@REFRESH`** - Display configuration
  - INTERFACE: HDMI-A-1, HDMI-A-2, DSI-1, etc.
  - WIDTH x HEIGHT: Native resolution
  - M: Monitor timing mode
  - @REFRESH: Refresh rate (usually 60)

- **`rotate=XXX`** - Console/framebuffer rotation (kernel level)
  - Affects text console and graphics
  - Does NOT affect Plymouth directly

- **`plymouth=XXX`** - Plymouth theme image selection
  - Tells theme which pre-rotated images to use
  - INDEPENDENT of rotate= parameter
  - Formula: plymouth = (360 - rotate) % 360

- **`fbcon=map:10`** (optional) - Framebuffer console mapping
  - Vendor/hardware specific parameter
  - Include if needed for your display

### Example: Waveshare 11.9" LCD (320x1480 native portrait)

**Vanilla cmdline.txt** (as shipped):
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no
```

**Modified for portrait display** (add parameters at end):
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 dwc_otg.fiq_fsm_enable=1 dwc_otg.fiq_fsm_mask=0xF dwc_otg.nak_holdoff=1 quiet console=serial0,115200 console=tty1 imgpart=UUID=cfdb2ece-53a1-41e1-976e-083b99a3d665 imgfile=/volumio_current.sqsh bootpart=UUID=3533-4CB0 datapart=UUID=f76792a9-df7b-4cdd-8b61-c2c89d5cbb6e uuidconfig=cmdline.txt pcie_aspm=off pci=pcie_bus_safe rootwait bootdelay=7 logo.nologo vt.global_cursor_default=0 net.ifnames=0 snd-bcm2835.enable_compat_alsa= snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 loglevel=0 nodebug use_kmsg=no video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

**Key changes**:
- Added: `video=HDMI-A-1:320x1480M@60,rotate=270` (console rotates 270 CCW)
- Added: `plymouth=90` (Plymouth uses 90 CW rotated images)
- Result: Correctly oriented display

### Toggle Parameters (Not Additions)

Some parameters are toggles - change between values, don't add both:

**Debug Control**:
- `nodebug` (default, no kernel debug) ↔ `debug` (enable kernel debug for dmesg)

**Plymouth Control**:
- `splash` (default, show Plymouth) ↔ `nosplash` (disable Plymouth)

**Console Messages**:
- `quiet` (default, suppress messages) ↔ `noquiet` (show all messages)

### Debugging Configuration

**For debugging Plymouth issues**, modify the toggles and add plymouth.debug:

```
splash ... noquiet ... debug plymouth.debug use_kmsg=no video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

Changes from vanilla:
- `quiet` → `noquiet` (show console messages)
- `nodebug` → `debug` (enable kernel debug)
- ADD: `plymouth.debug` (creates /var/log/plymouth-debug.log)

**After debugging**, revert:
- `noquiet` → `quiet`
- `debug` → `nodebug`
- REMOVE: `plymouth.debug`

### Hardware Configuration (userconfig.txt)

For hardware-level display settings, edit `/boot/userconfig.txt`:

```bash
sudo nano /boot/userconfig.txt
```

May contain:
```
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
```

**Note**: Video rotation (video=, rotate=) does NOT go here - it goes in cmdline.txt.

## Testing

### Method 1: Preview Mode (Recommended for Initial Testing)

Test without rebooting using Plymouth's preview mode:

```bash
sudo plymouthd --debug --debug-file=/tmp/plymouth-debug.log
sudo plymouth show-splash
# Wait 10 seconds to see animation
sudo plymouth quit
```

Check debug log if issues occur:

```bash
cat /tmp/plymouth-debug.log
```

### Method 2: Full Boot Test

```bash
sudo reboot
```

Observe Plymouth splash during boot. It should:
- Display correctly oriented Volumio logo
- Animate smoothly (90 frames for progress, 6 for micro)
- Show boot messages in correct orientation

### Method 3: Shutdown Test

```bash
sudo shutdown -h now
```

Plymouth should display during shutdown (if configured).

## Troubleshooting

### Plymouth not displaying at boot

**Check 1: Verify theme is installed**

```bash
sudo plymouth-set-default-theme
```

Should output: `volumio-adaptive`

**Check 2: Verify initramfs contains theme**

```bash
lsinitramfs /boot/initrd.img-$(uname -r) | grep plymouth | grep volumio-adaptive
```

Should show files from volumio-adaptive theme.

**Check 3: Verify plymouth= parameter**

```bash
cat /boot/cmdline.txt | grep plymouth=
```

**Check 4: Check Plymouth service status**

```bash
sudo systemctl status plymouth-start.service
sudo systemctl status plymouth-quit.service
```

### Images rotated incorrectly

Verify `plymouth=` value matches your display configuration:
- If console text is correct but Plymouth is wrong, adjust `plymouth=` value
- Remember: `plymouth_rotation = (360 - kernel_rotation) % 360`

### Only seeing micro sequence on large display

Enable debug overlay to check dimensions:

1. Edit `/usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script`
2. Change line: `enable_debug_overlay = (Window.GetWidth() < 0);`
   To: `enable_debug_overlay = (Window.GetWidth() > -1);`
3. Rebuild: `sudo plymouth-set-default-theme -R volumio-adaptive`
4. Reboot and observe debug text

### Missing images

Verify all image files exist:

```bash
ls -la /usr/share/plymouth/themes/volumio-adaptive/sequence0/ | wc -l
ls -la /usr/share/plymouth/themes/volumio-adaptive/sequence90/ | wc -l
ls -la /usr/share/plymouth/themes/volumio-adaptive/sequence180/ | wc -l
ls -la /usr/share/plymouth/themes/volumio-adaptive/sequence270/ | wc -l
```

Each should show 97 files (plus . and ..).

## Advanced Configuration

### Custom Rotation Values

The theme supports any numeric value for `plymouth=`, though only 0, 90, 180, 270 are provided by default. To add custom rotations:

1. Create new directory: `/usr/share/plymouth/themes/volumio-adaptive/sequence<VALUE>/`
2. Populate with rotated images
3. Use `plymouth=<VALUE>` in cmdline.txt

### Debug Mode

To enable debug overlay permanently:

1. Edit `volumio-adaptive.script`
2. Line ~100: `enable_debug_overlay = (Window.GetWidth() > -1);`
3. Rebuild: `sudo plymouth-set-default-theme -R volumio-adaptive`

The debug overlay shows:
- "ADAPTIVE SCRIPT OK" - script loaded successfully
- "FB: WxH" - raw framebuffer dimensions
- "ROTATION: X" - parsed `plymouth=` value
- "MICRO: 0/1" - whether using micro sequence

## Reverting to Original Theme

To switch back to volumio-player:

```bash
sudo plymouth-set-default-theme -R volumio-player
```

## Technical Notes

1. Plymouth `Image()` function uses paths relative to ImageDir set in .plymouth file
2. `Window.GetWidth()` and `Window.GetHeight()` return RAW framebuffer dimensions
3. Kernel rotation affects console but NOT Plymouth's view of framebuffer
4. Script swaps width/height logic for portrait orientations (90, 270)
5. Micro sequence activates when `(screen_width <= 640) && (screen_height <= 640)`
6. Animation timing: micro advances every 20 ticks, progress every 3 ticks

## Configuration Parameter Priority

The `plymouth=` parameter is INDEPENDENT of `video=` `rotate=` parameter.

**Correct usage**:

`/boot/userconfig.txt`:
```
video=HDMI-A-1:320x1480M@60,rotate=270
```

`/boot/cmdline.txt`:
```
plymouth=90
```

**Do NOT use**:
```
video=HDMI-A-1:320x1480M@60,rotate=270
# Missing plymouth= in cmdline.txt, will default to 0
```

## Performance Considerations

- All 90 images are loaded into memory at boot (or 6 for micro sequence)
- Total memory usage: ~800KB for progress sequence, ~50KB for micro
- Image loading happens once during Plymouth initialization
- No performance penalty for rotation logic (simple integer comparison)

## Maintenance

### To update images in the future

1. Update source images in `volumio-player/sequence/`
2. Re-run `generate-rotated-sequences.sh`
3. Rebuild initramfs: `sudo plymouth-set-default-theme -R volumio-adaptive`

No script changes needed when updating images.

## Support

For issues or questions:
1. Check `/tmp/plymouth-debug.log` for errors
2. Verify all files and permissions
3. Test with debug overlay enabled
4. Report to Volumio development team with debug log

## Version History

**1.0** - Initial release with adaptive rotation support
- Four rotation presets (0, 90, 180, 270)
- Micro and progress sequence support
- Debug overlay
- No initramfs rebuild needed for rotation changes
- 