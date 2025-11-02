# Troubleshooting Guide

Comprehensive troubleshooting for volumio-adaptive Plymouth theme

**THEME NOTE**: This guide is for volumio-adaptive theme which uses the `plymouth=` parameter. For volumio-text theme troubleshooting (which uses `video=...,rotate=` or `fbcon=rotate:` parameters), see the volumio-text documentation.

## Quick Diagnostic Checklist

Before diving into specific issues, run these quick checks:

```bash
# 1. Verify active theme
sudo plymouth-set-default-theme

# 2. Check theme-specific parameters in cmdline.txt
# For volumio-adaptive, should see plymouth= parameter
# For volumio-text, should see video=...,rotate= or fbcon=rotate:
cat /boot/cmdline.txt | grep -E "video=|rotate=|plymouth=|fbcon="

# 3. Verify image directories exist (volumio-adaptive only)
ls -d /usr/share/plymouth/themes/volumio-adaptive/sequence*/

# 4. Check Plymouth service status
systemctl status plymouth-start.service

# 5. If using runtime detection, verify scripts are installed
# NOTE: Runtime detection only applies to volumio-adaptive
ls -l /etc/initramfs-tools/scripts/init-premount/00-plymouth-rotation
ls -l /usr/local/bin/plymouth-rotation.sh
systemctl status plymouth-rotation.service
```

## Problem: Wrong Parameter for Theme Type

### Symptom

Parameters configured but Plymouth not rotating correctly or parameter seems ignored.

### Common Scenarios

**Scenario 1: Using plymouth= with volumio-text theme**

```bash
# Check active theme
sudo plymouth-set-default-theme
# Output: volumio-text

# Check cmdline.txt
cat /boot/cmdline.txt | grep plymouth=
# Shows: plymouth=90
```

**Problem**: volumio-text theme does not use plymouth= parameter. It relies on framebuffer rotation via video=...,rotate= or fbcon=rotate: parameters.

**Solution**:
```bash
# Edit cmdline.txt
sudo nano /boot/cmdline.txt

# REMOVE plymouth= parameter
# ENSURE video=...,rotate= or fbcon=rotate: is present
# Example correct configuration for volumio-text:
video=HDMI-A-1:320x1480M@60,rotate=270

# OR
fbcon=rotate:3

# Reboot
sudo reboot
```

**Scenario 2: Using video=...,rotate= only with volumio-adaptive theme**

```bash
# Check active theme
sudo plymouth-set-default-theme
# Output: volumio-adaptive

# Check cmdline.txt
cat /boot/cmdline.txt
# Shows: video=HDMI-A-1:320x1480M@60,rotate=270
# Missing: plymouth= parameter
```

**Problem**: volumio-adaptive theme requires plymouth= parameter to select pre-rotated image sequence. The video=...,rotate= parameter only rotates the console, not Plymouth images.

**Symptom**: Console text displays correctly rotated, but Plymouth splash appears in wrong orientation.

**Solution**:
```bash
# Edit cmdline.txt
sudo nano /boot/cmdline.txt

# ADD plymouth= parameter with correct value
# Formula: plymouth = (360 - rotate) % 360
# For rotate=270: plymouth=90
# Example correct configuration:
video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90

# Reboot
sudo reboot
```

### Parameter Usage By Theme

| Theme | Required Parameter | Optional Parameter | Effect |
|-------|-------------------|-------------------|--------|
| volumio-adaptive | plymouth=0 or 90 or 180 or 270 | video=...,rotate=N | Plymouth images rotate |
| volumio-text | video=...,rotate=N | - | Framebuffer rotates |
| volumio-text | fbcon=rotate:N | - | Framebuffer rotates (alt) |

### Verification Steps

**Step 1: Identify active theme**

```bash
sudo plymouth-set-default-theme
```

**Step 2: Verify parameter matches theme**

For volumio-adaptive:
```bash
cat /boot/cmdline.txt | grep plymouth=
# Should show: plymouth=0 or plymouth=90 or plymouth=180 or plymouth=270
```

