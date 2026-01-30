import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

print("\n=== running font_conv_for_lists.php ===", flush=True)
subprocess.run(
    ["php", str(BASE_DIR / "scripts" / "lvgl" / "font_conv_for_lists.php")],
    check=True
)

scripts = [
    "scripts/extract_res.py",
    "scripts/rewrite_src.py",
    "scripts/repack_res.py",
    "scripts/rewrite_c.py",
    "scripts/append_res.py",
]

for script in scripts:
    print(f"\n=== running {script} ===", flush=True)
    subprocess.run(
        [sys.executable, str(BASE_DIR / script)],
        check=True
    )
