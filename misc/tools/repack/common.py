from pathlib import Path

def find_misc_dir(start: Path) -> Path:
    for p in (start, *start.parents):
        if p.name == "misc":
            return p
    raise RuntimeError("misc directory not found")

BASE_DIR = Path(__file__).resolve().parent

MISC_DIR = find_misc_dir(BASE_DIR)
ROOT_DIR = MISC_DIR.parent

BUILD_DIR   = BASE_DIR / "build"
SEG_DIR     = BUILD_DIR / "segments"
JSON_DIR    = BUILD_DIR / "json"
FONT_DIR    = BUILD_DIR / "fonts"
PREVIEW_DIR = BUILD_DIR / "preview"

RES_SRC = ROOT_DIR / "misc" / "res" / "misc" / "res.pak"
PAK_TMP = BUILD_DIR / "res.pak"

OFFSETS_JSON = JSON_DIR / "offsets.json"
REWRITE_JSON = JSON_DIR / "rewrite.json"

RES_LAUNCH_DIR = ROOT_DIR / "misc" / "res" / "launch"
RES_SCREEN_DIR = ROOT_DIR / "misc" / "res" / "screens"
RES_ICON_DIR   = ROOT_DIR / "misc" / "res" / "icons"

HEKATE_LOGO_PNG = RES_ICON_DIR / "info.png"

HEKATE_DIR  = ROOT_DIR / "contents" / "hekate"
LV_FONT_DIR = HEKATE_DIR / "bdk" / "libs" / "lvgl" / "lv_fonts"
NYX_GFX_DIR = HEKATE_DIR / "nyx" / "nyx_gui" / "gfx"

CUSTOM_DIR = NYX_GFX_DIR / "asap_custom.h"
LOGOS_DIR  = NYX_GFX_DIR / "logos-gui.h"

HEKATE_LOGO_BIN = SEG_DIR / "hekate_logo.bin"
FICHIERCLE_BIN  = BASE_DIR / "src" / "bin" / "fichiercle.bin"

SEG_DIR.mkdir(parents=True, exist_ok=True)
JSON_DIR.mkdir(parents=True, exist_ok=True)
FONT_DIR.mkdir(parents=True, exist_ok=True)
PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
