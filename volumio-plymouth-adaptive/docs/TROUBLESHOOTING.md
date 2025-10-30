# Troubleshooting Guide

Comprehensive troubleshooting for volumio-adaptive Plymouth theme

## Quick Diagnostic Checklist

Before diving into specific issues, run these quick checks:

```bash
# 1. Verify theme is installed
sudo plymouth-set-default-theme

# 2. Check configuration in cmdline.txt
cat /boot/cmdline.txt | grep -E "video=|rotate=|plymouth="

# 3. Verify image directories exist
ls -d /usr/share/plymouth/themes/volumio-adaptive/sequence*/

# 4. Check Plymouth service status
systemctl status plymouth-start.service
```

## Problem: Plymouth Not Displaying at Boot

### Symptom

No boot splash appears, just blank screen or text console messages.

### Diagnosis Steps

**Step 1: Verify theme installation**

```bash
sudo plymouth-set-default-theme
```

Expected output: `volumio-adaptive`

If not, reinstall:

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

**Step 2: Check initramfs contains theme**

```bash
lsinitramfs /boot/initrd.img-$(uname -r) | grep plymouth | grep volumio-adaptive
```

Should show multiple files from volumio-adaptive theme.

If empty, rebuild initramfs:

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

**Step 3: Verify cmdline.txt has splash parameters**

```bash
cat /boot/cmdline.txt
```

Must contain: `quiet splash`

If missing, add them and reboot.

**Step 4: Check Plymouth services**

```bash
sudo systemctl status plymouth-start.service
sudo systemctl status plymouth-quit.service
```

If failed, check logs:

```bash
sudo journalctl -u plymouth-start.service
```

**Step 5: Test in preview mode**

```bash
sudo plymouthd --debug --debug-file=/tmp/plymouth-debug.log
sudo plymouth show-splash
# Wait 10 seconds
sudo plymouth quit
cat /tmp/plymouth-debug.log
```

### Common Causes

1. Theme not set as default
2. Missing "quiet splash" in cmdline.txt
3. Plymouth service disabled
4. Graphics driver issues

### Solutions

**Solution 1: Reinstall theme**

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
sudo reboot
```

**Solution 2: Enable Plymouth services**

```bash
sudo systemctl enable plymouth-start.service
sudo systemctl enable plymouth-quit.service
sudo reboot
```

**Solution 3: Check graphics driver**

Ensure VC4 KMS driver is enabled in `/boot/config.txt` (read-only, check only):

```bash
cat /boot/config.txt | grep dtoverlay=vc4
```

## Problem: Images Rotated Incorrectly

### Symptom

Boot splash appears but is sideways, upside-down, or mirror-image.

### Diagnosis Steps

**Step 1: Check current rotation values**

```bash
# All parameters in cmdline.txt
cat /boot/cmdline.txt | grep -E "video=|rotate=|plymouth="
```

**Step 2: Verify rotation formula**

Calculate correct plymouth value:

```
plymouth_rotation = (360 - kernel_rotation) % 360
```

Examples:
- rotate=270 -> plymouth=90
- rotate=90 -> plymouth=270
- rotate=180 -> plymouth=180
- rotate=0 -> plymouth=0

**Step 3: Enable debug overlay**

Edit script to show rotation information:

```bash
sudo nano /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
```

Find line (around line 100):

```
enable_debug_overlay = (Window.GetWidth() < 0);
```

Change to:

```
enable_debug_overlay = (Window.GetWidth() > -1);
```

Rebuild and reboot:

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
sudo reboot
```

Debug overlay will show:
- FB: WxH (framebuffer dimensions)
- ROTATION: X (parsed plymouth value)
- MICRO: 0/1 (sequence type)

### Solutions

**Solution 1: Correct plymouth= value**

Edit `/boot/cmdline.txt` and update `plymouth=` parameter on the existing line:

```bash
sudo nano /boot/cmdline.txt
```

Try these values systematically:
- plymouth=0 (landscape, no rotation)
- plymouth=90 (portrait, 90 CW)
- plymouth=180 (upside-down)
- plymouth=270 (portrait, 270 CW)

**Solution 2: Correct rotate= value**

In the same file (`/boot/cmdline.txt`), update the `rotate=` value within the `video=` parameter:

```bash
sudo nano /boot/cmdline.txt
```

Ensure `rotate=` value matches your physical display orientation within the `video=` parameter.

Example: `video=HDMI-A-1:320x1480M@60,rotate=270`

**Solution 3: Regenerate images**

If images themselves are incorrect:

```bash
cd /path/to/theme/files
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
sudo plymouth-set-default-theme -R volumio-adaptive
```

## Problem: Only Micro Sequence on Large Display

### Symptom

Seeing 6-frame micro animation instead of 90-frame progress animation on large display.

### Diagnosis

Enable debug overlay (see above) and check displayed dimensions.

Micro sequence activates when: `(width <= 640) && (height <= 640)`

### Common Cause

For portrait displays (plymouth=90 or 270), script should swap dimensions but may not be detecting rotation correctly.

### Solution

**Step 1: Verify plymouth= parameter present**

```bash
cat /boot/cmdline.txt | grep plymouth=
```

If missing or set to 0 when it should be 90 or 270, correct it.

**Step 2: Check debug overlay**

Debug overlay shows actual vs effective dimensions. Verify rotation is detected correctly.

**Step 3: Manual script verification**

Check if ParsePlymouthRotation function is working:

```bash
sudo nano /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
```

Find ParsePlymouthRotation function and verify it's parsing correctly.

## Problem: Missing Images

### Symptom

