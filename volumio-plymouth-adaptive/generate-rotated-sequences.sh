#!/bin/bash
#
# generate-rotated-sequences.sh
# Generates all four rotation sequence directories from base volumio-player images
#
# Usage: ./generate-rotated-sequences.sh /path/to/volumio-player/sequence /path/to/volumio-adaptive
#

set -e

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 SOURCE_DIR TARGET_DIR"
  echo "  SOURCE_DIR: Path to volumio-player/sequence (contains base 480x270 images)"
  echo "  TARGET_DIR: Path to volumio-adaptive theme directory"
  exit 1
fi

SOURCE_DIR="$1"
TARGET_DIR="$2"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "ERROR: Source directory does not exist: $SOURCE_DIR"
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "ERROR: Target directory does not exist: $TARGET_DIR"
  exit 1
fi

echo "=========================================="
echo "Volumio Adaptive Image Generation"
echo "=========================================="
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Create sequence directories
echo "Creating sequence directories..."
mkdir -p "$TARGET_DIR/sequence0"
mkdir -p "$TARGET_DIR/sequence90"
mkdir -p "$TARGET_DIR/sequence180"
mkdir -p "$TARGET_DIR/sequence270"

# Function to rotate a single image
rotate_image() {
  local src="$1"
  local dst="$2"
  local angle="$3"
  
  if [ ! -f "$src" ]; then
    echo "WARNING: Source image not found: $src"
    return
  fi
  
  if [ "$angle" -eq 0 ]; then
    # No rotation, just copy
    cp "$src" "$dst"
  else
    # Rotate using ImageMagick
    convert "$src" -rotate "$angle" "$dst"
  fi
}

# Process all images
echo ""
echo "Processing images..."

# Progress images (1-90)
for i in $(seq 1 90); do
  base_name="progress-$i.png"
  src="$SOURCE_DIR/$base_name"
  
  if [ ! -f "$src" ]; then
    echo "WARNING: Missing $base_name"
    continue
  fi
  
  echo -n "."
  
  # sequence0: no rotation (copy original)
  rotate_image "$src" "$TARGET_DIR/sequence0/$base_name" 0
  
  # sequence90: 90 degrees clockwise
  rotate_image "$src" "$TARGET_DIR/sequence90/$base_name" 90
  
  # sequence180: 180 degrees (upside down)
  rotate_image "$src" "$TARGET_DIR/sequence180/$base_name" 180
  
  # sequence270: 270 degrees clockwise (90 CCW)
  rotate_image "$src" "$TARGET_DIR/sequence270/$base_name" 270
done

echo ""

# Micro images (1-6)
for i in $(seq 1 6); do
  base_name="micro-$i.png"
  src="$SOURCE_DIR/$base_name"
  
  if [ ! -f "$src" ]; then
    echo "WARNING: Missing $base_name"
    continue
  fi
  
  echo -n "."
  
  # sequence0: no rotation (copy original)
  rotate_image "$src" "$TARGET_DIR/sequence0/$base_name" 0
  
  # sequence90: 90 degrees clockwise
  rotate_image "$src" "$TARGET_DIR/sequence90/$base_name" 90
  
  # sequence180: 180 degrees (upside down)
  rotate_image "$src" "$TARGET_DIR/sequence180/$base_name" 180
  
  # sequence270: 270 degrees clockwise (90 CCW)
  rotate_image "$src" "$TARGET_DIR/sequence270/$base_name" 270
done

echo ""

# Layout constraint (if exists)
if [ -f "$SOURCE_DIR/layout-constraint.png" ]; then
  echo "Processing layout-constraint.png..."
  rotate_image "$SOURCE_DIR/layout-constraint.png" "$TARGET_DIR/sequence0/layout-constraint.png" 0
  rotate_image "$SOURCE_DIR/layout-constraint.png" "$TARGET_DIR/sequence90/layout-constraint.png" 90
  rotate_image "$SOURCE_DIR/layout-constraint.png" "$TARGET_DIR/sequence180/layout-constraint.png" 180
  rotate_image "$SOURCE_DIR/layout-constraint.png" "$TARGET_DIR/sequence270/layout-constraint.png" 270
fi

echo ""
echo "=========================================="
echo "Image generation complete!"
echo "=========================================="
echo ""
echo "Generated directories:"
echo "  $TARGET_DIR/sequence0/    (0 degrees - landscape)"
echo "  $TARGET_DIR/sequence90/   (90 degrees CW - portrait)"
echo "  $TARGET_DIR/sequence180/  (180 degrees - upside-down)"
echo "  $TARGET_DIR/sequence270/  (270 degrees CW - portrait)"
echo ""
echo "File counts:"
echo "  sequence0:   $(ls -1 "$TARGET_DIR/sequence0" | wc -l) files"
echo "  sequence90:  $(ls -1 "$TARGET_DIR/sequence90" | wc -l) files"
echo "  sequence180: $(ls -1 "$TARGET_DIR/sequence180" | wc -l) files"
echo "  sequence270: $(ls -1 "$TARGET_DIR/sequence270" | wc -l) files"
echo ""
