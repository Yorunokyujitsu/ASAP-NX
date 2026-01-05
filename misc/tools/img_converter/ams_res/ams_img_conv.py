# requirements ( pip install pillow numpy )
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

# image file path = script path
SCRIPT_DIR = Path(__file__).resolve().parent
RES_DIR = SCRIPT_DIR.parents[2] / "res" / "screens"
CONTENTS_ROOT = SCRIPT_DIR.parents[3] / "contents"
OUT_BOOT_DIRS = [
    CONTENTS_ROOT / "Atmosphere" / "stratosphere" / "boot" / "source",
    CONTENTS_ROOT / "Atmosphere_8GB" / "stratosphere" / "boot" / "source",
]
OUT_FATAL_DIRS = [
    CONTENTS_ROOT / "Atmosphere" / "stratosphere" / "fatal" / "source",
    CONTENTS_ROOT / "Atmosphere_8GB" / "stratosphere" / "fatal" / "source",
]
OUT_IMG_DIRS = [
    CONTENTS_ROOT / "Atmosphere" / "img",
    CONTENTS_ROOT / "Atmosphere_8GB" / "img",
]
ALLOWED_EXTS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}

# insert license header (fatal, notext, text)
def write_header(f):
    f.write("/*\n")
    f.write(" * Copyright (c) Atmosphère-NX\n")
    f.write(" *\n")
    f.write(" * This program is free software; you can redistribute it and/or modify it\n")
    f.write(" * under the terms and conditions of the GNU General Public License,\n")
    f.write(" * version 2, as published by the Free Software Foundation.\n")
    f.write(" *\n")
    f.write(" * This program is distributed in the hope it will be useful, but WITHOUT\n")
    f.write(" * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or\n")
    f.write(" * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for\n")
    f.write(" * more details.\n")
    f.write(" *\n")
    f.write(" * You should have received a copy of the GNU General Public License\n")
    f.write(" * along with this program.  If not, see <http://www.gnu.org/licenses/>.\n")
    f.write(" */\n")

# serch image file
def find_image_exact_stem(stem: str) -> str | None:
    matches = []
    if not RES_DIR.exists():
        return None
    for name in os.listdir(RES_DIR):
        p = RES_DIR / name
        if p.is_file() and p.suffix.lower() in ALLOWED_EXTS and p.stem.lower() == stem.lower():
            matches.append(p)
    if not matches:
        return None
    if len(matches) > 1:
        raise RuntimeError(
            f"Multiple '{stem}.*' files found in {RES_DIR}: " + ", ".join(m.name for m in matches)
        )
    return str(matches[0])

# boot_splash base config
def boot_splash_base(image, width, height, SplashScreenX, SplashScreenY, folder: Path):
    folder.mkdir(parents=True, exist_ok=True)
    out_notext = folder / "boot_splash_screen_notext.inc"
    out_text   = folder / "boot_splash_screen_text.inc"

    with open(out_notext, "w", encoding="utf-8") as f_notext, open(out_text, "w", encoding="utf-8") as f_text:
        for f in (f_notext, f_text):
            write_header(f)
            f.write(f"constexpr size_t SplashScreenX = {SplashScreenX};\n")
            f.write(f"constexpr size_t SplashScreenY = {SplashScreenY};\n")
            f.write(f"constexpr size_t SplashScreenW = {width};\n")
            f.write(f"constexpr size_t SplashScreenH = {height};\n\n")
            f.write("constexpr u32 SplashScreen[] = {\n")
            for y in range(height):
                for x in range(width):
                    r, g, b, a = image.getpixel((x, y))
                    pixel_value = (0xFF << 24) | (r << 16) | (g << 8) | b
                    f.write(f"0x{pixel_value:08X}, ")
                f.write("\n")
            f.write("};\n")
            f.write(
                "static_assert(sizeof(SplashScreen) == sizeof(u32) * SplashScreenW * SplashScreenH, "
                "\"Incorrect SplashScreen definition!\");"
            )

