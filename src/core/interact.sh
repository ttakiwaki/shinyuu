#!/usr/bin/env bash
set -uo pipefail

# ─── Theme: use the terminal's own ANSI palette, not fixed hex ────────────
# ANSI slot numbers (0-15) resolve to whatever colors YOUR terminal theme
# defines for them — so this matches your setup automatically instead of
# imposing a fixed palette. Swap the slot numbers below if you want a
# different accent (0 black, 1 red, 2 green, 3 yellow, 4 blue, 5 magenta,
# 6 cyan, 7 white, 8-15 bright variants).
ACCENT=5   # magenta slot
BORDER=4   # blue slot
ERROR=1    # red slot
OK=2       # green slot

export GUM_INPUT_CURSOR_FOREGROUND="$ACCENT"
export GUM_INPUT_PROMPT_FOREGROUND="$ACCENT"
export GUM_CHOOSE_CURSOR_FOREGROUND="$ACCENT"
export GUM_CHOOSE_SELECTED_FOREGROUND="15"
export GUM_CHOOSE_HEADER_FOREGROUND="$BORDER"
export GUM_CONFIRM_SELECTED_BACKGROUND="$ACCENT"
export GUM_SPIN_SPINNER_FOREGROUND="$ACCENT"
export GUM_SPIN_TITLE_FOREGROUND="15"

export FZF_DEFAULT_OPTS="
  --height=60% --layout=reverse --border=rounded
  --color=fg:-1,bg:-1,hl:$ACCENT
  --color=fg+:-1,bg+:-1,hl+:$ACCENT
  --color=border:$BORDER,prompt:$ACCENT,pointer:$ACCENT,header:$BORDER
"

banner() {
    gum style --border rounded --border-foreground "$BORDER" \
        --padding "0 2" --margin "1 0" "$1"
}

step() {
    gum style --foreground "$BORDER" "▸ $1"
}

err() {
    gum style --foreground "$ERROR" "✗ $1"
}

ok() {
    gum style --foreground "$OK" "✓ $1"
}

# ─── Setup ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
STORE="$HOME/.config/shinyuu/gif_store.json"
STATE_FILE="$HOME/.config/shinyuu/state.json"
LAST_DIR_FILE="$HOME/.config/shinyuu/last_gifdir"
EXTRACT_LOG="/tmp/shinyuu_extract.log"
AVAILABLE_MODELS=("isnet-anime" "isnet-general-use" "u2net" "u2net_human_seg")

mkdir -p "$(dirname "$STORE")"
[[ -s "$STORE" ]] && jq -e . "$STORE" >/dev/null 2>&1 || echo '{}' > "$STORE"

banner "shinyuu — desktop mascot picker"

# ─── Step 1: pick a gif ─────────────────────────────────────────────────
DEFAULT_DIR=""
[[ -f "$LAST_DIR_FILE" ]] && DEFAULT_DIR=$(cat "$LAST_DIR_FILE")

step "Where are your gifs?"
GIFDIR=$(gum input --placeholder "e.g. ~/Pictures/gifs" --value "$DEFAULT_DIR")
GIFDIR="${GIFDIR/#\~/$HOME}"

if [[ ! -d "$GIFDIR" ]]; then
    err "That directory doesn't exist."
    exit 1
fi
echo "$GIFDIR" > "$LAST_DIR_FILE"

