Technical Documentation - Rotation Adaptation
=============================================

COORDINATE TRANSFORMATION SYSTEM
---------------------------------

The text theme implements automatic coordinate transformation
to adapt layout to display rotation without pre-rendered content.

ROTATION DETECTION
------------------

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

TRANSFORMATION FORMULAS
-----------------------

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

IMPLEMENTATION FUNCTIONS
------------------------

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

Text Theme Rotation Adaptation:
- Transforms coordinates dynamically
- No pre-rendered content needed
- Single script handles all rotations
- Runtime coordinate calculation

PASSWORD PROMPT TRANSFORMATION
-------------------------------

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

Coordinate transformation overhead:
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

DEBUGGING ROTATION
------------------

To debug rotation issues:

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

COORDINATE SYSTEM REFERENCE
----------------------------

Screen origin: Top-left corner (0, 0)
X-axis: Increases right
Y-axis: Increases down

After transformation:
- Origin remains top-left of physical display
- Logical (0,0) maps to different physical positions
- Center calculations in logical space ensure proper layout

FORMULA DERIVATION
------------------

90-degree rotation formula derivation:

Original point: (x, y) in WxH display
After 90-degree rotation: display is HxW

Old top-left (0,0) -> new top-right (H,0)
Old point (x,y) rotates around origin
New position: (H-y, x)

Generalized for all rotations using matrix multiplication,
simplified to conditional formulas for performance.

TESTING METHODOLOGY
-------------------

Test matrix for rotation validation:

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

See volumio-text.script for complete implementation.

Key functions:
- transform_coordinates(): Core transformation
- get_layout_dimensions(): Dimension handling
- message_callback(): Dynamic positioning

All positioning uses these functions for consistency.
