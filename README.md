# shinyuu

A Linux desktop mascot overlay for Hyprland/Wayland — cuts a character out of an animated GIF (background removed via `rembg`) and floats it, click-through, in the corner of your screen.

## How it works

1. Point `shinyuu` at a folder of your GIFs.
2. Pick one via an `fzf` picker with a live image preview.
3. If it's never been processed before, choose a background-removal model and extract it.
4. The cutout is cached (keyed by filename) so you don't have to re-extract next time — you can also preview and reuse previously-generated versions, or regenerate with a different model.
5. Set a display scale, and the mascot appears as a transparent, click-through overlay anchored to the bottom-right of your screen via Quickshell/QML.

## Architecture

```
interact.sh (fzf + gum TUI)
    │
    ├── checks gif_store.json
    │
    ├── extract.py (rembg background removal + GIF re-encode)
    │       writes
    │       updates
    ├── writes 
    │
    └── launches → overlay.qml (Quickshell/QML)
```

## System Prerequisites (Arch Linux)

Before running the project with GPU acceleration, ensure system CUDA and cuDNN drivers are installed:

```bash
sudo pacman -S nvidia cuda cudnn quickshell jq fzf gum kitty uv
```

## Python Dependencies

Declared in `pyproject.toml`:

```toml
dependencies = [
    "rembg",
    "pillow",
    "onnxruntime-gpu",
    "pathlib"
]
```

Install with:

```bash
uv sync
```

## Project Structure

```
shinyuu/
├── overlay.qml              # Quickshell/QML overlay — reads state.json, renders the mascot
├── pyproject.toml
├── src/
│   └── core/
│       ├── extract.py       # GIF → transparent cutout GIF (rembg)
│       └── interact.sh      # TUI entry point (fzf + gum)
└── README.md
```

## Background-removal models

Available via `rembg`, selectable per-GIF:

| Model | Best for |
|---|---|
| `isnet-anime` | Anime/illustrated characters — best edge handling on line art and hair |
| `u2net_human_seg` | Real people / photos |
| `isnet-general-use` | General-purpose fallback |
| `u2net` | Default rembg model — hit or miss depending on art style |

Different models can be tried per-GIF and are cached separately, so you can compare results without re-running extraction from scratch.
