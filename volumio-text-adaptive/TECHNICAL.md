Technical Documentation - Rotation Adaptation
=============================================

**INTEGRATION NOTE**: In volumio-os, this theme becomes `volumio-text` and uses
framebuffer rotation (`video=` or `fbcon=` parameters) instead of coordinate
transformation. This documentation reflects the original development approach.
See "Integration Version (volumio-os)" section below for deployed usage.

COORDINATE TRANSFORMATION SYSTEM (DEVELOPMENT VERSION)
------------------------------------------------------

The text theme implements automatic coordinate transformation
to adapt layout to display rotation without pre-rendered content.

**NOTE**: This coordinate transformation approach is used only in the 
development version. The volumio-os integration uses framebuffer rotation 
instead due to Plymouth API limitations with text rotation.

ROTATION DETECTION (DEVELOPMENT VERSION)
----------------------------------------

Rotation value read from /proc/cmdline at theme initialization.

Detection logic:
1. Read /proc/cmdline contents
2. Search for rotate=N parameter
3. Parse N as integer (0, 90, 180, 270)
4. Store in global.rotation variable
5. Default to 0 if not found

Code:
```
global.rotation = 0;
cmdline_file = "/proc/cmdline";
cmdline_contents = ReadFile(cmdline_file);

if (cmdline_contents) {
  cmdline_str = cmdline_contents;
  if (StringContains(cmdline_str, "rotate=90")) {
    global.rotation = 90;
  } else if (StringContains(cmdline_str, "rotate=180")) {
    global.rotation = 180;
  } else if (StringContains(cmdline_str, "rotate=270")) {
    global.rotation = 270;
  }
}
```

**INTEGRATION NOTE**: This rotate= detection is not used in volumio-os.
See "Integration Version" section below for the deployed approach.

COORDINATE SYSTEMS
------------------

Physical Coordinates:
- Actual pixel positions on physical display
- Fixed based on panel dimensions
- Example: 800x480 landscape display

Logical Coordinates:
- Layout calculation space
- May be swapped for portrait rotations
- Example: 480x800 when rotated 90/270 degrees

TRANSFORMATION FORMULAS (DEVELOPMENT VERSION)
---------------------------------------------

Rotation 0 degrees (Standard):
  physical_x = logical_x
  physical_y = logical_y
  layout_width = Window.GetWidth()
  layout_height = Window.GetHeight()

Rotation 90 degrees (Portrait Right):
  physical_x = Window.GetHeight() - logical_y
  physical_y = logical_x
  layout_width = Window.GetHeight()
  layout_height = Window.GetWidth()

Rotation 180 degrees (Upside Down):
  physical_x = Window.GetWidth() - logical_x
  physical_y = Window.GetHeight() - logical_y
  layout_width = Window.GetWidth()
  layout_height = Window.GetHeight()

Rotation 270 degrees (Portrait Left):
  physical_x = logical_y
  physical_y = Window.GetWidth() - logical_x
  layout_width = Window.GetHeight()
  layout_height = Window.GetWidth()

IMPLEMENTATION FUNCTIONS (DEVELOPMENT VERSION)
----------------------------------------------

transform_coordinates(x, y):
  Input: Logical coordinates (layout space)
  Output: Physical coordinates (screen space)
  
  Applies rotation-specific transformation formula.
  
  Example:
  logical_x = 240 (center of 480-wide layout)
  logical_y = 200 (vertical position)
  rotation = 90
  
  Result:
  physical_x = 800 - 200 = 600
  physical_y = 240

get_layout_dimensions():
  Returns: [layout_width, layout_height]
  
  For 0/180: Returns actual window dimensions
  For 90/270: Returns swapped dimensions
  
  Used for: Centering calculations in logical space

CENTERING LOGIC
---------------

All elements centered in logical space before transformation:

Title centering:
  title_x = layout_width / 2 - title_image.GetWidth() / 2
  title_y = layout_height / 2 - 40

Message centering:
  message_x = layout_width / 2 - message_image.GetWidth() / 2
  message_y = title_y + title_image.GetHeight() + 15

Then transformed:
  physical_pos = transform_coordinates(title_x, title_y)

ROTATION VISUALIZATION
----------------------

Consider 800x480 display with text at logical center (400, 240):

Rotation 0:
  +---800px---+
  |           |
  |    TEXT   | 480px
  |  (400,240)|
  +-----------+
  Physical: (400, 240)

Rotation 90:
  +-480px-+
  |       |
  |       |
  | TEXT  | 800px
  |(240,  |
  | 400)  |
  +-------+
  Physical: (800-240, 400) = (560, 400)

Rotation 180:
  +---800px---+
  |(400,240)  |
  |   TEXT    | 480px
  |           |
  +-----------+
  Physical: (800-400, 480-240) = (400, 240)

Rotation 270:
  +-480px-+
  |  (400,|
  |  240) |
  |  TEXT | 800px
  |       |
  |       |
  +-------+
  Physical: (240, 800-400) = (240, 400)

DIMENSION ADAPTATION
--------------------

Font sizes adapt to logical height (not physical):

