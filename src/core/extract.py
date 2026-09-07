# extract.py
"""
Starts by breaking the provided gif into frames & durations. Then extracts the background
from each frame and accurately rebuilds the gif with a transparent background.
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageSequence
from rembg import remove
from rembg.session_factory import new_session


def extract_frames(gif_path, model="u2net"):
    img = Image.open(gif_path)
    frames = []
    session = new_session(model)
    for frame in ImageSequence.Iterator(img):
        frame_rgba = frame.convert("RGBA")
        frame_duration = frame.info.get("duration", 100)
        frames.append(
            (
                remove(
                    frame_rgba,
                    session=session,
                ),
                frame_duration,
            )
        )
    return frames


def update_store(store_path: Path, slug: str, model: str, preview_path: Path):
    store_path.parent.mkdir(parents=True, exist_ok=True)

    if store_path.exists() and store_path.stat().st_size > 0:
        with open(store_path) as f:
            try:
                store = json.load(f)
            except json.JSONDecodeError:
                store = {}
    else:
        store = {}

    store.setdefault(slug, {}).setdefault("models", {})[model] = str(preview_path)

    with open(store_path, "w") as f:
        json.dump(store, f, indent=2)


if __name__ == "__main__":
    gif_path = sys.argv[1]
    output_folder = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("output/")
    model = sys.argv[3] if len(sys.argv) > 3 else "u2net"
    store_path = (
        Path(sys.argv[4])
        if len(sys.argv) > 4
        else Path.home() / ".config" / "shinyuu" / "gif_store.json"
    )

    slug = Path(gif_path).stem

    frames = extract_frames(gif_path, model)
    output_folder.mkdir(parents=True, exist_ok=True)
    print(f"Extracted {len(frames)} frames")
    frames_duration = []
    # Output cutout frames
    for i, frame in enumerate(frames):
        filepath = output_folder / f"frame_{i}.png"
        frame[0].save(filepath)
        # Build list (duration)
        frames_duration.append(frame[1])
    frames = [
        Image.open(output_folder / f"frame_{i}.png")
        for i in range(len(frames_duration))
    ]
    preview_path = output_folder / "preview.gif"
    frames[0].save(
        preview_path,
        save_all=True,
        append_images=frames[1:],
        duration=frames_duration,
        loop=0,
        disposal=2,
    )

    update_store(store_path, slug, model, preview_path)
    print(f"Updated store: {store_path}")
