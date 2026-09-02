import sys

from PIL import Image, ImageSequence
from rembg import remove


def extract_frames(gif_path):
    img = Image.open(gif_path)
    frames = []

    for frame in ImageSequence.Iterator(img):
        frames.append(remove(frame))

    return frames


if __name__ == "__main__":
    frames = extract_frames(sys.argv[1])
    print(f"Extracted {len(frames)} frames!")