```
layout_dims = get_layout_dimensions();
layout_height = layout_dims[1];

if (layout_height < 480) {
  title_font = "Sans Bold 12";
}
if (layout_height < 240) {
  title_font = "Sans Bold 10";
}
```

For 800x480 display:
- Rotation 0/180: layout_height = 480, use Bold 12
- Rotation 90/270: layout_height = 800, use Bold 16

This ensures text remains proportional to viewing area.

TEXT TRUNCATION
---------------

Message truncation based on logical width:

```
max_chars = 60;
if (global.layout_width < 640) {
  max_chars = 40;
}
if (global.layout_width < 320) {
  max_chars = 30;
}
```

Prevents text overflow in narrower orientations.

ROTATION INDEPENDENCE
---------------------

Key principle: Layout calculations in logical space.

Process:
1. Calculate element positions in logical coordinates
2. Transform to physical coordinates
3. Set sprite positions using physical coordinates

Benefits:
- Single layout logic for all rotations
- No rotation-specific positioning code
- Maintains proper centering automatically

COMPARISON TO IMAGE THEME
--------------------------

Image Theme Rotation Adaptation:
- Selects pre-rotated image sequence
- plymouth= parameter chooses file
- Images pre-rendered at each rotation
- Formula: plymouth = (360 - rotate) % 360

Text Theme Rotation Adaptation (Development):
- Transforms coordinates dynamically
- No pre-rendered content needed
- Single script handles all rotations
- Runtime coordinate calculation

Text Theme Rotation Adaptation (Integration):
- Uses framebuffer rotation
- video=...,rotate= or fbcon=rotate: parameters
- System handles rotation, not theme
- Simple theme with no coordinate transformation

PASSWORD PROMPT TRANSFORMATION (DEVELOPMENT VERSION)
----------------------------------------------------

Password prompts also transformed:

```
prompt_x = global.layout_width / 2 - prompt_image.GetWidth() / 2;
prompt_y = global.layout_height / 2 + 40;
prompt_pos = transform_coordinates(prompt_x, prompt_y);
global.password_prompt.SetPosition(prompt_pos[0], prompt_pos[1], 100);
```

Ensures prompts remain centered and readable at any rotation.

Z-ORDERING
----------

Z-order independent of rotation:
- Background: 0 (implicit)
- Title: 10
- Messages: 10
- Password prompts: 100

Higher Z values appear in front.

PERFORMANCE CONSIDERATIONS
--------------------------

Coordinate transformation overhead (Development Version):
- Minimal (simple arithmetic)
- Executed only during element positioning
- Not per-frame (text is static)

Memory usage:
- No image buffers
- Only text rendering cache
- Significantly lighter than image theme

LIMITATIONS
-----------

1. Cannot rotate text within sprites
   - Plymouth doesn't support sprite rotation
   - Text always horizontal in physical space
   - Rotation handled by coordinate transformation only

2. Font rendering
   - Depends on system font availability
   - Sans and Monospace fonts assumed present
   - Fallback to system default if missing

3. Transform precision
   - Integer coordinates only
   - Minor centering variations possible
   - Generally imperceptible

INTEGRATION VERSION (VOLUMIO-OS)
--------------------------------

### Why Coordinate Transformation Was Removed

Plymouth Script API does not support rotating text images:
- No Image.Rotate() function exists
- Image.Text() creates horizontal text only
- Cannot rotate dynamic text at runtime
- Only pre-rendered static images can be rotated

**Evidence**: The volumio-player-ccw theme disables text messages with this 
comment: "plymouth is unable to rotate properly in init"

**Result**: Coordinate transformation alone cannot create readable rotated 
text displays. Text positioned at transformed coordinates remains horizontal 
in physical space.

### Framebuffer Rotation Solution

In volumio-os, volumio-text uses system-level framebuffer rotation:

Parameter Format:
- video=...,rotate=90
- video=...,rotate=180  
- video=...,rotate=270
- fbcon=rotate:1 (90 degrees)
- fbcon=rotate:2 (180 degrees)
- fbcon=rotate:3 (270 degrees)

How It Works:
1. Kernel rotates framebuffer before Plymouth starts
2. Plymouth writes text to already-rotated buffer
3. Text appears correctly rotated on physical display
4. Theme code remains simple (no transformation needed)

### Implementation Difference

Development Version (volumio-text-adaptive):
- Script: 227 lines with coordinate transformation
- Detects rotate= parameter in /proc/cmdline
- Transforms coordinates for each element
- Text still horizontal (limitation)

Integration Version (volumio-text):
- Script: 174 lines without transformation
- Relies on video= or fbcon= parameters
- No coordinate transformation code
- System handles rotation completely

### Parameter Usage By Theme

| Theme | Parameter | Purpose |
|-------|-----------|---------|
| volumio-adaptive | plymouth=0 or 90 or 180 or 270 | Pre-rotated images |
| volumio-text | video=...,rotate=90 | Framebuffer rotation |
| volumio-text | fbcon=rotate:1 | Framebuffer rotation |

**CRITICAL**: Do not use plymouth= parameter with volumio-text theme.
It expects system-level rotation via video= or fbcon= parameters.