For volumio-text:
```bash
cat /boot/cmdline.txt | grep -E "video=.*rotate=|fbcon=rotate:"
# Should show either video=...,rotate=N or fbcon=rotate:N
```

**Step 3: Correct mismatch**

If wrong parameter for theme type, edit cmdline.txt and add/remove parameters as needed.

## Problem: Runtime Detection Applied to Wrong Theme

### Symptom

Installed runtime detection but it has no effect or causes issues.

### Important: Runtime Detection Scope

**Runtime detection patches only volumio-adaptive theme**. It:
- Detects plymouth= parameter from cmdline.txt
- Patches volumio-adaptive.script at boot and shutdown
- Updates plymouth_rotation variable in script

**Runtime detection does NOT apply to volumio-text theme** because:
- volumio-text uses framebuffer rotation (system-level)
- No script variable to patch
- Rotation handled by kernel, not theme
- No runtime detection needed

### Diagnosis

```bash
# Check active theme
sudo plymouth-set-default-theme
```

**If output is "volumio-text"**:
- Runtime detection scripts serve no purpose
- They will not cause harm but provide no benefit
- Consider uninstalling to reduce complexity

**If output is "volumio-adaptive"**:
- Runtime detection should work as designed
- Follow "Runtime Detection Not Working" section if issues occur

### Solution for volumio-text Users

If using volumio-text and want to change rotation:

**Step 1: Edit cmdline.txt directly**
```bash
sudo nano /boot/cmdline.txt

# Update video=...,rotate= parameter
# Example for 270 degree rotation:
video=HDMI-A-1:320x1480M@60,rotate=270

# OR update fbcon=rotate: parameter
fbcon=rotate:3
```

**Step 2: Reboot**
```bash
sudo reboot
```

**No runtime detection needed** - kernel handles rotation directly.

## Problem: Runtime Detection Not Working

**NOTE**: This section applies only to volumio-adaptive theme users.

### Symptom

Changed plymouth= in cmdline.txt and rebooted, but wrong rotation still displays.

### Diagnosis Steps

**Step 1: Verify volumio-adaptive is active theme**

```bash
sudo plymouth-set-default-theme
```

Should output: `volumio-adaptive`

If shows `volumio-text`, runtime detection does not apply - see "Runtime Detection Applied to Wrong Theme" section above.

**Step 2: Verify runtime detection scripts are installed**

```bash
# Check init-premount script
ls -l /etc/initramfs-tools/scripts/init-premount/00-plymouth-rotation

# Check systemd script
ls -l /usr/local/bin/plymouth-rotation.sh

# Check service unit
ls -l /etc/systemd/system/plymouth-rotation.service
```

If missing, install from `runtime-detection/` directory (see RUNTIME-DETECTION-INSTALL.md).

**Step 3: Verify init-premount script is executable**

```bash
sudo chmod +x /etc/initramfs-tools/scripts/init-premount/00-plymouth-rotation
sudo update-initramfs -u
```

**Step 4: Check if script is in initramfs**

```bash
lsinitramfs /boot/initrd.img-$(uname -r) | grep 00-plymouth-rotation
```

Should show: `scripts/init-premount/00-plymouth-rotation`

If missing, rebuild initramfs:

```bash
sudo update-initramfs -u
```

**Step 5: Verify systemd service is enabled**

```bash
systemctl status plymouth-rotation.service
```

If not enabled:

```bash
sudo systemctl enable plymouth-rotation.service
sudo systemctl start plymouth-rotation.service
```

**Step 6: Check if rotation value is being patched**

```bash
# Check boot phase (initramfs)
sudo lsinitramfs /boot/initrd.img-$(uname -r) | \
  xargs -I {} sudo cpio -i --to-stdout {} < /boot/initrd.img-$(uname -r) 2>/dev/null | \
  grep "plymouth_rotation = "

# Check shutdown phase (installed script)
grep "plymouth_rotation = " /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
```

Should show current rotation value from cmdline.txt.

**Step 7: Test runtime detection manually**

```bash
# Test what value would be detected
grep -o "plymouth=[0-9]*" /proc/cmdline

# Manually run systemd script
sudo /usr/local/bin/plymouth-rotation.sh

# Check if script was patched
grep "plymouth_rotation = " /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
```

