#!/usr/bin/env bash
# Generate a labeled 1920x1080 24fps placeholder clip so the pipeline can run
# before the real screen recording exists. Usage: make_placeholder.sh NAME LABEL SECONDS
set -euo pipefail
NAME="$1"; LABEL="$2"; SECS="${3:-4}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/capture/${NAME}"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Use Python with PIL to create a frame with text label
python3 << PYTHON_EOF
import sys
from PIL import Image, ImageDraw, ImageFont

# Create a 1920x1080 image with dark background
img = Image.new('RGB', (1920, 1080), color=(0x1e, 0x20, 0x30))
draw = ImageDraw.Draw(img)

# Try to use a system font, fall back to default if not available
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 54)
except:
    font = ImageFont.load_default()

# Draw text centered
label = "$LABEL"
bbox = draw.textbbox((0, 0), label, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
x = (1920 - text_width) // 2
y = (1080 - text_height) // 2
draw.text((x, y), label, fill=(255, 255, 255), font=font)

# Save frame
img.save("$TMPDIR/frame.png")
PYTHON_EOF

# Create video from the frame, looped for the specified duration
ffmpeg -y -loop 1 -i "$TMPDIR/frame.png" -c:v libx264 -pix_fmt yuv420p -r 24 -t "$SECS" "${OUT}" >/dev/null 2>&1
echo "wrote ${OUT}"
