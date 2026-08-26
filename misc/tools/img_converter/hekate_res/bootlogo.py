from pathlib import Path
import re
import struct
from PIL import Image

LOGO_DIMENSIONS = (192, 68)
FRAME_DIMENSIONS = (68, 192)
FRAME_CAPACITY = FRAME_DIMENSIONS[0] * FRAME_DIMENSIONS[1]

CONVERTER_HOME = Path(__file__).resolve().parent
REPOSITORY_ROOT = CONVERTER_HOME.parents[3]

INPUT_LOGO = REPOSITORY_ROOT / "misc" / "res" / "icons" / "bootlogo.png"
INTERMEDIATE_BITMAP = CONVERTER_HOME / "bootlogo.bmp"
HEKATE_LOGOS = REPOSITORY_ROOT / "contents" / "hekate" / "bootloader" / "gfx" / "logos.c"

def render_indexed_asset() -> None:
    with Image.open(INPUT_LOGO) as source:
        if source.size != LOGO_DIMENSIONS:
            raise SystemExit(
                f"Invalid logo size: {source.width}x{source.height} "
                f"(required: {LOGO_DIMENSIONS[0]}x{LOGO_DIMENSIONS[1]})"
            )

        source = source.convert("RGBA").transpose(Image.Transpose.ROTATE_90)
        canvas = Image.new("RGBA", FRAME_DIMENSIONS, (0, 0, 0, 255))
        canvas.alpha_composite(source)
        rgb_data = canvas.convert("RGB").tobytes()

    pixels = bytearray(FRAME_CAPACITY)
    for pixel, offset in enumerate(range(0, len(rgb_data), 3)):
        pixels[pixel] = sum(rgb_data[offset:offset + 3]) // 3

    bitmap = Image.frombytes("P", FRAME_DIMENSIONS, bytes(pixels))
    bitmap.putpalette(bytes(channel for value in range(256) for channel in (value,) * 3))
    bitmap.save(INTERMEDIATE_BITMAP, "BMP")