**Step 8: Check script syntax**

```bash
# Verify init-premount script
sudo sh -n /etc/initramfs-tools/scripts/init-premount/00-plymouth-rotation

# Verify systemd script
sudo bash -n /usr/local/bin/plymouth-rotation.sh
```

No output means syntax is correct. Errors indicate script corruption.

### Common Causes

1. **Scripts not installed**: Follow runtime-detection/RUNTIME-DETECTION-INSTALL.md
2. **Scripts not executable**: Run `chmod +x` on both scripts
3. **Init-premount not in initramfs**: Run `update-initramfs -u`
4. **Service not enabled**: Run `systemctl enable plymouth-rotation.service`
5. **Wrong rotation in cmdline.txt**: Verify plymouth= parameter exists
6. **Typo in script**: Re-copy from runtime-detection/ directory
7. **Wrong theme active**: Runtime detection only works with volumio-adaptive

## Problem: Plymouth Not Displaying at Boot

### Symptom

No boot splash appears, just blank screen or text console messages.

### Diagnosis Steps

**Step 1: Verify theme installation**

```bash
sudo plymouth-set-default-theme
```

Expected output: `volumio-adaptive` or `volumio-text`

If not, reinstall:

```bash
# For volumio-adaptive
sudo plymouth-set-default-theme -R volumio-adaptive

# For volumio-text
sudo plymouth-set-default-theme -R volumio-text
```

**Step 2: Check initramfs contains theme**

```bash
# For volumio-adaptive
lsinitramfs /boot/initrd.img-$(uname -r) | grep plymouth | grep volumio-adaptive

# For volumio-text
lsinitramfs /boot/initrd.img-$(uname -r) | grep plymouth | grep volumio-text
```

Should show multiple files from active theme.

If empty, rebuild initramfs:

```bash
# Replace with your active theme
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
# Replace with your theme
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

**NOTE**: This section applies primarily to volumio-adaptive theme.

### Symptom

Boot splash appears but is sideways, upside-down, or mirror-image.

### Diagnosis Steps

**Step 1: Verify active theme**

```bash
sudo plymouth-set-default-theme
```

**Step 2: Check rotation parameters**

```bash
# All parameters in cmdline.txt
cat /boot/cmdline.txt | grep -E "video=|rotate=|plymouth=|fbcon="
```

**For volumio-adaptive theme**:
- Should have plymouth= parameter
- May also have video=...,rotate= for console rotation
- plymouth= controls Plymouth image selection
- rotate= controls console rotation

**For volumio-text theme**:
- Should have video=...,rotate= or fbcon=rotate: parameter
- Should NOT have plymouth= parameter
- Rotation controlled by framebuffer

**Step 3: Verify rotation formula (volumio-adaptive only)**

Calculate correct plymouth value:

```
plymouth_rotation = (360 - kernel_rotation) % 360
```

Examples:
- rotate=270 -> plymouth=90
- rotate=90 -> plymouth=270
- rotate=180 -> plymouth=180
- rotate=0 -> plymouth=0

**Step 4: Enable debug overlay (volumio-adaptive only)**

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

**Solution 1 (volumio-adaptive): Correct plymouth= value**

Edit `/boot/cmdline.txt` and update `plymouth=` parameter on the existing line:

```bash
sudo nano /boot/cmdline.txt
```

Try these values systematically:
- plymouth=0 (landscape, no rotation)
- plymouth=90 (portrait, 90 CW)
- plymouth=180 (upside-down)
- plymouth=270 (portrait, 270 CW)

**Solution 2 (volumio-text): Correct framebuffer rotation**

Edit `/boot/cmdline.txt` and update rotation parameter:

```bash
sudo nano /boot/cmdline.txt
```

Try video= parameter:
```
video=HDMI-A-1:WIDTHxHEIGHTM@60,rotate=0   # No rotation
video=HDMI-A-1:WIDTHxHEIGHTM@60,rotate=90  # 90 CW
video=HDMI-A-1:WIDTHxHEIGHTM@60,rotate=180 # 180
video=HDMI-A-1:WIDTHxHEIGHTM@60,rotate=270 # 270 CW
```

Or fbcon= parameter:
```
fbcon=rotate:0  # No rotation
fbcon=rotate:1  # 90 CW
fbcon=rotate:2  # 180
fbcon=rotate:3  # 270 CW
```

**Solution 3 (volumio-adaptive only): Regenerate images**

If images themselves are incorrect:

```bash
cd /path/to/theme/files
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
sudo plymouth-set-default-theme -R volumio-adaptive
```

## Problem: Only Micro Sequence on Large Display

**NOTE**: This section applies only to volumio-adaptive theme. volumio-text does not use image sequences.

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

**NOTE**: This section applies only to volumio-adaptive theme. volumio-text generates text dynamically.

### Symptom

Blank splash screen or error messages about missing images.

### Diagnosis

```bash
# Count files in each sequence directory
for dir in /usr/share/plymouth/themes/volumio-adaptive/sequence*/; do
  echo "$dir: $(ls -1 $dir | wc -l) files"
