#!/bin/bash
#
# Generate all Plymouth overlay images
# 13 messages x 4 rotations x 2 sizes = 104 images
# Overlays placed directly in sequence directories alongside animations
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

# Message definitions
declare -A MESSAGES
MESSAGES["player-preparing"]="Player preparing startup"
MESSAGES["finishing-storage"]="Finishing storage preparations."
MESSAGES["player-prepared"]="Player prepared, please wait for startup to finish"
MESSAGES["player-restarting"]="Player re-starting now"
MESSAGES["receiving-update"]="Receiving player update from USB, this can take several minutes"
MESSAGES["update-complete"]="Player update from USB completed"
MESSAGES["remove-usb"]="Remove USB used for update, the player restarts after 10 seconds"
MESSAGES["factory-reset"]="Performing factory reset, this can take several minutes"
MESSAGES["performing-update"]="Performing player update, followed by a restart"
MESSAGES["success-restart"]="Success, player restarts after 5 seconds"
MESSAGES["expanding-storage"]="Expanding internal storage space to maximum, this can take a minute"
MESSAGES["waiting-usb"]="Waiting for USB devices, this should not take long"
MESSAGES["internal-update"]="Player internal parameters update from successful system upgrade"

# Ensure sequence directories exist
for seq in 0 90 180 270; do
    if [ ! -d "$BASE_DIR/sequence${seq}" ]; then
        echo "Error: sequence${seq} directory not found"
        exit 1
    fi
done

# Function to create overlay image
create_overlay() {
    local sequence=$1
    local size=$2
    local message_id=$3
    local message_text="${MESSAGES[$message_id]}"
    local output_file="$BASE_DIR/sequence${sequence}/overlay-${message_id}${size}.png"
    
    # Determine font size first
    if [ "$size" = "" ]; then
        FONT_SIZE=16
    else
        FONT_SIZE=12
    fi
    
    # Calculate text width needed (approximate: font_size * 0.6 * char_count)
    text_length=${#message_text}
    text_width_needed=$(echo "$FONT_SIZE * 0.6 * $text_length" | bc)
    text_width_needed=${text_width_needed%.*}  # Convert to integer
    
    # Add margins
    text_width_with_margin=$((text_width_needed + 40))
    
    # Determine dimensions based on sequence and size
    case "$sequence" in
        0|180)
            # Horizontal text - check if we need wider overlay
            if [ $text_width_with_margin -gt 480 ]; then
                WIDTH=$text_width_with_margin
            else
                WIDTH=480
            fi
            
            if [ "$size" = "" ]; then
                HEIGHT=380
            else
                HEIGHT=322
            fi
            ;;
        90|270)
            # Vertical text - height becomes the limiting dimension
            # For vertical text, the "width" (after rotation) is the HEIGHT dimension
            if [ $text_width_with_margin -gt 480 ]; then
                HEIGHT=$text_width_with_margin
            else
                HEIGHT=480
            fi
            
            if [ "$size" = "" ]; then
                WIDTH=380
            else
                WIDTH=320
            fi
            ;;
    esac
    
    # Create base TRANSPARENT image
    convert -size ${WIDTH}x${HEIGHT} xc:none /tmp/base_$$.png
    
    # Create text image
    case "$sequence" in
        0)
            # Text at bottom, horizontal
            convert -background none \
                    -fill white \
                    -font Liberation-Sans \
                    -pointsize $FONT_SIZE \
                    -gravity center \
                    label:"$message_text" \
                    /tmp/text_$$.png
            
            # Composite text onto base at bottom center
            convert /tmp/base_$$.png /tmp/text_$$.png \
                    -gravity south \
                    -geometry +0+20 \
                    -composite \
                    "$output_file"
            ;;
            
        90)
            # Text rotated 90° clockwise (top-to-bottom reading)
            convert -background none \
                    -fill white \
                    -font Liberation-Sans \
                    -pointsize $FONT_SIZE \
                    -gravity center \
                    label:"$message_text" \
                    -rotate 90 \
                    /tmp/text_$$.png
            
            # Composite text onto base at left center
            convert /tmp/base_$$.png /tmp/text_$$.png \
                    -gravity west \
                    -geometry +20+0 \
                    -composite \
                    "$output_file"
            ;;
            
        180)
            # Text at bottom, upside down
            convert -background none \
                    -fill white \
                    -font Liberation-Sans \
                    -pointsize $FONT_SIZE \
                    -gravity center \
                    label:"$message_text" \
                    -rotate 180 \
                    /tmp/text_$$.png
            
            # Composite text onto base at top center (becomes bottom after 180° rotation)
            convert /tmp/base_$$.png /tmp/text_$$.png \
                    -gravity north \
                    -geometry +0+20 \
                    -composite \
                    "$output_file"
            ;;
            
        270)
            # Text rotated 270° clockwise (bottom-to-top reading)
            convert -background none \
                    -fill white \
                    -font Liberation-Sans \
                    -pointsize $FONT_SIZE \
                    -gravity center \
                    label:"$message_text" \
                    -rotate 270 \
                    /tmp/text_$$.png
            
            # Composite text onto base at right center
            convert /tmp/base_$$.png /tmp/text_$$.png \
                    -gravity east \
                    -geometry +20+0 \
                    -composite \
                    "$output_file"
            ;;
    esac
    
    # Cleanup temp files
    rm -f /tmp/base_$$.png /tmp/text_$$.png
    
    echo "Created: $output_file (${WIDTH}x${HEIGHT})"
}

# Generate all images
echo "Generating message overlays..."
echo "Output: sequence directories in $BASE_DIR"
echo

for message_id in "${!MESSAGES[@]}"; do
    echo "Generating overlays for: ${MESSAGES[$message_id]}"
    
    # sequence0 - large and compact
    create_overlay 0 "" "$message_id"
    create_overlay 0 "-compact" "$message_id"
    
    # sequence90 - large and compact
    create_overlay 90 "" "$message_id"
    create_overlay 90 "-compact" "$message_id"
    
    # sequence180 - large and compact
    create_overlay 180 "" "$message_id"
    create_overlay 180 "-compact" "$message_id"
    
    # sequence270 - large and compact
    create_overlay 270 "" "$message_id"
    create_overlay 270 "-compact" "$message_id"
done

echo ""
echo "Image generation complete!"
echo "Total images created: $(find $BASE_DIR/sequence* -name 'overlay-*.png' | wc -l)"
echo ""
echo "Overlays placed in:"
for seq in 0 90 180 270; do
    count=$(ls -1 $BASE_DIR/sequence${seq}/overlay-*.png 2>/dev/null | wc -l)
    echo "  sequence${seq}/: $count files"
done
