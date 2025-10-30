# Technical Implementation Details

In-depth technical documentation for volumio-adaptive Plymouth theme

## Architecture Overview

The volumio-adaptive theme uses a multi-directory approach to support rotation without requiring initramfs rebuilds. The core innovation is runtime selection of pre-rotated image sequences based on a kernel command line parameter.

### Volumio Configuration Structure

Volumio uses a specific file hierarchy for boot configuration:

**`/boot/config.txt`** - Build process managed, do not modify
- System-level hardware configuration
- Managed by Volumio build scripts

**`/boot/volumioconfig.txt`** - Volumio defaults, do not modify
- Application-level Volumio settings
- System managed

**`/boot/userconfig.txt`** - User editable hardware configuration
- Contains: `dtoverlay`, `hdmi_group`, `hdmi_mode`, `hdmi_cvt`
- Hardware-level display settings
- Does NOT contain `video=` or `rotate=` parameters

**`/boot/cmdline.txt`** - User editable kernel parameters (single line)
- Contains: `video=`, `rotate=`, `plymouth=`, `fbcon=`
- All kernel command line parameters
- Must be single line, space-separated
- Where display rotation is configured

**Critical**: Display rotation (`video=`, `rotate=`) and Plymouth parameters (`plymouth=`) go in **cmdline.txt**, not userconfig.txt.

### Plymouth API Limitations (Critical Discovery)

**Problem**: Plymouth's command line parsing APIs are broken on Debian Bookworm/Volumio 4.x:

- `Plymouth.GetParameter()` - Returns NULL (cannot read parameters)
- `Plymouth.GetKernelCommandLine()` - Returns NULL (cannot read cmdline)
- `ReadFile("/proc/cmdline")` - Returns NULL (file I/O blocked)

**Impact**: Script cannot detect rotation parameter at runtime using Plymouth APIs.

**Root cause**: Plymouth security restrictions or API changes in recent versions prevent script access to kernel command line and file system.

**Attempted solutions** (all failed):
1. ParsePlymouthRotation() function using GetKernelCommandLine() - returned NULL
2. ReadFile("/proc/cmdline") - returned NULL
3. Plymouth.GetParameter("plymouth") - returned NULL

### Runtime Detection Solution

**Implementation**: Two-phase patching system that works OUTSIDE Plymouth:

**Phase 1 - Boot (Init-Premount Script)**:
1. Script runs in initramfs BEFORE Plymouth loads
2. Reads /proc/cmdline (available in early boot, before Plymouth restrictions)
3. Uses sed to patch plymouth_rotation value in script file
4. Plymouth loads already-patched script with correct rotation

**Phase 2 - Shutdown (Systemd Service)**:
1. Service runs at system startup
2. Patches installed script in /usr/share/plymouth/themes/
3. Ensures shutdown/reboot use correct rotation

**Key insight**: /proc/cmdline IS available in initramfs init-premount phase, but NOT available once Plymouth script executes. Solution: Patch the script before Plymouth loads it.

**Files**:
- `00-plymouth-rotation` - Init-premount script (boot phase)
- `plymouth-rotation.sh` - Systemd script (shutdown phase)
- `plymouth-rotation.service` - Service unit

**Advantages**:
- No initramfs rebuild needed for rotation changes
- Works with broken Plymouth APIs
- Compatible with Volumio OTA updates
- User only needs to edit cmdline.txt and reboot

**Disadvantage**:
- Requires one-time installation of runtime detection system
- Reboot required for rotation changes (cannot hot-swap)

See `runtime-detection/RUNTIME-DETECTION-INSTALL.md` for installation instructions.

### Core Components

1. **volumio-adaptive.script** - Plymouth script implementing rotation detection and dynamic image loading
2. **volumio-adaptive.plymouth** - Theme configuration defining ImageDir and script path
3. **generate-rotated-sequences.sh** - Offline image generation script
4. **sequence directories** - Pre-rotated image sets (0, 90, 180, 270)

### Data Flow

**With Runtime Detection** (recommended):
```
Boot starts
  |
  v
Initramfs init-premount phase
  |
  v
00-plymouth-rotation script reads /proc/cmdline
  |
  v
Script patches plymouth_rotation value in theme script
  |
  v
Plymouth reads volumio-adaptive.plymouth
  |
  v
Plymouth executes pre-patched volumio-adaptive.script
  |
  v
Script reads plymouth_rotation variable (already set correctly)
  |
  v
Script builds path: "sequence" + rotation + "/"
  |
  v
All Image() calls use selected directory
  |
  v
Appropriate rotation displayed
```

