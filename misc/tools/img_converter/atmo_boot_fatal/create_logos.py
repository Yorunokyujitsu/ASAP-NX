import os
from PIL import Image

def find_image(keyword):
    for file_name in os.listdir("../../../res/screens"):
        if keyword in file_name.lower():
            return os.path.join("../../../res/screens", file_name)
    return None

def generate_splash_screen_code():
    image_path = find_image("splash2")

    if image_path is None:
        print("Splash image not found!")
        return

    image = Image.open(image_path)
    width, height = image.size

    screen_width = 1280
    screen_height = 720

    center_x = screen_width // 2
    center_y = screen_height // 2

    SplashScreenX = center_x - (width // 2)
    SplashScreenY = center_y - (height // 2)

    output_folder = "../../../../contents/Atmosphere/stratosphere/boot/source"
    output_file = "boot_splash_screen_notext.inc"
    output_file_text = "boot_splash_screen_text.inc"
    output_path = os.path.join(output_folder, output_file)
    output_path_text = os.path.join(output_folder, output_file_text)
    print("Creation successful:", output_file)
    print("Creation successful:", output_file_text)

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    with open(output_path, "w", encoding='utf-8') as f_notext, open(output_path_text, "w", encoding='utf-8') as f_text:
        for f in [f_notext, f_text]:    
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
            f.write("static_assert(sizeof(SplashScreen) == sizeof(u32) * SplashScreenW * SplashScreenH, \"Incorrect SplashScreen definition!\");")

def generate_atmosphere_logo_code():
    image_path = find_image("fatal")

    if image_path is None:
        print("Fatal image not found!")
        return

    image = Image.open(image_path)
    width, height = image.size
    AtmosphereLogoWidth = hex(width)
    AtmosphereLogoHeight = hex(height)

    output_folder = "../../../../contents/Atmosphere/stratosphere/fatal/source"
    output_file = "fatal_ams_logo.inc"
    output_path = os.path.join(output_folder, output_file)
    print("Creation successful:", output_file) 

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    with open(output_path, "w", encoding='utf-8') as f:
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
        f.write(f"constexpr size_t AtmosphereLogoWidth = {AtmosphereLogoWidth};\n")
        f.write(f"constexpr size_t AtmosphereLogoHeight = {AtmosphereLogoHeight};\n")
        f.write("\n")
        f.write("static constexpr u16 AtmosphereLogoData[] = {\n")

        for y in range(height):
            for x in range(width):
                r, g, b, a = image.getpixel((x, y))
                pixel_value = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
                f.write(f"0x{pixel_value:04X}, ")
            f.write("\n")

        f.write("};\n")
        f.write("static_assert(util::size(AtmosphereLogoData) == AtmosphereLogoWidth * AtmosphereLogoHeight, \"Logo definition!\");")

generate_splash_screen_code()
generate_atmosphere_logo_code()