# convert boot_splash image file to include file
def gen_boot_splash() -> list[str]:
    image_path = find_image_exact_stem("boot_splash")
    if image_path is None:
        print(f"'boot_splash.*' image not found in: {RES_DIR}")
        return []
    image = Image.open(image_path).convert("RGBA")
    width, height = image.size

    screen_width, screen_height = 1280, 720
    center_x, center_y = screen_width // 2, screen_height // 2
    SplashScreenX = center_x - (width // 2)
    SplashScreenY = center_y - (height // 2)

    out_names: list[str] = []
    for folder in OUT_BOOT_DIRS:
        boot_splash_base(image, width, height, SplashScreenX, SplashScreenY, folder)
        out_names += ["boot_splash_screen_notext.inc", "boot_splash_screen_text.inc"]
    return out_names

# convert fatal image file to include file
def gen_fatal_logo() -> list[str]:
    image_path = find_image_exact_stem("fatal")
    if image_path is None:
        print(f"'fatal.*' image not found in: {RES_DIR}")
        return []
    image = Image.open(image_path).convert("RGBA")
    width, height = image.size

    out_names: list[str] = []
    for folder in OUT_FATAL_DIRS:
        folder.mkdir(parents=True, exist_ok=True)
        out = folder / "fatal_ams_logo.inc"
        with open(out, "w", encoding="utf-8") as f:
            write_header(f)
            f.write(f"constexpr size_t AtmosphereLogoWidth = {width};\n")
            f.write(f"constexpr size_t AtmosphereLogoHeight = {height};\n\n")
            f.write("static constexpr u16 AtmosphereLogoData[] = {\n")
            for y in range(height):
                for x in range(width):
                    r, g, b, a = image.getpixel((x, y))
                    pixel_value = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
                    f.write(f"0x{pixel_value:04X}, ")
                f.write("\n")
            f.write("};\n")
            f.write(
                "static_assert(sizeof(AtmosphereLogoData) / sizeof(u16) == "
                "AtmosphereLogoWidth * AtmosphereLogoHeight, \"Logo definition!\");"
            )
        out_names.append("fatal_ams_logo.inc")
    return out_names

def convert_splash_image(image_fn: str) -> bytes:
    img = Image.open(image_fn).convert("RGBA")
    img = ImageOps.exif_transpose(img)

    w, h = img.size
    if (w, h) == (1280, 720):
        img = img.transpose(Image.ROTATE_90)
        w, h = img.size

    if (w, h) != (720, 1280):
        raise ValueError(f"Input must be 720x1280 or 1280x720. Got {w}x{h}.")

    arr = np.array(img, dtype=np.uint8)
    b, g, r, a = arr[..., 2], arr[..., 1], arr[..., 0], arr[..., 3]
    bgra = np.dstack((b, g, r, a))

    pad_px = 768 - 720
    if pad_px > 0:
        pad_block = np.zeros((1280, pad_px, 4), dtype=np.uint8)
        bgra = np.concatenate([bgra, pad_block], axis=1)

    return bgra.tobytes()

# convert splash image file to binary file
def gen_splash_bin() -> list[str]:
    image_path = find_image_exact_stem("splash")
    if image_path is None:
        print(f"'splash.*' image not found in: {RES_DIR}")
        return []

    splash_bin = convert_splash_image(image_path)
    if len(splash_bin) != 0x3C0000:
        print(f"Error: splash size invalid (expected 0x3C0000). Got {len(splash_bin):#x}")
        return []

    out_names: list[str] = []
    for folder in OUT_IMG_DIRS:
        folder.mkdir(parents=True, exist_ok=True)
        out_path = folder / "splash.bin"
        with open(out_path, "wb") as f:
            f.write(splash_bin)
        out_names.append("splash.bin")
    return out_names

# python ./ams_img_conv.py [boot|fatal|splash]
def main(argv: list[str]) -> int:
    cmds = [a.lower() for a in argv[1:]]
    run_all = (len(cmds) == 0) or ("all" in cmds)

    valid = {"boot", "fatal", "splash", "all"}
    if not run_all:
        unknown = [c for c in cmds if c not in valid]
        if unknown:
            exe = Path(argv[0]).name
            print("Usage:")
            print(f"  {exe}          # run all (boot+fatal+splash)")
            print(f"  {exe} boot     # boot_splash.* -> boot_splash_screen_*.inc")
            print(f"  {exe} fatal    # fatal.*       -> fatal_ams_logo.inc")
            print(f"  {exe} splash   # splash.*      -> splash.bin")
            return 1

    to_run = {"boot", "fatal", "splash"} if run_all else set(cmds) & {"boot", "fatal", "splash"}

    generated: list[str] = []

    if "boot" in to_run:
        generated += gen_boot_splash()
    if "fatal" in to_run:
        generated += gen_fatal_logo()
    if "splash" in to_run:
        generated += gen_splash_bin()

    if generated:
        print("Converted:")
        for name in sorted(set(generated)):
            print(f"  - {name}")

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