**Without Runtime Detection**:
```
Boot starts
  |
  v
Plymouth reads volumio-adaptive.plymouth
  |
  v
Plymouth executes volumio-adaptive.script
  |
  v
Script reads hardcoded plymouth_rotation value
  |
  v
Script builds path: "sequence" + rotation + "/"
  |
  v
All Image() calls use selected directory
  |
  v
Rotation displayed (must manually edit script for changes)
```

## Plymouth Script Engine

### Script Language

Plymouth uses a custom scripting language with these characteristics:

- Interpreted at boot time
- No string manipulation functions (manual parsing required)
- Limited mathematical operations
- No file I/O beyond Image() loading
- No external command execution

### Key Limitations

1. **No string search**: Cannot use indexOf(), find(), or similar
2. **Character-by-character only**: Must iterate manually through strings
3. **No regex**: Pattern matching not available
4. **Fixed functions**: Cannot define custom string utilities

### Available Functions

**Window Functions**:
- `Window.GetWidth()` - Returns framebuffer width in pixels
- `Window.GetHeight()` - Returns framebuffer height in pixels
- `Window.GetX()` - Returns window X position
- `Window.GetY()` - Returns window Y position

**Image Functions**:
- `Image(path)` - Load image from path relative to ImageDir
- `image.SetX(x)` - Set image X position
- `image.SetY(y)` - Set image Y position
- `image.SetZ(z)` - Set image Z-order (layering)

**Sprite Functions**:
- `Sprite()` - Create sprite object
- `sprite.SetImage(image)` - Assign image to sprite
- `sprite.SetX(x)` - Set sprite X position
- `sprite.SetY(y)` - Set sprite Y position
- `sprite.SetZ(z)` - Set sprite Z-order
- `sprite.SetOpacity(opacity)` - Set transparency (0.0-1.0)

**Text Functions**:
- `Image.Text(string, r, g, b)` - Create text image with RGB color
- Font automatically selected by Plymouth

**Plymouth Functions**:
- `Plymouth.GetKernelCommandLine()` - Returns complete kernel command line
- `Plymouth.SetRefreshRate(hz)` - Set screen refresh rate
- `Plymouth.SetUpdateFunction(callback)` - Set per-frame callback

## ParsePlymouthRotation Implementation

### Algorithm

The function searches for "plymouth=" in the kernel command line and extracts the numeric value following it.

### Pseudo-code

```
function ParsePlymouthRotation():
  cmdline = Plymouth.GetKernelCommandLine()
  
  for each character position in cmdline:
    if next 9 characters match "plymouth=":
      position += 9 (skip "plymouth=")
      value_string = ""
      
      while current character is digit:
        value_string += character
        position++
      
      return integer(value_string)
  
  return 0 (default)
```

### Implementation Notes

1. **Manual parsing required**: No built-in string search
2. **Character comparison**: Tests each position for "plymouth="
3. **Digit extraction**: Accumulates numeric characters
4. **Default fallback**: Returns 0 if parameter not found
5. **No validation**: Accepts any numeric value (user responsibility)

### Edge Cases Handled

- Parameter at start of line
- Parameter at end of line
- Parameter in middle with spaces on both sides
- Multiple digits (90, 180, 270)
- Missing parameter (returns 0)

### Edge Cases NOT Handled

- Non-numeric values (undefined behavior)
- Negative values (undefined behavior)
- Values > 360 (works but non-standard)

## Dynamic Image Loading

### Path Construction

Images are loaded using relative paths built at runtime:

```
image_subdir = "sequence" + plymouth_rotation + "/"
progress_image = Image(image_subdir + "progress-" + frame_number + ".png")
```

### ImageDir Resolution

The `.plymouth` file sets:

```
ImageDir=/usr/share/plymouth/themes/volumio-adaptive
```

All Image() paths are relative to this directory.

### Complete Path Examples

For `plymouth=90`:
```
ImageDir + "sequence90/" + "progress-1.png"
= /usr/share/plymouth/themes/volumio-adaptive/sequence90/progress-1.png
```

