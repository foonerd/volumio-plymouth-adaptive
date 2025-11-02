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
- Contains: `video=`, `plymouth=`, `fbcon=`
- All kernel command line parameters
- Must be single line, space-separated
- Where display rotation is configured
- `plymouth=` parameter is for volumio-adaptive theme
- `video=...,rotate=` or `fbcon=rotate:` is for volumio-text theme

**Critical**: Display rotation and Plymouth parameters go in **cmdline.txt**, not userconfig.txt. Different themes use different parameters.

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

### Plymouth Text Rotation Limitation (Critical Discovery)

**Problem**: Plymouth Script API does not support rotating text images.

- No `Image.Rotate()` function exists in Plymouth Script API
- `Image.Text()` creates horizontal text only
- Dynamic text cannot be rotated at runtime
- Only pre-rendered static images can be rotated

**Evidence**: volumio-player-ccw theme (line 122-124) disables text messages with comment: "plymouth is unable to rotate properly in init"

**Impact**: This limitation directly affects theme design:
- Image-based themes (volumio-adaptive): Use pre-rotated image sequences (works)
- Text-based themes (volumio-text): Must rely on framebuffer rotation (different approach)

### Dual-Theme Rotation Approaches

**volumio-adaptive** (Image-based):
- Uses `plymouth=` parameter for theme-level rotation
- Pre-rotated image sequences for all orientations
- Runtime detection patches `plymouth_rotation` variable
- Script selects correct image sequence directory
- Works because images are pre-rotated static content

**volumio-text** (Text-based):
- Uses `video=...,rotate=` or `fbcon=rotate:` parameters
- System-level framebuffer rotation
- No theme script patching needed
- Framebuffer handles rotation automatically
- Required because Plymouth cannot rotate text images

**Summary**: Different themes, different methods. Both work for their specific use cases.

### Message Overlay System Architecture (v1.02)

**Version**: 1.02 introduces transparent message overlay system for boot messages.

**Problem Statement**: Plymouth boot messages need to be displayed at all rotation angles, but Plymouth Script API limitations prevent dynamic text rotation:

1. No `Image.Rotate()` function exists
2. `Image.Text()` creates only horizontal text
3. Rotating text images produces severe clipping artifacts
4. Dynamic text rotation is impossible at runtime

**Solution**: Pre-rendered transparent PNG overlays with pattern matching.

#### Design Rationale

**Why NOT Dynamic Text Rendering:**

Attempted approaches that failed:
1. `Image.Text().Rotate()` - Function does not exist
2. Creating text then rotating - Produces severe clipping (text cuts off at edges)
3. Coordinate transformation - Cannot transform individual glyphs
4. Canvas rotation - No canvas API in Plymouth Script

**Evidence**: volumio-player-ccw theme explicitly disables messages (line 122-124) with comment: "plymouth is unable to rotate properly in init"

**Why Transparent Overlays Work:**

1. Pre-rendered images guarantee perfect text quality
2. Transparency preserves logo visibility
3. No runtime rotation needed
4. Works universally across all display configurations
5. Simple pattern matching for message detection

#### Architecture Components

**1. Z-Index Layering System**

```
Z-index 0: Background (debug only, when enabled)
Z-index 1: Logo animation sprite (progress or micro sequence)
Z-index 2: Message overlay sprite (transparent PNG with text)
Z-index 9999: Debug text overlay (when enabled)
```

**Key principle**: Logo renders BELOW overlay, visible through transparent areas.

**2. Overlay Image Structure**

Directory layout:
```
sequence0/
  progress-*.png         (animation frames)
  micro-*.png           (animation frames)
  overlay-*.png         (message overlays - large)
  overlay-*-compact.png (message overlays - small)

sequence90/  (same structure)
sequence180/ (same structure)
sequence270/ (same structure)
```

**Total**: 26 overlay files per sequence × 4 rotations = 104 overlay images

**3. Message Pattern Matching**

Function: `GetOverlayFilename(message_text)`

**Purpose**: Map Volumio boot messages to overlay filenames using substring matching.

**Why Pattern Matching:**
- Messages may contain variables (version numbers, timeouts)
- OEM builds may customize message text
- Need robust matching across Volumio variants

