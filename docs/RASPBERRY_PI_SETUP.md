# Raspberry Pi Setup Guide

Complete guide for configuring Raspberry Pi with rotated displays for Volumio.

## Prerequisites

- Raspberry Pi (3, 4, or 5 recommended)
- Raspberry Pi OS Bookworm or compatible
- Volumio installed
- Root or sudo access

## Volumio Configuration Files

Volumio uses a specific hierarchy for boot configuration:

### /boot/config.txt
**DO NOT MODIFY DIRECTLY**
- Managed by build process
- Changes may be overwritten
- System configuration

### /boot/volumioconfig.txt
**DO NOT MODIFY**
- Volumio player defaults
- System managed
- Application-level settings

### /boot/userconfig.txt
**USER EDITABLE**
- Hardware configuration only
- dtoverlay settings
- hdmi_group, hdmi_mode settings
- display_rotate (legacy, deprecated - use video= rotate= in cmdline.txt instead)
- User changes preserved
- IMPORTANT: video= and rotate= parameters go in cmdline.txt, NOT here

### /boot/cmdline.txt
**USER EDITABLE**
- Kernel command line parameters
- CRITICAL: video= and rotate= parameters MUST go here
- plymouth= parameter goes here
- One line only, space-separated parameters
- Location varies by OS:
  - Volumio 3.x/4.x: /boot/cmdline.txt
  - Pi OS Bookworm: /boot/firmware/cmdline.txt

## Display Detection

Before configuring, identify your display:

```bash
# List connected displays
kmsprint

# Or use tvservice (legacy)
tvservice -l
tvservice -s
```

Note the display name (usually HDMI-A-1 or HDMI-A-2).

## Basic Display Configuration

### Landscape Display (No Rotation)

/boot/userconfig.txt:
```
# Force specific resolution if needed
hdmi_group=2
hdmi_mode=82
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=xxxx rootfstype=ext4 fsck.repair=yes rootwait plymouth=0 quiet splash
```

### Portrait Display - Method 1 (Modern KMS)

/boot/userconfig.txt:
```
# Hardware settings only - no video= or rotate= here
# Optional: Force specific hdmi settings if needed
# hdmi_group=2
# hdmi_mode=87
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=xxxx rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90 quiet splash
```

Note: video= and rotate= MUST be in cmdline.txt (single line with all other parameters).

### Portrait Display - Method 2 (Legacy Rotation - DEPRECATED)

/boot/userconfig.txt:
```
display_rotate=3
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=xxxx rootfstype=ext4 fsck.repair=yes rootwait plymouth=90 quiet splash
```

Note: display_rotate is legacy and deprecated. Use video= rotate= in cmdline.txt (Method 1) instead.

## Runtime Detection (Recommended)

The volumio-plymouth-adaptive theme includes optional runtime detection that eliminates manual script edits when changing rotation.

### What Runtime Detection Does

- Automatically patches theme scripts at boot based on cmdline.txt parameters
- Eliminates need for manual script edits
- Eliminates need for repeated initramfs rebuilds
- One-time installation, zero maintenance

### Installation

See: volumio-plymouth-adaptive/runtime-detection/RUNTIME-DETECTION-INSTALL.md

Quick summary:
```bash
# Copy scripts
sudo cp runtime-detection/00-plymouth-rotation /etc/initramfs-tools/scripts/init-premount/
sudo cp runtime-detection/plymouth-rotation.sh /usr/local/bin/
sudo cp runtime-detection/plymouth-rotation.service /etc/systemd/system/

# Make executable
sudo chmod +x /etc/initramfs-tools/scripts/init-premount/00-plymouth-rotation
sudo chmod +x /usr/local/bin/plymouth-rotation.sh

# Enable service
sudo systemctl enable plymouth-rotation.service

# Rebuild initramfs (one time)
sudo update-initramfs -u
```

### After Runtime Detection is Installed

To change display rotation:
1. Edit /boot/cmdline.txt (change plymouth= or rotate= values)
2. Reboot
3. Done - no manual edits, no rebuilds

### Without Runtime Detection

Without runtime detection installed:
1. Edit /boot/cmdline.txt (change plymouth= value)
2. Edit /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
3. Change plymouth_rotation value manually
4. Rebuild initramfs: sudo update-initramfs -u
5. Reboot

Runtime detection is highly recommended for ease of use.

## Common Display Types

### Official Raspberry Pi Touch Display (800x480)

Portrait mode:

/boot/userconfig.txt:
```
# Hardware only - no video= here
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=xxxx rootfstype=ext4 fsck.repair=yes rootwait video=DSI-1:800x480M@60,rotate=90 plymouth=270 quiet splash
```

### Waveshare Displays

11.9" LCD (320x1480):

/boot/userconfig.txt:
```
# Hardware only
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=xxxx rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90 quiet splash
```

7" HDMI (1024x600):

/boot/userconfig.txt:
```
# Hardware only
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=xxxx rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-1:1024x600M@60 plymouth=0 quiet splash
```

### Generic HDMI Display

Standard 1920x1080:

/boot/userconfig.txt:
```
# Usually auto-detected, but can force:
hdmi_group=1
hdmi_mode=16
```

/boot/cmdline.txt:
```
plymouth=0
```

## Rotation Values

### rotate= (Kernel Parameter)

| Value | Effect |
|-------|--------|
| 0     | Normal (default) |
| 90    | 90 degrees counterclockwise |
| 180   | 180 degrees (upside-down) |
| 270   | 270 degrees counterclockwise (= 90 clockwise) |

### display_rotate= (Legacy)