### Benefits of This Approach

1. **No file system queries**: All paths constructed, not discovered
2. **Predictable loading**: Same code path regardless of rotation
3. **Fast initialization**: No directory scanning needed
4. **Simple logic**: Single string concatenation per image

## Dimension Swapping Logic

### Purpose

Portrait orientations (90, 270) require swapping width and height for sequence selection logic to work correctly.

### Implementation

```
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

if (plymouth_rotation == 90 || plymouth_rotation == 270) {
  temp = screen_width;
  screen_width = screen_height;
  screen_height = temp;
}
```

### Why This Is Necessary

**Example**: 320x1480 portrait display with plymouth=90

- `Window.GetWidth()` returns 320 (physical framebuffer width)
- `Window.GetHeight()` returns 1480 (physical framebuffer height)
- Images in sequence90/ are 270x480 (rotated from 480x270)
- For micro sequence test `(width <= 640 && height <= 640)`:
  - WITHOUT swap: 320 <= 640 && 1480 <= 640 -> FALSE (wrong)
  - WITH swap: 1480 <= 640 && 320 <= 640 -> FALSE (correct)

The swap ensures sequence selection logic sees "logical" dimensions matching image orientation.

### Impact on Positioning

Positioning calculations use swapped dimensions:
```
center_x = screen_width / 2;
center_y = screen_height / 2;
```

This centers images correctly in the logical coordinate space.

## Sequence Selection Logic

### Micro vs Progress

Two animation sequences available:

**Micro**: 6 frames, simple animation
- Used for small displays
- Lower memory usage (~50KB)
- Simpler visual
- 20 ticks per frame

**Progress**: 90 frames, detailed animation
- Used for normal/large displays  
- Higher memory usage (~800KB)
- More detailed visual
- 3 ticks per frame

### Selection Criteria

```
if (screen_width <= 640 && screen_height <= 640) {
  use_micro = 1;
  frame_count = 6;
  ticks_per_frame = 20;
} else {
  use_micro = 0;
  frame_count = 90;
  ticks_per_frame = 3;
}
```

### Memory Considerations

**Progress sequence**:
- 90 images x ~9KB average = ~810KB

**Micro sequence**:
- 6 images x ~9KB average = ~54KB

All images loaded at initialization, held in memory throughout boot.

## Animation Timing

### Tick System

Plymouth calls the update function at regular intervals ("ticks"). Default rate is typically 50Hz (50 ticks/second).

### Frame Advancement

```
function refresh_callback() {
  tick_counter++;
  
  if (tick_counter >= ticks_per_frame) {
    tick_counter = 0;
    current_frame++;
    
    if (current_frame >= frame_count) {
      current_frame = 0;  // Loop
    }
    
    load_and_display_frame(current_frame);
  }
}
```

### Actual Frame Rates

**Micro sequence**:
- 20 ticks per frame
- At 50Hz: 50/20 = 2.5 FPS
- Full loop: 6 frames / 2.5 FPS = 2.4 seconds

**Progress sequence**:
- 3 ticks per frame
- At 50Hz: 50/3 = 16.67 FPS
- Full loop: 90 frames / 16.67 FPS = 5.4 seconds

## Debug Overlay

### Purpose

Shows runtime information for troubleshooting:
- Framebuffer dimensions
- Parsed rotation value
- Sequence type (micro/progress)

### Implementation

```
if (enable_debug_overlay) {
  debug_text = 
    "ADAPTIVE SCRIPT OK\n" +
    "FB: " + Window.GetWidth() + "x" + Window.GetHeight() + "\n" +
    "ROTATION: " + plymouth_rotation + "\n" +
    "MICRO: " + use_micro;
  
  debug_image = Image.Text(debug_text, 1, 1, 1);
  debug_sprite = Sprite(debug_image);
  debug_sprite.SetPosition(10, 10);
  debug_sprite.SetZ(1000);  // On top
}
```

### Control Variable

```
enable_debug_overlay = (Window.GetWidth() < 0);  // Disabled (never true)
enable_debug_overlay = (Window.GetWidth() > -1); // Enabled (always true)
```

Change condition to enable/disable.

### Display Format

```
ADAPTIVE SCRIPT OK
FB: 320x1480
ROTATION: 90
MICRO: 0
```

