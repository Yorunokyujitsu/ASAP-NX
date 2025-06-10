#!/usr/bin/env python3
import os
import sys
from glob import glob
from PIL import Image

def convert_profile_image(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    scale = max(365 / w, 365 / h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    img = img.resize((new_w, new_h), resample=Image.Resampling.LANCZOS)
    left = (new_w - 365) // 2
    top  = (new_h - 365) // 2
    img = img.crop((left, top, left + 365, top + 365))
    img.save(output_path, format="BMP")
    print(f"Converted: '{input_path}' → '{output_path}' (365×365 True Color + Alpha BMP)")

def convert_background_image(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    target_w, target_h = 1280, 720
    scale = max(target_w / w, target_h / h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    img = img.resize((new_w, new_h), resample=Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top  = (new_h - target_h) // 2
    img = img.crop((left, top, left + target_w, top + target_h))
    img.save(output_path, format="BMP")
    print(f"Converted: '{input_path}' → '{output_path}' (1280×720 True Color + Alpha BMP)")

def main():
    if getattr(sys, 'frozen', False):
        base_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))

    patterns = [
        ('profile.*', convert_profile_image),
        ('background.*', convert_background_image),
    ]
    found = False

    for pattern, func in patterns:
        for filepath in glob(os.path.join(base_dir, pattern)):
            ext = os.path.splitext(filepath)[1].lower()
            if ext == '.bmp':
                continue
            name = os.path.splitext(os.path.basename(filepath))[0]
            out_path = os.path.join(base_dir, f"{name}.bmp")
            func(filepath, out_path)
            found = True

    if not found:
        print("Not found 'profile', 'background' img files.")

if __name__ == '__main__':
    main()