done
```

Each directory should have 123 files (97 animation frames + 26 message overlays).

### Solutions

**Solution 1: Regenerate animation sequences**

```bash
cd /path/to/theme/files
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
```

**Solution 1b: Generate message overlays (v1.02)**

If animation frames exist but overlays are missing:

```bash
cd /path/to/theme/files
./generate-overlays.sh

# Then copy to installed theme
for seq in 0 90 180 270; do
  sudo cp sequence${seq}/overlay-*.png \
    /usr/share/plymouth/themes/volumio-adaptive/sequence${seq}/
done

# Rebuild initramfs
sudo plymouth-set-default-theme -R volumio-adaptive
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

## Problem: Boot Messages Not Displaying (v1.02)

**NOTE**: This section applies only to volumio-adaptive v1.02 with message overlay system.

### Symptom

Logo animation displays correctly but Volumio boot messages do not appear during startup.

### Diagnosis Steps

**Step 1: Verify overlay files exist**

```bash
# Check for overlay files
ls /usr/share/plymouth/themes/volumio-adaptive/sequence0/overlay-*.png | wc -l
# Should show: 26

# Check all rotations
ls /usr/share/plymouth/themes/volumio-adaptive/sequence*/overlay-*.png | wc -l
# Should show: 104
```

**Step 2: Test message display manually**

```bash
sudo plymouthd --debug --debug-file=/tmp/plymouth-debug.log
sudo plymouth --show-splash
sudo plymouth message --text="Player prepared, please wait for startup to finish"
# Wait 5 seconds - overlay should appear
sudo plymouth quit

# Check debug log
cat /tmp/plymouth-debug.log | grep -i message
```

**Step 3: Verify script version**

```bash
grep "GetOverlayFilename" /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
# Should return matching lines - function exists in v1.02
```

**Step 4: Check pattern matching**

Enable debug overlay and check if messages trigger pattern matching:

```bash
sudo nano /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
# Change: enable_debug_overlay = (Window.GetWidth() < 0);
# To: enable_debug_overlay = (Window.GetWidth() > -1);

sudo plymouth-set-default-theme -R volumio-adaptive
sudo reboot
```

### Common Causes

**Cause 1: Missing overlay files**

Solution: Run `generate-overlays.sh` and copy files to theme directory (see above).

**Cause 2: Wrong script version**

If script doesn't have `GetOverlayFilename()` function, you're running v1.0 script:

```bash
# Check version
head -1 /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
# Should show: "...with rotation and overlay messages"
```

Solution: Replace with v1.02 script and rebuild initramfs:

```bash
sudo cp volumio-adaptive.script /usr/share/plymouth/themes/volumio-adaptive/
sudo plymouth-set-default-theme -R volumio-adaptive
```

**Cause 3: Message text doesn't match patterns**

If Volumio sends messages with unexpected formatting, pattern matching may fail.

Solution: Check actual message text in debug log and add pattern to `GetOverlayFilename()` function.

**Cause 4: File permissions**

```bash
# Fix permissions
sudo chmod 644 /usr/share/plymouth/themes/volumio-adaptive/sequence*/overlay-*.png
```