## Message System

### Purpose

Display boot messages (5-line scrolling log).

### Implementation

Inherited from volumio-player theme:

```
message_queue[5];  // Array of 5 message strings

function message_callback(text) {
  // Shift messages up
  for (i = 0; i < 4; i++) {
    message_queue[i] = message_queue[i+1];
  }
  message_queue[4] = text;
  
  // Redraw all messages
  for (i = 0; i < 5; i++) {
    message_images[i] = Image.Text(message_queue[i], 1, 1, 1);
    message_sprites[i].SetImage(message_images[i]);
  }
}

Plymouth.SetMessageFunction(message_callback);
```

### Font Selection

Plymouth automatically selects font based on:
1. Available system fonts
2. Screen resolution
3. Text length

Theme cannot control font selection directly.

### Small Screen Adaptation

For very small displays (width < 200), font may be too large. Plymouth has limited control over this.

## Image Generation Process

### Script: generate-rotated-sequences.sh

Uses ImageMagick to rotate images:

```bash
for rotation in 0 90 180 270; do
  mkdir -p "sequence$rotation/"
  
  for image in sequence/*.png; do
    if [ $rotation -eq 0 ]; then
      cp "$image" "sequence$rotation/"
    else
      convert "$image" -rotate $rotation "sequence$rotation/$(basename $image)"
    fi
  done
done
```

### ImageMagick Parameters

- `-rotate X` - Rotates image X degrees clockwise
- Preserves transparency
- Maintains PNG format
- No quality loss (lossless rotation)

### Rotation Angles

- **0**: Copy original (no rotation)
- **90**: 90 degrees clockwise
- **180**: 180 degrees (upside-down)
- **270**: 270 degrees clockwise (= 90 CCW)

### Output Validation

Script verifies:
- All files processed
- Correct file count per directory
- No ImageMagick errors

## Performance Characteristics

### Initialization Time

- Image loading: ~0.5-1 second (depends on storage speed)
- Script parsing: Negligible (<10ms)
- Total delay: ~1 second

### Runtime Overhead

- Per-frame: < 1ms (simple integer math)
- No file I/O during animation
- No memory allocation after initialization

### Memory Usage

**Progress sequence**:
- Script + data: ~50KB
- Images: ~800KB
- Total: ~850KB

**Micro sequence**:
- Script + data: ~50KB
- Images: ~50KB
- Total: ~100KB

### CPU Usage

Minimal:
- Simple sprite updates
- No complex calculations
- Hardware-accelerated compositing (if available)

## Compatibility Notes

### Plymouth Versions

Tested with Plymouth 0.9.x (standard in Raspberry Pi OS Bookworm).

### Graphics Drivers

**VC4 KMS** (recommended):
- Full acceleration
- Best performance
- Proper rotation support

**FKMS** (legacy):
- May work but not tested
- Potentially slower

**Framebuffer** (fbdev):
- Basic support
- No acceleration

### Raspberry Pi Models

**Tested**:
- Raspberry Pi 5
- Raspberry Pi 4

**Expected to work**:
- Raspberry Pi 3
- Raspberry Pi 400
- Raspberry Pi CM4

**Not tested**:
- Pi Zero (may be too slow)
- Pi 1/2 (likely too slow)

### Display Interfaces

**Supported**:
- HDMI (HDMI-A-1, HDMI-A-2)
- DSI (DSI-1)
- DPI (theoretically, not tested)

**Not supported**:
- Composite video (insufficient resolution)
- VGA through adapters (depends on adapter)

## Kernel Command Line Parsing

### Volumio cmdline.txt Structure

The `/boot/cmdline.txt` file contains all kernel parameters as a **single line** with space-separated parameters.

Example vanilla Volumio cmdline.txt:
```
splash plymouth.ignore-serial-consoles dwc_otg.fiq_enable=1 ... quiet ... nodebug use_kmsg=no
```

### Parameter Types