def unpack_grayscale_frame() -> list[int]:
    bmp = INTERMEDIATE_BITMAP.read_bytes()
    if len(bmp) < 54 or bmp[:2] != b"BM":
        raise SystemExit("Generated file is not a valid BMP.")

    pixel_offset = struct.unpack_from("<I", bmp, 10)[0]
    dib_size = struct.unpack_from("<I", bmp, 14)[0]
    width, signed_height, planes, bpp, compression = struct.unpack_from("<iiHHI", bmp, 18)

    if (
        width != FRAME_DIMENSIONS[0]
        or abs(signed_height) != FRAME_DIMENSIONS[1]
        or planes != 1
        or bpp != 8
        or compression != 0
    ):
        raise SystemExit(
            f"Unsupported BMP: {width}x{signed_height}, "
            f"planes {planes}, {bpp}bpp, compression {compression}"
        )

    colors_used = struct.unpack_from("<I", bmp, 46)[0] or 256
    palette_offset = 14 + dib_size
    palette_end = palette_offset + colors_used * 4
    if palette_end > len(bmp) or pixel_offset > len(bmp):
        raise SystemExit("BMP palette or pixel offset is invalid.")

    palette = bmp[palette_offset:palette_end]
    stride = ((width * bpp + 31) // 32) * 4
    height = abs(signed_height)
    pixel_end = pixel_offset + stride * height
    if pixel_end > len(bmp):
        raise SystemExit("BMP pixel data is incomplete.")

    output: list[int] = []
    for y in range(height):
        stored_y = y if signed_height < 0 else height - y - 1
        row_start = pixel_offset + stored_y * stride
        for index in bmp[row_start:row_start + width]:
            if index >= colors_used:
                raise SystemExit(f"BMP palette index {index} is out of range.")

            blue, green, red, _ = palette[index * 4:index * 4 + 4]
            output.append((red + green + blue) // 3)

    if len(output) != FRAME_CAPACITY:
        raise SystemExit(f"Invalid pixel count: {len(output)} (required: {FRAME_CAPACITY})")

    return output

def serialize_initializer(pixels: list[int]) -> str:
    rows = []
    for start in range(0, len(pixels), 16):
        values = ", ".join(f"0x{value:02X}" for value in pixels[start:start + 16])
        rows.append(f"\t{values},")

    return "u8 bootlogo[] = {\n" + "\n".join(rows) + "\n};"

def replace_or_verify(
    source: str,
    pattern: str,
    replacement: str,
    expected: str,
    description: str,
) -> str:
    source, replacements = re.subn(pattern, replacement, source, count=1, flags=re.MULTILINE)
    if replacements == 0 and expected not in source:
        raise SystemExit(f"{description} was not found in logos.c.")

    return source

def inject_builtin_logo(pixels: list[int]) -> None:
    source = HEKATE_LOGOS.read_text(encoding="utf-8")

    logo_declaration = re.compile(
        r"u8\s+bootlogo(?:_blz)?\[\]\s*=\s*\{.*?\n\};",
        re.DOTALL,
    )
    source, replacements = logo_declaration.subn(
        serialize_initializer(pixels),
        source,
        count=1,
    )
    if replacements != 1:
        raise SystemExit("Built-in bootlogo array was not found in logos.c.")

    source = re.sub(
        r"^#define\s+BOOTLOGO_BLZ_SIZE\s+\d+\s*\r?\n",
        "",
        source,
        count=1,
        flags=re.MULTILINE,
    )

    old_renderer = re.compile(
        r"blz_uncompress_srcdest\(\s*bootlogo_blz\s*,\s*"
        r"sizeof\s*\(\s*bootlogo_blz\s*\)\s*,\s*"
        r"logo_buf\s*,\s*BOOTLOGO_SIZE\s*\);"
    )
    source, replacements = old_renderer.subn(
        "memcpy(logo_buf, bootlogo, BOOTLOGO_SIZE);",
        source,
        count=1,
    )
    if replacements == 0 and "memcpy(logo_buf, bootlogo, BOOTLOGO_SIZE);" not in source:
        raise SystemExit("Bootlogo renderer was not found in logos.c.")

    required_defines = {
        "BOOTLOGO_WIDTH": 68,
        "BOOTLOGO_HEIGHT": 192,
        "BOOTLOGO_SIZE": 13056,
    }
    for name, expected in required_defines.items():
        match = re.search(rf"^#define\s+{name}\s+(\d+)\s*$", source, re.MULTILINE)
        if not match or int(match.group(1)) != expected:
            raise SystemExit(f"{name} must be defined as {expected}.")

    source = replace_or_verify(
        source,
        r"gfx_clear_grey\s*\(\s*0x1B\s*\);",
        "gfx_clear_grey(0x00);",
        "gfx_clear_grey(0x00);",
        "Static bootlogo background",
    )
    source = replace_or_verify(
        source,
        r"memset\s*\(\s*grey\s*,\s*0x1B\s*,\s*6\s*\*\s*BOOTLOGO_HEIGHT\s*\);",
        "memset(grey, 0x00, 6 * BOOTLOGO_HEIGHT);",
        "memset(grey, 0x00, 6 * BOOTLOGO_HEIGHT);",
        "Ticker clear color",
    )
    source = replace_or_verify(
        source,
        r"gfx_set_rect_grey\s*\(\s*grey\s*,\s*6\s*,\s*BOOTLOGO_HEIGHT\s*,\s*362\s*,\s*BOOTLOGO_Y\s*\);",
        "gfx_set_rect_grey(grey, 6, BOOTLOGO_HEIGHT, 368, BOOTLOGO_Y);",
        "gfx_set_rect_grey(grey, 6, BOOTLOGO_HEIGHT, 368, BOOTLOGO_Y);",
        "Ticker clear position",
    )
    source = replace_or_verify(
        source,
        (
            r"gfx_set_rect_grey\s*\(\s*logo_buf\s*\+\s*BOOTLOGO_WIDTH\s*\*\s*"
            r"\(\s*BOOTLOGO_HEIGHT\s*-\s*i\s*\)\s*\+\s*36\s*,\s*6\s*,\s*1\s*,\s*"
            r"362\s*,\s*BOOTLOGO_Y\s*\+\s*BOOTLOGO_HEIGHT\s*-\s*i\s*\);"
        ),
        (
            "gfx_set_rect_grey(logo_buf + BOOTLOGO_WIDTH * "
            "(BOOTLOGO_HEIGHT - i) + 42, 6, 1, 368, "
            "BOOTLOGO_Y + BOOTLOGO_HEIGHT - i);"
        ),
        (
            "gfx_set_rect_grey(logo_buf + BOOTLOGO_WIDTH * "
            "(BOOTLOGO_HEIGHT - i) + 42, 6, 1, 368, "
            "BOOTLOGO_Y + BOOTLOGO_HEIGHT - i);"
        ),
        "Ticker progress position",
    )

    HEKATE_LOGOS.write_text(source, encoding="utf-8", newline="")

def audit_generated_source() -> None:
    source = HEKATE_LOGOS.read_text(encoding="utf-8")
    match = re.search(
        r"u8\s+bootlogo\[\]\s*=\s*\{(.*?)\n\};",
        source,
        re.DOTALL,
    )
    count = len(re.findall(r"0x[0-9A-Fa-f]{2}", match.group(1))) if match else 0

    if count != FRAME_CAPACITY:
        raise SystemExit(f"Generated bootlogo[] has {count} bytes, expected {FRAME_CAPACITY}.")

    if "bootlogo_blz[]" in source or "BOOTLOGO_BLZ_SIZE" in source:
        raise SystemExit("Legacy compressed bootlogo data still remains in logos.c.")

    if "u8 battery_icons_blz[]" not in source:
        raise SystemExit("battery_icons_blz[] was unexpectedly removed.")

    required_renderer_code = (
        "gfx_clear_grey(0x00);",
        "memset(grey, 0x00, 6 * BOOTLOGO_HEIGHT);",
        "gfx_set_rect_grey(grey, 6, BOOTLOGO_HEIGHT, 368, BOOTLOGO_Y);",
        (
            "gfx_set_rect_grey(logo_buf + BOOTLOGO_WIDTH * "
            "(BOOTLOGO_HEIGHT - i) + 42, 6, 1, 368, "
            "BOOTLOGO_Y + BOOTLOGO_HEIGHT - i);"
        ),
        "memcpy(logo_buf, bootlogo, BOOTLOGO_SIZE);",
    )
    for required in required_renderer_code:
        if required not in source:
            raise SystemExit(f"Required renderer code is missing: {required}")

def execute_conversion() -> None:
    for required in (INPUT_LOGO, HEKATE_LOGOS):
        if not required.is_file():
            raise SystemExit(f"Required file not found: {required}")

    render_indexed_asset()
    pixels = unpack_grayscale_frame()
    inject_builtin_logo(pixels)
    audit_generated_source()
    print("Converted: logos.c")

if __name__ == "__main__":
    execute_conversion()