Blank splash screen or error messages about missing images.

### Diagnosis

```bash
# Count files in each sequence directory
for dir in /usr/share/plymouth/themes/volumio-adaptive/sequence*/; do
  echo "$dir: $(ls -1 $dir | wc -l) files"
done
```

Each directory should have 97 files.

### Solutions

**Solution 1: Regenerate all sequences**

```bash
cd /path/to/theme/files
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
```

**Solution 2: Check source images**

Verify volumio-player theme has source images:

```bash
ls -la /usr/share/plymouth/themes/volumio-player/sequence/
```

Should contain progress-1.png through progress-90.png, micro-1.png through micro-6.png, and layout-constraint.png.

**Solution 3: Fix permissions**

```bash
sudo chown -R volumio:volumio /usr/share/plymouth/themes/volumio-adaptive
sudo chmod 644 /usr/share/plymouth/themes/volumio-adaptive/sequence*/*.png
```

## Problem: Animation Not Smooth

### Symptom

Animation stutters, skips frames, or appears choppy.

### Common Causes

1. System performance issues
2. Image file corruption
3. Memory constraints

### Solutions

**Solution 1: Verify all images intact**

```bash
# Check for corrupted PNG files
for dir in /usr/share/plymouth/themes/volumio-adaptive/sequence*/; do
  for img in $dir/*.png; do
    file "$img" | grep -v "PNG image" && echo "Corrupted: $img"
  done
done
```

**Solution 2: Increase GPU memory**

Edit `/boot/userconfig.txt`:

```bash
sudo nano /boot/userconfig.txt
```

Add or increase:

```
gpu_mem=128
```

**Solution 3: Use micro sequence**

On low-performance systems, micro sequence (6 frames) may be smoother than progress (90 frames).

## Problem: Plymouth Hangs at Shutdown

### Symptom

System hangs with Plymouth splash during shutdown.

### Solution

Check plymouth-quit service:

```bash
sudo systemctl status plymouth-quit.service
```

If problematic, disable quit splash:

```bash
sudo systemctl mask plymouth-quit.service
```

## Problem: Console Text Appears Over Splash

### Symptom

Kernel messages or console text overlays the Plymouth splash.

### Diagnosis

Check cmdline.txt for "quiet" parameter:

```bash
cat /boot/cmdline.txt | grep quiet
```

### Solution

Add "quiet" to cmdline.txt:

```bash
sudo nano /boot/cmdline.txt
```

Ensure line contains: `quiet splash`

## Problem: Configuration Changes Not Taking Effect

### Symptom

Edited configuration files but Plymouth still shows old behavior.

### Common Causes

1. Syntax errors in cmdline.txt (must be single line)
2. initramfs not rebuilt after theme changes (script edits only)

### Solutions

**Solution 1: Verify cmdline.txt syntax**

Check cmdline.txt is single line:

```bash
wc -l /boot/cmdline.txt
```

Should output: `1`

If multiple lines, edit to single line with space-separated parameters.

**Solution 2: Verify parameters added correctly**

```bash
cat /boot/cmdline.txt | grep -E "video=|rotate=|plymouth="
```

Ensure parameters are present and space-separated.

**Solution 3: Rebuild after theme changes**

If you edited the script itself:

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

For cmdline.txt changes only, just reboot - no rebuild needed.

## Problem: Debug Overlay Not Showing

### Symptom

Enabled debug overlay but not appearing on screen.

### Solutions

**Solution 1: Verify edit was saved**

```bash
grep "enable_debug_overlay" /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
```

Should show: `enable_debug_overlay = (Window.GetWidth() > -1);`

**Solution 2: Rebuild initramfs**

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
sudo reboot
```

**Solution 3: Check screen size**

Debug text may be off-screen on very small displays. Try larger display for testing.

## Problem: Theme Works in Preview but Not at Boot

### Symptom

`plymouth show-splash` works but nothing at boot.

### Diagnosis

Different environment between preview and actual boot.

### Solutions

**Solution 1: Check boot services**

```bash
sudo systemctl list-units | grep plymouth
```

Ensure plymouth-start.service is active.

**Solution 2: Check boot order**

Plymouth must start before console. Check service dependencies:

```bash
systemctl show plymouth-start.service
```

## Getting Help

If problems persist:

1. Collect debug information:
```bash
sudo plymouth-set-default-theme
cat /boot/cmdline.txt
cat /boot/userconfig.txt
ls -la /usr/share/plymouth/themes/volumio-adaptive/
systemctl status plymouth-start.service
```

2. Enable debug mode and capture log:
```bash
# Edit cmdline.txt: change nodebug->debug, quiet->noquiet, add plymouth.debug
sudo nano /boot/cmdline.txt
sudo reboot

# After boot, check logs:
dmesg | grep -i plymouth
cat /var/log/plymouth-debug.log
```

3. Report issue with collected information to Volumio development team.

## Common Error Messages

### "Theme has no script file"

**Cause**: volumio-adaptive.script missing or incorrect permissions

**Solution**:
```bash
ls -la /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
sudo chmod 644 /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
sudo plymouth-set-default-theme -R volumio-adaptive
```

### "Cannot find image: sequenceX/progress-Y.png"

**Cause**: Missing image directory or files

**Solution**: Regenerate sequences (see "Missing Images" section)

### "Script execution failed"

**Cause**: Syntax error in script

**Solution**: Check script syntax, compare with original, reinstall if needed

## Prevention Tips

1. Always backup configuration files before editing
2. Test changes in preview mode before rebooting
3. Make one change at a time
4. Document working configurations
5. Keep original theme files as backup
