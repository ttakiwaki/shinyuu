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


def extract_frames(gif_path):
    img = Image.open(gif_path)
    frames = []

    session = new_session("u2net")  # isnet-anime

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


if __name__ == "__main__":
    frames = extract_frames(sys.argv[1])
    output_folder = Path("output/")
    output_folder.mkdir(parents=True, exist_ok=True)
    print(f"Extracted {len(frames)} frames")

    frames_duration = []
    # Output cutout frames
    for i, frame in enumerate(frames):
        filepath = output_folder / f"frame_{i}.png"
        frame[0].save(filepath)

        # Build list (duration)
        frames_duration.append(frame[1])

    # Output JSON containing index, duration
    json_filepath = output_folder / "durations.json"
    with open(json_filepath, "w") as json_file:
        json.dump((frames_duration), json_file, indent=4)

    frames = [
        Image.open(output_folder / f"frame_{i}.png")
        for i in range(len(frames_duration))
    ]
    frames[0].save(
        "preview.gif",
        save_all=True,
        append_images=frames[1:],
        duration=frames_duration,
        loop=0,
        disposal=2,
    )
