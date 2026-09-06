#!/usr/bin/env bash
set -euo pipefail

GIF_DIR="${1:-$(gum input --placeholder "Path to your gifs folder")}"
GIF=$(gum file "$GIF_DIR")

slug=$(basename "$GIF" .gif)
CACHE_DIR="$HOME/.cache/shinyuu/$slug"
mkdir -p "$CACHE_DIR"

if [[ -f "$CACHE_DIR/preview.gif" ]]; then
    ACTION=$(gum choose "Use existing" "Regenerate (different model)" "Just change display size")
else
    ACTION="Regenerate (different model)"
fi

if [[ "$ACTION" == "Regenerate"* ]]; then
    MODEL=$(gum choose "isnet-anime" "u2net_human_seg" "isnet-general-use")
    gum spin --title "Extracting..." -- python src/core/extract.py "$GIF" "$CACHE_DIR" "$MODEL"
    echo "$MODEL" > "$CACHE_DIR/model.txt"
fi

SCALE=$(gum input --placeholder "Scale (e.g. 1.0, 2.0)" --value "1.0")

cat > "$HOME/.config/shinyuu/state.json" <<EOF
{"gif": "$CACHE_DIR/preview.gif", "scale": $SCALE}
EOF

pkill -f "overlay.qml" 2>/dev/null || true
quickshell -p ~/.config/quickshell/overlay.qml &