### Solutions

**Complete overlay system installation:**

```bash
# 1. Generate overlays
cd /path/to/volumio-adaptive
./generate-overlays.sh

# 2. Verify generation
ls sequence0/overlay-*.png | wc -l
# Should show: 26

# 3. Copy to installed theme
for seq in 0 90 180 270; do
  sudo cp sequence${seq}/overlay-*.png \
    /usr/share/plymouth/themes/volumio-adaptive/sequence${seq}/
done

# 4. Verify installation
ls /usr/share/plymouth/themes/volumio-adaptive/sequence*/overlay-*.png | wc -l
# Should show: 104

# 5. Rebuild initramfs
sudo plymouth-set-default-theme -R volumio-adaptive

# 6. Reboot and test
sudo reboot
```

## Problem: Overlay Generation Fails (v1.02)

### Symptom

`generate-overlays.sh` script fails with errors or produces no files.

### Diagnosis

```bash
# Test ImageMagick availability
which convert
# Should show: /usr/bin/convert

# Test convert functionality
convert -version
# Should show ImageMagick version info

# Check bash version (needs associative arrays)
bash --version
# Should be 4.0 or higher

# Check bc availability (for math)
which bc
# Should show: /usr/bin/bc
```

### Common Causes

**Cause 1: ImageMagick not installed**

```bash
# Install ImageMagick
sudo apt-get update
sudo apt-get install imagemagick
```

**Cause 2: Font not available**

Script uses Liberation-Sans font:

```bash
# Check available fonts
convert -list font | grep -i liberation
# Or try alternative
convert -list font | grep -i dejavu
```

Solution: Edit `generate-overlays.sh` and change font:

```bash
# Change line:
-font Liberation-Sans
# To:
-font DejaVu-Sans
```

**Cause 3: bc not installed**

```bash
sudo apt-get install bc
```

**Cause 4: Permission denied**

```bash
# Make script executable
chmod +x generate-overlays.sh

# Run from theme directory
cd /path/to/volumio-adaptive
./generate-overlays.sh
```

**Cause 5: Sequence directories don't exist**

Script requires sequence directories to exist first:

```bash
# Create directories if missing
mkdir -p sequence0 sequence90 sequence180 sequence270

# Then generate animations
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  .

# Then generate overlays
./generate-overlays.sh
```

### Solutions

**Full regeneration procedure:**

```bash
cd /path/to/volumio-adaptive

# 1. Ensure dependencies
sudo apt-get install imagemagick bc

# 2. Create directories
mkdir -p sequence0 sequence90 sequence180 sequence270

# 3. Generate animations first
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  .

# 4. Generate overlays
./generate-overlays.sh

# 5. Verify both
ls sequence0/*.png | wc -l
# Should show: 123 (97 animations + 26 overlays)

# 6. Check overlay count specifically
ls sequence0/overlay-*.png | wc -l
# Should show: 26
```

## Problem: Wrong Overlay Size Displayed (v1.02)

### Symptom

Overlay text appears too large or too small for display size.

### Diagnosis

Check which size variant is being selected:

```bash
# Enable debug overlay
sudo nano /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
# Change: enable_debug_overlay = (Window.GetWidth() < 0);
# To: enable_debug_overlay = (Window.GetWidth() > -1);

sudo plymouth-set-default-theme -R volumio-adaptive
sudo reboot

# Debug overlay will show "FB: WxH" (framebuffer dimensions)
```

### Adaptive Sizing Logic

- Smallest dimension >= 400px: Uses large overlays (16pt font)
- Smallest dimension < 400px: Uses compact overlays (12pt font)

**Examples:**
- 1920x1080: smallest=1080 -> large
- 1480x320: smallest=320 -> compact
- 800x600: smallest=600 -> large

### Solutions

**Issue: Text too large on small display**

Manually force compact overlays by editing script:

```plymouth
# Find line (around line 184):
if (smaller_dimension < 400) {
  overlay_size_suffix = "-compact";
} else {
  overlay_size_suffix = "";
}

# Change to always use compact:
overlay_size_suffix = "-compact";
```

**Issue: Text too small on large display**

Force large overlays:

