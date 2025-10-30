# Display Rotation Mathematics

Understanding how kernel rotation and Plymouth rotation relate.

## The Problem

Raspberry Pi has two separate display systems that handle rotation differently:

1. **Kernel Console** (framebuffer console)
   - Controlled by rotate= parameter
   - Affects text console and most graphics
   - Applied at kernel level

2. **Plymouth Boot Splash**
   - Direct framebuffer access
   - Does NOT respect kernel rotation
   - Sees raw, unrotated display dimensions

## Why This Matters

When you set rotate=270 in the kernel:
- Text console rotates 270 degrees counterclockwise
- Plymouth framebuffer stays at 0 degrees (no rotation)
- Result: Plymouth shows sideways or upside-down

## The Rotation Formula

To compensate, we use opposite rotation:

```
plymouth_rotation = (360 - kernel_rotation) % 360
```

### Examples

| Kernel rotate= | Console Result | plymouth= Needed | Plymouth Images |
|---------------|----------------|------------------|-----------------|
| 0             | Normal         | 0                | Normal          |
| 90            | 90 CCW         | 270              | 270 CW          |
| 180           | Upside-down    | 180              | Upside-down     |
| 270           | 270 CCW        | 90               | 90 CW           |

## Visual Explanation

### Portrait Display (320x1480) - Physical Orientation

```
Native (0 degrees):
+-------+
|       |  320 wide
|       |  1480 tall
|       |
|   ^   |
|   |   |
| TOP   |
+-------+
```

### Kernel rotate=270 (console rotates 270 CCW)

```
Console sees:
+-----------------+
|  <-- TOP        |  1480 wide
|                 |  320 tall
+-----------------+

Physical display rotated 270 CCW:
+-----------------+
|  TOP -->        |
|                 |
+-----------------+
```

### plymouth=90 (images rotated 90 CW)

```
Images rotated 90 CW:
+-------+
|   ^   |
|   |   |
| TOP   |  Back to correct orientation
|       |  when displayed on rotated framebuffer
|       |
+-------+
```

## Why Opposite Directions

The kernel rotates the viewport.
Plymouth rotates the content.

Think of it as:
- Kernel: Rotating the window you look through
- Plymouth: Rotating the picture inside the window

To see the picture correctly through a rotated window, you must rotate the picture the opposite direction.

## Common Configurations

### Landscape Display (1920x1080)

Native orientation - no rotation needed:
```
/boot/cmdline.txt:
video=HDMI-A-1:1920x1080M@60 plymouth=0

Or (simplified):
plymouth=0
```

Note: video= parameter goes in cmdline.txt, not userconfig.txt

### Portrait Display - Top at Right

Rotate display 90 CCW, images 270 CW:
```
/boot/cmdline.txt:
video=HDMI-A-1:1080x1920M@60,rotate=90 plymouth=270
```

### Portrait Display - Top at Left

Rotate display 270 CCW, images 90 CW:
```
/boot/cmdline.txt:
video=HDMI-A-1:1080x1920M@60,rotate=270 plymouth=90
```

### Upside-Down Display

Rotate display 180, images 180:
```
/boot/cmdline.txt:
video=HDMI-A-1:1920x1080M@60,rotate=180 plymouth=180
```

### Important: cmdline.txt Location

Location varies by operating system:
- Volumio 3.x/4.x: /boot/cmdline.txt
- Raspberry Pi OS Bookworm: /boot/firmware/cmdline.txt

All parameters (video=, rotate=, plymouth=) must be on a single line in cmdline.txt.

## Text Theme Coordinate Transformation

The volumio-text-adaptive theme uses a different approach - coordinate transformation instead of pre-rotated images.

### How Text Theme Works

Instead of loading different image sequences, the text theme:
1. Reads rotate= parameter (not plymouth=)
2. Transforms text sprite coordinates at runtime
3. No pre-rendered images needed

### Text Theme Rotation

For text theme, use the rotate= parameter directly:
```
/boot/cmdline.txt:
rotate=270 (for portrait left)
```

No plymouth= parameter needed for text theme.

### Coordinate Transformation Math

The text theme transform_coordinates function applies:

For rotate=90:
```
new_x = screen_height - old_y
new_y = old_x
```

For rotate=180:
```
new_x = screen_width - old_x
new_y = screen_height - old_y
```

For rotate=270:
```
new_x = old_y
new_y = screen_width - old_x
```

This ensures text always appears upright relative to the physical display orientation.

## Runtime Detection

Both themes support runtime detection that eliminates manual script edits.

### With Runtime Detection Installed

Changing rotation workflow:
1. Edit cmdline.txt (change plymouth= or rotate= values)
2. Reboot
3. Done - automatic patching at boot

### Without Runtime Detection

Changing rotation workflow:
1. Edit cmdline.txt
2. Manually edit theme script
3. Change rotation variable value
4. Rebuild initramfs
5. Reboot

Runtime detection installation: See volumio-plymouth-adaptive/runtime-detection/RUNTIME-DETECTION-INSTALL.md

## Dimension Swapping

When plymouth=90 or plymouth=270 (portrait modes):
- Script swaps screen_width and screen_height
- This ensures sequence logic works correctly
- Image dimensions remain as stored (already rotated)

### Example

Display: 320x1480 native portrait
Config: rotate=270, plymouth=90

Plymouth reports:
- screen_width = 320
- screen_height = 1480

Script swaps for sequence logic:
- effective_width = 1480
- effective_height = 320

Loads from: sequence90/ (images rotated 90 CW, dimensions 270x480)

Result: Correctly oriented display

## Testing Rotation

To test if rotation is correct:

1. Look for text in boot splash
2. Text should be readable without turning your head
3. Animation should flow naturally
4. No stretching or distortion

If wrong:
- Text sideways: Add or change plymouth= parameter
- Text upside-down: Try opposite rotation (90 vs 270)
- Text backwards: Check if images were generated correctly

## Mathematical Proof

Given:
- K = kernel rotation (degrees CCW)
- P = plymouth rotation (degrees CW)
- R = resulting display orientation

For correct orientation: R = 0

```
R = (K + P) % 360 = 0
P = (360 - K) % 360
```

Examples:
- K=90:  P = (360-90) % 360 = 270
- K=270: P = (360-270) % 360 = 90
- K=180: P = (360-180) % 360 = 180
- K=0:   P = (360-0) % 360 = 0

## References

- Plymouth framebuffer documentation
- Linux kernel fbcon rotation
- Raspberry Pi video= parameter documentation