| Value | Effect |
|-------|--------|
| 0     | Normal |
| 1     | 90 degrees |
| 2     | 180 degrees |
| 3     | 270 degrees |

### plymouth= (This Theme)

| Value | Effect |
|-------|--------|
| 0     | Normal |
| 90    | 90 degrees clockwise |
| 180   | 180 degrees |
| 270   | 270 degrees clockwise |

## Testing Configuration

### Step 1: Edit Configuration

```bash
sudo nano /boot/userconfig.txt
# Add or modify video= line

sudo nano /boot/cmdline.txt
# Add or modify plymouth= parameter
```

### Step 2: Reboot

```bash
sudo reboot
```

### Step 3: Verify Boot Splash

Watch the boot splash:
- Animation should be correctly oriented
- Text should be readable
- No distortion or stretching

### Step 4: Verify Console

After boot completes:
- Console text should be readable
- Correct orientation
- Proper dimensions

## Troubleshooting

### Boot Splash Sideways

Problem: Animation shows but rotated wrong

Solution: Adjust plymouth= value
- Try opposite rotation (90 vs 270)
- Use formula: plymouth = (360 - kernel_rotate) % 360

### Console Correct but Plymouth Wrong

Problem: Console text readable, boot splash wrong

Solution: plymouth= parameter missing or incorrect
- Check /boot/cmdline.txt has plymouth= parameter
- Verify value matches formula

### Both Wrong

Problem: Both console and Plymouth wrong orientation

Solution: Fix kernel rotation first
- Check video= rotate= in /boot/userconfig.txt
- Or display_rotate= if using legacy method

### Display Not Detected

Problem: No output on display

Solutions:
- Check physical connections
- Try forcing HDMI: hdmi_force_hotplug=1 in userconfig.txt
- Check display power
- Try different HDMI port (Pi 4/5 have two ports)

### Resolution Wrong

Problem: Display works but wrong resolution

Solutions:
- Explicitly set with video= parameter
- Or use hdmi_group and hdmi_mode
- Check display's native resolution
- Try hdmi_safe=1 for testing

## Advanced Configuration

### Multiple Displays

Pi 4 and 5 support two displays:

/boot/userconfig.txt:
```
video=HDMI-A-1:1920x1080M@60
video=HDMI-A-2:1024x600M@60,rotate=90
```

/boot/cmdline.txt:
```
plymouth=0
```

Note: Plymouth only shows on first display.

### Custom Resolutions

Some displays need custom timings:

/boot/userconfig.txt:
```
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 1480 60 6 0 0 0
video=HDMI-A-1:320x1480M@60,rotate=270
```

### Overscan Adjustment

If boot splash has black borders:

/boot/userconfig.txt:
```
disable_overscan=1
```

Or adjust manually:
```
overscan_left=0
overscan_right=0
overscan_top=0
overscan_bottom=0
```

## Performance Tuning

### GPU Memory

Increase for better graphics performance:

/boot/userconfig.txt:
```
gpu_mem=128
```

Range: 64-256 MB depending on total RAM

### Framebuffer

Lock framebuffer to specific resolution:

/boot/cmdline.txt:
```
fbcon=map:10 fbcon=font:VGA8x8
```

## Verification Commands

### Check Current Configuration

```bash
# Display kernel command line
cat /proc/cmdline

# Check framebuffer info
fbset

# Check KMS status
dmesg | grep drm

# List video modes
kmsprint -m
```

### Check Plymouth Status

```bash
# Plymouth version
plymouth --version

# Current theme
plymouth-set-default-theme

# Test theme (requires plymouth running)
plymouth show-splash
```

### Check Display Info

```bash
# Connected displays
kmsprint | grep Connector

# Resolution and refresh
kmsprint | grep mode

# Framebuffer devices
ls -l /dev/fb*
```

## Example Configurations

### Configuration 1: Landscape Desktop

Display: 1920x1080 HDMI monitor
Orientation: Normal

/boot/userconfig.txt:
```
# Auto-detected, no changes needed
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 fsck.repair=yes rootwait plymouth=0 quiet splash
```

### Configuration 2: Portrait Touchscreen

Display: 800x480 official touchscreen
Orientation: Portrait (cable at top)

/boot/userconfig.txt:
```
# Hardware only
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 fsck.repair=yes rootwait video=DSI-1:800x480M@60,rotate=270 plymouth=90 quiet splash
```

### Configuration 3: Tall Portrait Display

Display: Waveshare 11.9" (320x1480)
Orientation: Portrait (cable at bottom)

/boot/userconfig.txt:
```
# Hardware only
```

/boot/cmdline.txt:
```
console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90 quiet splash
```

## Safety Tips

### Before Editing

```bash
# Backup configuration files
sudo cp /boot/userconfig.txt /boot/userconfig.txt.backup
sudo cp /boot/cmdline.txt /boot/cmdline.txt.backup
```

### After Editing

```bash
# Verify file syntax
cat /boot/userconfig.txt
cat /boot/cmdline.txt

# Check no extra newlines in cmdline.txt (must be single line)
wc -l /boot/cmdline.txt
# Should output: 1
```

### Recovery

If system won't boot:
1. Remove SD card
2. Mount on another system
3. Edit /boot/userconfig.txt and /boot/cmdline.txt
4. Restore .backup files if needed
5. Reinsert and boot

## References

- Raspberry Pi Video Options: https://www.raspberrypi.com/documentation/computers/config_txt.html
- KMS Documentation: https://www.kernel.org/doc/html/latest/gpu/drm-kms.html
- Plymouth Documentation: https://www.freedesktop.org/wiki/Software/Plymouth/