```plymouth
# Change to always use large:
overlay_size_suffix = "";
```

**Issue: Want custom breakpoint**

Change 400 to desired pixel value:

```plymouth
if (smaller_dimension < 600) {  # Changed from 400
  overlay_size_suffix = "-compact";
}
```

After editing, rebuild:

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

## Problem: Overlay Appears But Logo Missing (v1.02)

### Symptom

Message overlay displays correctly but Volumio logo animation is not visible underneath.

### Cause

Z-index issue or animation not loading.

### Diagnosis

```bash
# Check if animation files exist
ls /usr/share/plymouth/themes/volumio-adaptive/sequence0/progress-*.png | wc -l
# Should show: 90

# Check for micro sequence
ls /usr/share/plymouth/themes/volumio-adaptive/sequence0/micro-*.png | wc -l
# Should show: 6
```

### Solution

**If animation files missing:**

```bash
./generate-rotated-sequences.sh \
  /usr/share/plymouth/themes/volumio-player/sequence \
  /usr/share/plymouth/themes/volumio-adaptive
```

**If files exist but not displaying:**

Check Z-index in script:

```bash
grep "logo_sprite.SetZ" /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
# Should show: logo_sprite.SetZ(1);

grep "message_overlay_sprite.SetZ" /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
# Should show: message_overlay_sprite.SetZ(2);
```

Logo must be Z=1, overlay must be Z=2. If reversed, reinstall v1.02 script.

## Problem: Animation Not Smooth

**NOTE**: This section applies only to volumio-adaptive theme. volumio-text does not use animation sequences.

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
3. Wrong theme active

### Solutions

**Solution 1: Verify active theme**

```bash
sudo plymouth-set-default-theme
```

Ensure correct theme is active.

**Solution 2: Verify cmdline.txt syntax**

Check cmdline.txt is single line:

```bash
wc -l /boot/cmdline.txt
```

Should output: `1`

If multiple lines, edit to single line with space-separated parameters.

**Solution 3: Verify parameters added correctly**

```bash
cat /boot/cmdline.txt | grep -E "video=|rotate=|plymouth=|fbcon="
```

Ensure parameters are present and space-separated.

**Solution 4: Rebuild after theme changes**

If you edited the script itself:

```bash
sudo plymouth-set-default-theme -R volumio-adaptive
```

For cmdline.txt changes only, just reboot - no rebuild needed.

## Problem: Debug Overlay Not Showing

**NOTE**: This section applies only to volumio-adaptive theme.

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
ls -la /usr/share/plymouth/themes/volumio-text/
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

**Cause**: Theme script missing or incorrect permissions

**Solution**:
```bash
# For volumio-adaptive
ls -la /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
sudo chmod 644 /usr/share/plymouth/themes/volumio-adaptive/volumio-adaptive.script
sudo plymouth-set-default-theme -R volumio-adaptive

# For volumio-text
ls -la /usr/share/plymouth/themes/volumio-text/volumio-text.script
sudo chmod 644 /usr/share/plymouth/themes/volumio-text/volumio-text.script
sudo plymouth-set-default-theme -R volumio-text
```

### "Cannot find image: sequenceX/progress-Y.png"

**NOTE**: This error only applies to volumio-adaptive theme.

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
6. Verify active theme before troubleshooting
7. Use correct parameters for active theme type
8. Remember runtime detection only applies to volumio-adaptive

## Theme-Specific Quick Reference

### volumio-adaptive
- Uses: plymouth= parameter (0, 90, 180, 270)
- Images: Pre-rotated sequences in sequence0/, sequence90/, etc.
- Messages: Transparent overlay system (v1.02, 13 messages)
- Overlay count: 26 files per sequence (104 total)
- Runtime detection: Supported and recommended
- Debug overlay: Available
- Parameter location: /boot/cmdline.txt
- File count: 123 per sequence (97 animations + 26 overlays)

### volumio-text
- Uses: video=...,rotate= or fbcon=rotate: parameters
- Images: None (dynamic text rendering)
- Runtime detection: Not applicable
- Debug overlay: Not available
- Parameter location: /boot/cmdline.txt
