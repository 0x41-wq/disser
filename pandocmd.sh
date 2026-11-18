#!/bin/bash
# pandocmd.sh - Build dissertation by chapters, convert LaTeX directly to DOCX with images
# Usage: ./pandocmd.sh [dissertation|synopsis]
# Key: Convert LaTeX → DOCX directly, not via markdown (preserves images and formatting)

set -e

TARGET="${1:-dissertation}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${BUILD_DIR}/output"
DOCX_PARTS_DIR="${OUTPUT_DIR}/docx-parts"
IMAGES_DIR="${OUTPUT_DIR}/images-docx"

echo "==== Building $TARGET by chapters (LaTeX → DOCX directly) ===="
echo "Project dir: $PROJECT_DIR"
echo "Build dir: $BUILD_DIR"
echo "Output dir: $OUTPUT_DIR"
echo ""

# Create directories
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$DOCX_PARTS_DIR" "$IMAGES_DIR"

# === LaTeX files for dissertation ===
if [ "$TARGET" = "dissertation" ]; then
  LATEX_FILES=(
    "Dissertation/title.tex"
    "Dissertation/introduction.tex"
    "Dissertation/part1.tex"
    "Dissertation/part2.tex"
    "Dissertation/part3.tex"
    "Dissertation/part4.tex"
    "Dissertation/conclusion.tex"
    "Dissertation/references.tex"
    "Dissertation/appendix.tex"
  )
  OUTPUT_FILE="dissertation.docx"

# === LaTeX files for synopsis ===
elif [ "$TARGET" = "synopsis" ]; then
  LATEX_FILES=(
    "Dissertation/title.tex"
    "synopsis.tex"
  )
  OUTPUT_FILE="synopsis.docx"

else
  echo "ERROR: Unknown target '$TARGET'. Use 'dissertation' or 'synopsis'."
  exit 1
fi

# === Convert each chapter LaTeX → DOCX directly (preserves images) ===
echo "Converting chapters LaTeX → DOCX (preserving images)..."
DOCX_PARTS=()

for latex_file in "${LATEX_FILES[@]}"; do
  if [ ! -f "$PROJECT_DIR/$latex_file" ]; then
    echo "Warning: File not found: $PROJECT_DIR/$latex_file (skipping)"
    continue
  fi

  base=$(basename "$latex_file" .tex)
  docx_part="$DOCX_PARTS_DIR/${base}.docx"
  
  echo "  Converting: $latex_file"
  
  # Convert LaTeX to DOCX with reference doc and media extraction
  # Using --from=latex to preserve LaTeX structures better
  pandoc \
    --from=latex \
    --to=docx \
    --wrap=auto \
    --reference-doc="$PROJECT_DIR/reference.docx" \
    --extract-media="$IMAGES_DIR" \
    --resource-path="$PROJECT_DIR" \
    "$PROJECT_DIR/$latex_file" \
    -o "$docx_part" \
    2>&1 || echo "  Warning: Conversion had issues (continuing)"
  
  DOCX_PARTS+=("$docx_part")
done

echo ""

# === For now: use first DOCX as base (in production, merge all via python-docx or docxcompose) ===
# Since merging DOCX files is complex, we'll create a combined markdown from LaTeX
# but this time using a different approach: extract images first, then ensure they're in markdown

echo "Creating combined LaTeX file with all chapters..."
COMBINED_TEX="$BUILD_DIR/combined.tex"

# Minimal LaTeX preamble
cat > "$COMBINED_TEX" << 'LATEXPREAMBLE'
\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage{graphicx}
\begin{document}
LATEXPREAMBLE

# Append each chapter with explicit image path setup
for latex_file in "${LATEX_FILES[@]}"; do
  if [ -f "$PROJECT_DIR/$latex_file" ]; then
    echo "" >> "$COMBINED_TEX"
    # Include file with relative path from combined.tex
    # pandoc will resolve image paths relative to the included files
    cat "$PROJECT_DIR/$latex_file" >> "$COMBINED_TEX"
    echo "" >> "$COMBINED_TEX"
  fi