mapfile -t GIF_LIST < <(find "$GIFDIR" -type f -iname "*.gif")
if [[ ${#GIF_LIST[@]} -eq 0 ]]; then
    err "No .gif files found in $GIFDIR"
    exit 1
fi

step "Pick a gif"
SELECTEDGIF=$(printf '%s\n' "${GIF_LIST[@]}" | SHELL=bash fzf \
    --delimiter '/' --with-nth -1 \
    --header "enter to select · ctrl-c to cancel" \
    --preview 'kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0" {}')

[[ -z "$SELECTEDGIF" ]] && { err "No gif selected."; exit 1; }

slug=$(basename "$SELECTEDGIF" .gif)
CACHE_DIR="$HOME/.cache/shinyuu/$slug"

# ─── Extraction helpers ───────────────────────────────────────────────────
run_extract() {
    local model="$1"
    mkdir -p "$CACHE_DIR/$model"
    gum spin --title "Extracting with $model..." -- \
        uv run python "$SCRIPT_DIR/extract.py" "$SELECTEDGIF" "$CACHE_DIR/$model" "$model" "$STORE" \
        > "$EXTRACT_LOG" 2>&1

    local out="$CACHE_DIR/$model/preview.gif"
    if [[ ! -s "$out" ]]; then
        err "Extraction failed — see $EXTRACT_LOG"
        exit 1
    fi
    echo "$out"
}

pick_model_and_extract() {
    step "Choose a model" >&2
    local model
    model=$(gum choose --header "which rembg model?" "${AVAILABLE_MODELS[@]}")
    run_extract "$model"
}

# fzf-preview picker for choosing among ALREADY-cached models
pick_existing_model() {
    local model_paths
    model_paths=$(jq -r --arg slug "$slug" \
        '.[$slug].models | to_entries[] | "\(.key)\t\(.value)"' "$STORE")

    printf '%s\n' "$model_paths" | SHELL=bash fzf \
        --delimiter '\t' --with-nth 1 \
        --header "pick a cached model to preview" \
        --preview 'kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0" {2}' \
        | cut -f1
}

# ─── Step 2: cache check ──────────────────────────────────────────────────
if jq -e --arg slug "$slug" 'has($slug)' "$STORE" >/dev/null; then
    mapfile -t existing_models < <(jq -r --arg slug "$slug" '.[$slug].models | keys[]' "$STORE")
else
    existing_models=()
fi

if [[ ${#existing_models[@]} -gt 0 ]]; then
    step "Found ${#existing_models[@]} cached model(s): ${existing_models[*]}"

    # Ask WHAT the user wants to do first — no model-specific label yet,
    # so there's nothing that can render blank.
    choice=$(gum choose --header "how do you want to proceed?" \
        "Use an existing cached version" "Generate with a different model" "Pick a different gif")

    case "$choice" in
        "Use an existing"*)
            if [[ ${#existing_models[@]} -eq 1 ]]; then
                preview_model="${existing_models[0]}"
            else
                preview_model=$(pick_existing_model)
            fi
            preview_path=$(jq -r --arg slug "$slug" --arg m "$preview_model" '.[$slug].models[$m]' "$STORE")
            kitty +kitten icat --clear --transfer-mode=memory "$preview_path" 2>/dev/null
            final_gif="$preview_path"
            ;;
        "Generate with a different model")
            final_gif=$(pick_model_and_extract)
            ;;
        "Pick a different gif")
            exec "$0"
            ;;
    esac
else
    step "No cache entry yet for $slug — first time seeing this gif"
    final_gif=$(pick_model_and_extract)
fi

banner "Using: $(basename "$(dirname "$final_gif")")/$(basename "$final_gif")"

# ─── Step 3: display config ───────────────────────────────────────────────
step "Set display scale"
SCALE=$(gum input --placeholder "1.0" --value "1.0")
if ! [[ "$SCALE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    err "Invalid scale, defaulting to 1.0"
    SCALE="1.0"
fi

jq -n --arg gif "$final_gif" --argjson scale "$SCALE" \
    '{gif: $gif, scale: $scale}' > "$STATE_FILE"

# ─── Step 4: launch overlay ────────────────────────────────────────────────
step "Launching overlay"
pkill -f "quickshell.*overlay.qml" 2>/dev/null || true
sleep 0.2

ok "Mascot launched — close this terminal or Ctrl-C to stop it."
exec quickshell -p "$SCRIPT_DIR/../../overlay.qml"