**Example**:
```plymouth
# Actual message from Volumio:
"Version 3.569 prepared, please wait for startup to finish"

# Pattern match:
if (StringContains(message_text, "prepared, please wait for startup to finish"))
    return "overlay-player-prepared";
```

Matches on common substring, ignores version variable.

**Supported Messages** (13 total):

1. "Player preparing startup"
2. "Finishing storage preparations"
3. "prepared, please wait for startup to finish" (with version variable)
4. "Player re-starting now"
5. "Receiving player update from USB"
6. "Player update from USB completed"
7. "Remove USB used for update"
8. "Performing factory reset"
9. "Performing player update"
10. "Success, player restarts"
11. "Expanding internal storage"
12. "Waiting for USB devices"
13. "Player internal" (parameters update message)

**4. Adaptive Sizing System**

**Breakpoint**: 400 pixels (smallest dimension)

**Formula**:
```plymouth
smaller_dimension = Window.GetWidth();
if (Window.GetHeight() < smaller_dimension) {
  smaller_dimension = Window.GetHeight();
}

if (smaller_dimension < 400) {
  overlay_size_suffix = "-compact";
} else {
  overlay_size_suffix = "";
}
```

**Size Variants**:
- **Large overlays**: 16pt font, used when smallest dimension ≥ 400px
- **Compact overlays**: 12pt font, used when smallest dimension < 400px

**Examples**:
- 1920×1080 display: smallest=1080 → large overlays
- 1480×320 display: smallest=320 → compact overlays
- 640×480 display: smallest=480 → large overlays

**Why smallest dimension**: Works correctly regardless of native orientation (portrait or landscape).

**5. Overlay Loading Flow**

```
Plymouth.SetMessageFunction(message_callback)
  |
  v
message_callback(text) receives message
  |
  v
GetOverlayFilename(text) - pattern matching
  |
  v
overlay_filename found or ""
  |
  v
IF filename != "":
  overlay_path = image_subdir + overlay_filename + overlay_size_suffix + ".png"
  Example: "sequence0/overlay-player-prepared.png"
  |
  v
  Image(overlay_path) - load overlay
  |
  v
  Center overlay in framebuffer
  |
  v
  message_overlay_sprite.SetOpacity(1) - show overlay
ELSE:
  message_overlay_sprite.SetOpacity(0) - hide overlay
```

**6. Helper Functions**

**StringLength(string)**:
- Counts characters in string
- Used by StringContains for bounds checking
- Returns integer count

**StringContains(haystack, needle)**:
- Substring matching function
- Returns 1 if needle found in haystack, 0 otherwise
- Implements sliding window comparison
- Case-sensitive matching

**GetOverlayFilename(message_text)**:
- Maps message text to overlay filename
- Uses StringContains for pattern matching
- Returns filename string or empty string ""
- Handles 13 Volumio message patterns

#### Technical Specifications

**Overlay Image Format**:
- Format: PNG with alpha channel
- Background: Fully transparent (alpha=0)
- Text: White (RGB 255,255,255, alpha=255)
- Anti-aliasing: Enabled for smooth text

**Dimensions**:
- **sequence0/180** (landscape):
  - Width: 480-683 pixels (varies by message length)
  - Height: 380 pixels (large), 322 pixels (compact)
  
- **sequence90/270** (portrait):
  - Width: 380 pixels (large), 320 pixels (compact)
  - Height: 480-683 pixels (varies by message length)

**Dynamic Width Calculation**:
```bash
# In generate-overlays.sh
text_length=${#message_text}
text_width_needed=$(echo "$FONT_SIZE * 0.6 * $text_length" | bc)
text_width_with_margin=$((text_width_needed + 40))

if [ $text_width_with_margin -gt 480 ]; then
    WIDTH=$text_width_with_margin
else
    WIDTH=480
fi
```

**Font Specifications**:
- Font family: Liberation-Sans (DejaVu-Sans fallback)
- Size (large): 16pt
- Size (compact): 12pt
- Color: White
- Weight: Regular

#### Performance Characteristics