**Toggle Parameters** (change between values, don't add both):
- `debug` / `nodebug` - Kernel debug messages (view with dmesg)
- `splash` / `nosplash` - Plymouth enable/disable
- `quiet` / `noquiet` - Console message suppression

**Additional Parameters** (add to line):
- `video=HDMI-A-1:320x1480M@60,rotate=270` - Display configuration
- `plymouth=90` - Plymouth image selection
- `fbcon=map:10` - Framebuffer console mapping (optional, vendor-specific)
- `plymouth.debug` - Creates /var/log/plymouth-debug.log (debugging only)

### Console vs Plymouth Rotation

**`rotate=` parameter** (in `video=` specification):
- Affects kernel framebuffer console
- Rotates text console and graphics
- Does NOT affect Plymouth's view of framebuffer
- Plymouth sees raw, unrotated dimensions

**`plymouth=` parameter**:
- Tells volumio-adaptive theme which image directory to use
- Independent of `rotate=` parameter
- Both needed for correct rotated display

Example:
```
video=HDMI-A-1:320x1480M@60,rotate=270 plymouth=90
```
- Console rotates 270° CCW
- Plymouth loads images rotated 90° CW
- Result: Both correctly oriented

### Full Parameter Format

```
plymouth=90
```

### Parsing Context

The kernel command line is a single string with space-separated parameters:

```
console=serial0,115200 console=tty1 root=PARTUUID=xxx ... plymouth=90 quiet splash
```

### Why Manual Parsing Required

Plymouth script has no built-in parameter extraction. Must search character-by-character for "plymouth=" pattern.

### Alternative Approaches Considered

**Option 1: Fixed filename convention**
- Problem: Requires file renaming or symlinks
- Rejected: More complex, not dynamic

**Option 2: Separate .plymouth files per rotation**
- Problem: Still requires theme switch
- Rejected: Defeats purpose of single theme

**Option 3: Auto-detect from rotate= parameter**
- Problem: Cannot access kernel command line parameters other than plymouth=
- Rejected: Not feasible with Plymouth API

## Future Enhancement Possibilities

### Auto-detection

Read both `plymouth=` and `rotate=` parameters, apply formula automatically:

```
rotate_value = ParseParameter("rotate");
plymouth_value = (360 - rotate_value) % 360;
```

**Challenge**: Need to parse rotate= from video= parameter format.

### Arbitrary Angles

Support non-90-degree rotations:

**Challenge**: Image generation for arbitrary angles more complex (not lossless).

### Dynamic Image Generation

Generate rotations on-the-fly instead of pre-generating:

**Challenge**: Plymouth script cannot execute external commands or perform image manipulation.

### Configuration UI

Integration with Volumio web interface:

**Challenge**: Requires Volumio backend development, not just theme work.

## Security Considerations

### No User Input Validation

Theme trusts `plymouth=` parameter value. Malicious values could:
- Reference non-existent directories (fails gracefully, shows nothing)
- Use very large numbers (loads from sequenceXXXX/ if exists)

**Impact**: Low (worst case: no splash shown)

### No File System Access

Script cannot access files outside ImageDir. Cannot:
- Read sensitive files
- Write anywhere
- Execute commands

**Impact**: None (secure by design)

### initramfs Inclusion

Theme files included in initramfs (read-only). Cannot be modified at runtime.

**Impact**: Positive (tamper-resistant)

## Debugging Techniques

### Enable Script Tracing

Plymouth has limited debug output. Best approach:

1. Enable debug overlay (shows parsed values)
2. Test in preview mode with debug log
3. Add temporary text displays at key points

### Common Debug Points

```
# After ParsePlymouthRotation
debug_text = "Rotation: " + plymouth_rotation;

# After dimension swap
debug_text = "Dims: " + screen_width + "x" + screen_height;

# In frame update
debug_text = "Frame: " + current_frame + "/" + frame_count;
```

### Preview Mode Testing

Most effective debugging method:

```bash
sudo plymouthd --debug --debug-file=/tmp/plymouth-debug.log
sudo plymouth show-splash
# Observe behavior
sudo plymouth quit
cat /tmp/plymouth-debug.log
```

## References

- [Plymouth Script Reference](https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/)
- [Plymouth Source Code](https://gitlab.freedesktop.org/plymouth/plymouth)
- [Raspberry Pi Video Configuration](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [Kernel Framebuffer Documentation](https://www.kernel.org/doc/Documentation/fb/framebuffer.txt)

## Credits

Technical implementation: Nerd
Based on: volumio-player theme by Andrew Seredyn, Volumio Srl
Plymouth engine: Freedesktop.org
