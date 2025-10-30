# Volumio-Adaptive Quick Reference

Quick command reference and common scenarios

## Installation (One-time Setup)

### 1. Create theme directory

```bash
sudo mkdir -p /usr/share/plymouth/themes/volumio-adaptive
sudo chown volumio:volumio /usr/share/plymouth/themes/volumio-adaptive
```

### 2. Copy files

```bash
sudo cp volumio-adaptive.script /usr/share/plymouth/themes/volumio-adaptive/
sudo cp volumio-adaptive.plymouth /usr/share/plymouth/themes/volumio-adaptive/
```

### 3. Generate rotated images

```bash
chmod +x generate-rotated-sequences.sh
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
```

### 4. Install theme

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

## Changing Display Rotation

**NO INITRAMFS REBUILD NEEDED!** Just edit cmdline.txt:

### Edit kernel command line

```bash
sudo nano /boot/cmdline.txt
```

Add parameters to the existing single line (space-separated):

```
video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

**Example complete line** (portrait display):

```
splash plymouth.ignore-serial-consoles ... quiet ... nodebug use_kmsg=no video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

**IMPORTANT**: cmdline.txt must remain a single line with space-separated parameters.

### Reboot

```bash
sudo reboot
```

## Volumio Configuration Files

- **`/boot/config.txt`** - DO NOT MODIFY (build process managed)
- **`/boot/volumioconfig.txt`** - DO NOT MODIFY (Volumio defaults)
- **`/boot/userconfig.txt`** - USER EDITABLE (dtoverlay, hdmi_group, hdmi_mode)
- **`/boot/cmdline.txt`** - USER EDITABLE (video=, rotate=, plymouth=, fbcon=)

**Note**: Display rotation (video=, rotate=) and Plymouth parameter (plymouth=) go in cmdline.txt, NOT userconfig.txt.

## Rotation Cheatsheet

| Kernel rotate= | plymouth= | Result                       |
|----------------|-----------|------------------------------|
| (none)         | 0         | Landscape, no rotation       |
| rotate=90      | 270       | Portrait, 270 CW (90 CCW)    |
| rotate=180     | 180       | Landscape, upside-down       |
| rotate=270     | 90        | Portrait, 90 CW              |

**Formula**: `plymouth = (360 - rotate) % 360`

## Quick Testing

### Preview without reboot

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

## Troubleshooting Commands

### Check current theme

```bash
sudo plymouth-set-default-theme
```

### Check if theme files exist

```bash
ls -la /usr/share/plymouth/themes/volumio-adaptive/
```

### Check image directories

```bash
ls /usr/share/plymouth/themes/volumio-adaptive/sequence*/
```

### View current configuration

**Display and Plymouth configuration** (all in cmdline.txt):

```bash
cat /boot/cmdline.txt
```

Look for: video=, rotate=, plymouth= parameters

**Hardware configuration**:

```bash
cat /boot/userconfig.txt
```

Look for: dtoverlay, hdmi_group, hdmi_mode parameters

### Check Plymouth service

```bash
sudo systemctl status plymouth-start.service
```

### Enable debug overlay

Edit script, then rebuild:

```bash
sudo nano /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
```

Change:
```
enable_debug_overlay = (Window.GetWidth() < 0);
```

To:
```
enable_debug_overlay = (Window.GetWidth() > -1);
```

Rebuild:

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

## Reverting to Original

```bash
sudo plymouth-set-default-theme -R volumio-player
```

## File Locations

### Theme files

```
/usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
/usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.plymouth
```

### Image directories

```
/usr/share/plymouth/themes/volumio-adaptive/sequence0/
/usr/share/plymouth/themes/volumio-adaptive/sequence90/
/usr/share/plymouth/themes/volumio-adaptive/sequence180/
/usr/share/plymouth/themes/volumio-adaptive/sequence270/
```

### Boot configuration

```
/boot/userconfig.txt (hardware config: dtoverlay, hdmi settings)
/boot/cmdline.txt (kernel parameters: video=, rotate=, plymouth=)
```

### Debug log (when using preview mode)

```
/tmp/plymouth-debug.log
```

## Common Scenarios

### Scenario 1: New display with different rotation

1. Edit `/boot/cmdline.txt` - update `video=`, `rotate=`, and `plymouth=` values
2. Reboot
3. **NO theme reinstall needed!**

### Scenario 2: Testing different rotations

1. Edit configuration files, change rotation values
2. Reboot to test
3. Repeat until correct

### Scenario 3: Updating Volumio logo/images

1. Update source images in `volumio-player/sequence/`
2. Re-run `generate-rotated-sequences.sh`
3. Rebuild: `sudo plymouth-set-default-theme -R volumio-adaptive`
4. Reboot

### Scenario 4: Plymouth not showing

1. Check theme installed: `sudo plymouth-set-default-theme`
2. Check cmdline has "quiet splash"
3. Check services: `systemctl status plymouth-*`
4. Try preview mode for debugging

## Example Configurations

### Landscape Display (1920x1080)

`/boot/cmdline.txt` (add to existing line):
```
plymouth=0
```
(Or omit plymouth=, defaults to 0)

### Portrait Display - Waveshare 11.9" (320x1480)

`/boot/cmdline.txt` (add to existing line):
```
video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

### Portrait Display - Official Pi Touchscreen (800x480)

`/boot/cmdline.txt` (add to existing line):
```
video=DSI-1:800x480M@60,rotate=90 plymouth=270
```

### Upside-Down Display

`/boot/cmdline.txt` (add to existing line):
```
video=HDMI-A-1:1920x1080M@60,rotate=180 plymouth=180
```

### Debugging Configuration

`/boot/cmdline.txt` (modify toggles, add plymouth.debug):

Change:
- `quiet` → `noquiet`
- `nodebug` → `debug`
- ADD: `plymouth.debug`

Example:
```
splash ... noquiet ... debug plymouth.debug use_kmsg=no video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```

Debug outputs:
- `debug` → kernel messages (view with dmesg)
- `plymouth.debug` → /var/log/plymouth-debug.log

## Remember

1. `plymouth=` parameter is INDEPENDENT of `rotate=` parameter
2. Both `video=`, `rotate=`, and `plymouth=` go in `/boot/cmdline.txt` (single line)
3. NO initramfs rebuild when changing parameters
4. Formula: `plymouth_rotation = (360 - kernel_rotation) % 360`
5. Default is `plymouth=0` if parameter omitted
6. `/boot/userconfig.txt` is for hardware config only (dtoverlay, hdmi settings)
7. Toggle parameters: change `debug`/`nodebug`, `quiet`/`noquiet`, `splash`/`nosplash`
8. `plymouth.debug` is ADDED for debugging (not a toggle)