**Memory Usage**:
- Each overlay: ~3-5 KB (PNG with transparency)
- Total overlays in memory: 0 KB (loaded on-demand, one at a time)
- Animation frames: ~800 KB (progress) or ~50 KB (micro)
- Combined: ~800-850 KB peak memory

**Loading Performance**:
- Overlay loading: <10ms per image
- Pattern matching: <1ms (string operations)
- No pre-loading: Overlays loaded only when message displayed
- Sprite reuse: Single message_overlay_sprite reused for all messages

**CPU Impact**:
- Pattern matching: Negligible (simple string comparison)
- Image loading: One-time per message display
- No continuous processing: Overlay shown until next message
- Z-index rendering: Hardware-accelerated by Plymouth/DRM

#### Integration with Animation System

**Simultaneous Rendering**:
```
Frame N:
  1. logo_sprite renders animation frame (Z=1)
  2. message_overlay_sprite renders overlay (Z=2)
  3. Compositor blends: logo → overlay (transparent areas show logo)
```

**Animation Continues**:
- Logo animation progresses regardless of overlay state
- refresh_callback() updates logo_sprite independently
- message_callback() updates message_overlay_sprite independently
- No interference between logo and overlay rendering

**Sprite Independence**:
- `logo_sprite`: Controlled by refresh_callback(), Z=1
- `message_overlay_sprite`: Controlled by message_callback(), Z=2
- Separate image loading
- Separate positioning
- Separate opacity control

#### Comparison with V1.0 (Text Scrolling)

**V1.0 Implementation** (removed in v1.02):
- Used `Image.Text()` for dynamic text rendering
- Text scrolling with line wrapping
- Z-index 10000 (above logo)
- Black background behind text
- No rotation support (horizontal text only)

**V1.02 Implementation** (current):
- Uses pre-rendered transparent PNG overlays
- No scrolling (static display)
- Z-index 2 (above logo but lower than v1.0)
- Transparent background (logo visible)
- Full rotation support (4 orientations)

**Key Improvements**:
- Messages visible at all rotation angles
- Logo remains visible through transparency
- Consistent text quality (no rendering artifacts)
- Pattern matching handles message variations
- Adaptive sizing for different displays

**Trade-offs**:
- Fixed message set (13 messages)
- No dynamic message composition
- Requires 104 pre-rendered images
- +312 KB storage for overlays

#### Generation and Customization

**Overlay Generation Script**: `generate-overlays.sh`

**Requirements**:
- ImageMagick (convert command)
- bash with associative arrays
- bc (for floating-point math)

**Generation Process**:
```bash
./generate-overlays.sh
# Creates 104 PNG files in sequence directories
# 13 messages × 2 sizes × 4 rotations = 104 files
```

**Customization**:

1. **Add new message**:
   ```bash
   # Edit generate-overlays.sh
   MESSAGES["new-message"]="Your new message text"
   
   # Edit volumio-adaptive.script
   if (StringContains(message_text, "Your new message"))
       return "overlay-new-message";
   ```

2. **Change font**:
   ```bash
   # Edit generate-overlays.sh
   -font Liberation-Sans
   # Change to desired font
   ```

3. **Adjust sizes**:
   ```bash
   # Edit generate-overlays.sh
   FONT_SIZE=16  # Change large size
   FONT_SIZE=12  # Change compact size
   ```

4. **Regenerate**:
   ```bash
   ./generate-overlays.sh
   sudo cp sequence*/overlay-*.png /usr/share/plymouth/themes/volumio-adaptive/sequence*/
   sudo plymouth-set-default-theme -R volumio-adaptive
   ```

#### Debugging Overlay System

**Enable Debug Overlay**:
```plymouth
enable_debug_overlay = (Window.GetWidth() > -1);  // Always true
```

**Debug Information Displayed**:
- "ADAPTIVE SCRIPT OK" - Script loaded
- "FB: WxH" - Framebuffer dimensions
- "ROTATION: X" - Detected rotation
- "MICRO: 0/1" - Sequence type

**Test Message Display**:
```bash
sudo plymouthd --debug
sudo plymouth --show-splash
sudo plymouth message --text="Player prepared, please wait for startup to finish"
# Wait to see overlay
sudo plymouth quit
```