### Advantages of Framebuffer Rotation

Technical Benefits:
- Actually rotates text (not just coordinates)
- Works with Plymouth API limitations
- Simpler theme code
- More reliable across displays

Functional Benefits:
- Text remains readable at all rotations
- No Plymouth API workarounds needed
- Compatible with existing system rotation
- Standard Linux framebuffer approach

### Migration Notes

When moving from development to integration:

Removed Code:
- transform_coordinates() function (40 lines)
- get_layout_dimensions() function (15 lines)
- Rotation detection from /proc/cmdline (20 lines)
- All coordinate transformation calls (15 locations)

Added Requirements:
- video= or fbcon= parameters in /boot/cmdline.txt
- System-level rotation configuration
- Display-specific rotation values

Updated Documentation:
- Installation instructions use video=/fbcon= parameters
- Troubleshooting covers parameter configuration
- Examples show system-level rotation setup

DEBUGGING ROTATION (DEVELOPMENT VERSION)
----------------------------------------

To debug rotation issues in development version:

1. Add debug output to script:
   ```
   debug_msg = "Rotation: " + global.rotation;
   message_callback(debug_msg);
   ```

2. Check /proc/cmdline:
   ```
   cat /proc/cmdline | grep rotate
   ```

3. Verify transformation:
   - Known logical position
   - Calculate expected physical position
   - Compare with actual sprite position

4. Test all four rotations:
   - rotate=0, 90, 180, 270
   - Verify centering maintained
   - Check text visibility

DEBUGGING ROTATION (INTEGRATION VERSION)
----------------------------------------

To debug rotation issues in volumio-text:

1. Verify framebuffer rotation parameters:
   ```
   cat /boot/cmdline.txt | grep -E 'rotate|fbcon'
   ```

2. Check active rotation:
   ```
   cat /sys/class/graphics/fbcon/rotate
   ```

3. Test rotation values:
   - rotate=90 or fbcon=rotate:1
   - rotate=180 or fbcon=rotate:2
   - rotate=270 or fbcon=rotate:3

4. Verify theme active:
   ```
   sudo plymouth-set-default-theme --list
   sudo plymouth-set-default-theme
   ```

COORDINATE SYSTEM REFERENCE
----------------------------

Screen origin: Top-left corner (0, 0)
X-axis: Increases right
Y-axis: Increases down

After transformation (Development):
- Origin remains top-left of physical display
- Logical (0,0) maps to different physical positions
- Center calculations in logical space ensure proper layout

After framebuffer rotation (Integration):
- Origin remains top-left
- Entire framebuffer rotated by kernel
- Theme uses standard coordinates
- System handles all rotation

FORMULA DERIVATION (DEVELOPMENT VERSION)
----------------------------------------

90-degree rotation formula derivation:

Original point: (x, y) in WxH display
After 90-degree rotation: display is HxW

Old top-left (0,0) -> new top-right (H,0)
Old point (x,y) rotates around origin
New position: (H-y, x)

Generalized for all rotations using matrix multiplication,
simplified to conditional formulas for performance.

**NOTE**: These formulas are not used in volumio-os integration.
Framebuffer rotation eliminates need for coordinate transformation.

TESTING METHODOLOGY
-------------------

Test matrix for rotation validation (Development Version):

Display: 800x480
Test positions:
- Top-left: (0, 0)
- Top-right: (800, 0)
- Center: (400, 240)
- Bottom-left: (0, 480)
- Bottom-right: (800, 480)

Verify centering:
- Calculate logical center
- Transform to physical
- Measure distance from physical center
- Should match for all rotations

Test matrix for rotation validation (Integration Version):

1. Configure framebuffer rotation
2. Reboot system
3. Verify boot splash rotated correctly
4. Check text readability
5. Test all rotation values (0, 90, 180, 270)

FUTURE ENHANCEMENTS
-------------------

Possible improvements:
1. Support for intermediate rotations (45, 135, etc.)
2. Dynamic rotation detection (without reboot)
3. Rotation animation transitions
4. Text scaling based on rotation
5. Multi-line message support with wrap

Currently out of scope due to Plymouth limitations.

REFERENCE IMPLEMENTATION
------------------------

Development Version:
- See volumio-text-adaptive/volumio-text.script
- 227 lines with coordinate transformation
- Key functions: transform_coordinates(), get_layout_dimensions()

Integration Version (volumio-os):
- See volumio-text theme in volumio-os
- 174 lines without transformation
- Relies on framebuffer rotation
- Simpler implementation

SUMMARY OF APPROACHES
---------------------

| Aspect | Development | Integration |
|--------|-------------|-------------|
| Theme name | volumio-text-adaptive | volumio-text |
| Script lines | 227 | 174 |
| Rotation method | Coordinate transform | Framebuffer |
| Parameter | rotate=N | video=...,rotate=N |
| Text rotation | Not supported | Fully supported |
| Complexity | High | Low |
| Limitation | Horizontal text only | None |

**RECOMMENDATION**
Use integration version (volumio-text) with framebuffer rotation for reliable rotated text display. Development version demonstrates Plymouth API limitations.
