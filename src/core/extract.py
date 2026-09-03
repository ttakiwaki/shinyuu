import sys

from PIL import Image, ImageSequence
from rembg import remove
from rembg.session_factory import new_session


def extract_frames(gif_path):
    img = Image.open(gif_path)
    frames = []

    session = new_session("u2net")

    # for frame in ImageSequence.Iterator(img):
    frame_rgba = img.convert("RGBA")
    frames.append(remove(frame_rgba, session=session))

    return frames


if __name__ == "__main__":
    frames = extract_frames(sys.argv[1])
    print(f"Extracted {len(frames)} frames")
    frames[0].save("alya.png")