**Check Overlay Files**:
```bash
ls /usr/share/plymouth/themes/volumio-adaptive/sequence0/overlay-*.png | wc -l
# Should show: 26

ls /usr/share/plymouth/themes/volumio-adaptive/sequence*/overlay-*.png | wc -l
# Should show: 104
```

**Verify Pattern Matching**:
- Check Plymouth debug log: `/tmp/plymouth-debug.log`
- Search for message_callback execution
- Verify GetOverlayFilename returns expected filename

#### Limitations and Known Issues

**1. Fixed Message Set**:
- Only 13 predefined messages supported
- New messages require code modification + regeneration
- Cannot handle arbitrary dynamic messages

**2. Storage Requirements**:
- 104 overlay images: ~312 KB
- Total theme storage: ~3-4 MB (animations + overlays)
- Not suitable for extremely storage-constrained systems

**3. Pattern Matching Constraints**:
- Case-sensitive matching
- Requires exact substring match
- Messages with unexpected formatting may not match
- No regex or wildcard support

**4. No Message Queueing**:
- Only one message displayed at a time
- New message replaces previous immediately
- No message history or scrollback

**5. Plymouth Script Limitations**:
- Cannot dynamically compose overlays
- Cannot adjust text color or effects at runtime
- Cannot animate overlay transitions
- No fade-in/fade-out effects

#### Future Enhancement Possibilities

**Within Current Architecture**:
- Add more message patterns (requires regeneration)
- Adjust font sizes or styles (requires regeneration)
- Customize text positioning in overlays (requires regeneration)
- Add message priority system (code change only)

**Requires Architecture Change**:
- Dynamic message composition (impossible - Plymouth API limitation)
- Text color changes (impossible - pre-rendered)
- Message animation (possible but complex)
- Multiple simultaneous messages (possible with more sprites)

#### Cross-Platform Compatibility

**Tested Platforms**:
- Raspberry Pi OS Bookworm (ARM)
- Volumio 4.x (ARM)
- Works on amd64 (Intel/AMD systems)

**Display Compatibility**:
- FHD (1920×1080): Large overlays
- QHD (2560×1440): Large overlays
- 1480×320 (Waveshare): Compact overlays
- 640×480: Large overlays
- Portrait and landscape orientations

**Plymouth Versions**:
- Tested: Plymouth 22.02 (Debian Bookworm)
- Should work: Any Plymouth with Script plugin
- Requirement: DRM/KMS support for transparency

#### Summary

V1.02 message overlay system provides:
- Reliable boot message display at all rotation angles
- Logo visibility through transparency
- OEM-compatible pattern matching
- Adaptive sizing for various displays
- Minimal performance impact
- Simple customization through shell script

Trade-off: Pre-rendered approach requires storage and fixed message set, but eliminates 


### Runtime Detection Solution

**Implementation**: Two-phase patching system for volumio-adaptive theme.

**Note**: Runtime detection is ONLY for volumio-adaptive theme. volumio-text uses framebuffer rotation and does not require runtime patching.

**Phase 1 - Boot (Init-Premount Script)**:
1. Script runs in initramfs BEFORE Plymouth loads
2. Reads /proc/cmdline (available in early boot, before Plymouth restrictions)
3. Detects `plymouth=` parameter
4. Uses sed to patch `plymouth_rotation` value in volumio-adaptive.script
5. Plymouth loads already-patched script with correct rotation

**Phase 2 - Shutdown (Systemd Service)**:
1. Service runs at system startup
2. Patches volumio-adaptive.script in /usr/share/plymouth/themes/
3. Ensures shutdown/reboot use correct rotation

**Key insight**: /proc/cmdline IS available in initramfs init-premount phase, but NOT available once Plymouth script executes. Solution: Patch volumio-adaptive.script before Plymouth loads it.

**Files**:
- `00-plymouth-rotation` - Init-premount script (patches volumio-adaptive only)
- `plymouth-rotation.sh` - Systemd script (patches volumio-adaptive only)
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

**Note**: These enhancements apply to volumio-adaptive theme only. volumio-text uses framebuffer rotation and does not use these mechanisms.

### Auto-detection

For volumio-adaptive: Read both `plymouth=` and kernel rotation, apply formula automatically:

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