done

# Close LaTeX document
echo '\end{document}' >> "$COMBINED_TEX"

echo "Combined LaTeX: $COMBINED_TEX"
echo ""

# Convert referenced PDF figures to PNG for better Word compatibility
echo "Converting referenced PDF figures to PNG (if any)..."
# Find includegraphics targets with .pdf extension
grep -oP "\\\\includegraphics[^\n]*\{\K[^}]+\\.pdf" "$COMBINED_TEX" | sort -u | while read -r img; do
  src="$PROJECT_DIR/$img"
  png_src="${src%.pdf}.png"
  rel_png="${img%.pdf}.png"
  if [ -f "$src" ]; then
    if [ ! -f "$png_src" ]; then
      echo "  Converting: $img -> $rel_png"
      # Try pdftoppm (poppler); fall back to ImageMagick convert
      if command -v pdftoppm >/dev/null 2>&1; then
        pdftoppm -png -singlefile "$src" "${src%.pdf}" >/dev/null 2>&1 || true
      else
        convert -density 300 "$src" "$png_src" >/dev/null 2>&1 || true
      fi
    else
      echo "  Already exists: $rel_png"
    fi
  else
    echo "  Warning: source image not found: $src"
  fi
done

# Replace .pdf references in combined tex with .png so pandoc embeds PNGs
if grep -q "\\.pdf" "$COMBINED_TEX"; then
  echo "Updating combined.tex references from .pdf to .png"
  sed -i 's/\.pdf}/.png}/g; s/\.pdf)/.png)/g; s/\.pdf\]/.png]/g' "$COMBINED_TEX"
fi

# === Convert combined LaTeX directly to DOCX ===
echo "Converting combined LaTeX to DOCX with images..."
OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILE"

if [ "$TARGET" = "synopsis" ]; then
  # For synopsis, convert directly without combining (it's a complete document)
  pandoc \
    --from=latex \
    --to=docx \
    --wrap=auto \
    --lua-filter="$PROJECT_DIR/filters/cleanup-latex.lua" \
    --reference-doc="$PROJECT_DIR/reference.docx" \
    --extract-media="$IMAGES_DIR" \
    --resource-path="$PROJECT_DIR" \
    "$PROJECT_DIR/synopsis.tex" \
    -o "$OUTPUT_PATH"
else
  # For dissertation, convert combined file
  pandoc \
    --from=latex \
    --to=docx \
    --wrap=auto \
    --table-of-contents \
    --number-sections \
    --lua-filter="$PROJECT_DIR/filters/cleanup-latex.lua" \
    --reference-doc="$PROJECT_DIR/reference.docx" \
    --extract-media="$IMAGES_DIR" \
    --resource-path="$PROJECT_DIR" \
    "$COMBINED_TEX" \
    -o "$OUTPUT_PATH"
fi

echo ""
echo "==== Build complete ===="
echo "Output: $OUTPUT_PATH"
echo "Size: $(du -h "$OUTPUT_PATH" | cut -f1)"

if [ -d "$IMAGES_DIR" ] && [ -n "$(ls -A "$IMAGES_DIR" 2>/dev/null)" ]; then
  echo "Images extracted: $IMAGES_DIR"
  echo "  Files: $(find "$IMAGES_DIR" -type f | wc -l)"
  echo "  Content: $(ls -la "$IMAGES_DIR" | tail -n +4 | head -5)"
else
  echo "Images: None extracted (check if images are in LaTeX files)"
fi
echo ""

# Copy to root for convenience
cp "$OUTPUT_PATH" "$PROJECT_DIR/$OUTPUT_FILE"
echo "Also copied to: $PROJECT_DIR/$OUTPUT_FILE"
echo ""
echo "Done!"
