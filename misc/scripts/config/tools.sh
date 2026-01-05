#!/usr/bin/env bash
set -euo pipefail

# Default config
: "${TOP_DIR:?TOP_DIR not set}"
: "${APP_DIR:?APP_DIR not set}"
: "${MISC_DIR:?MISC_DIR not set}"

source "${MISC_DIR}/scripts/config/log.sh"

# Enable switch
if [[ "${ENABLE_BUILD_TOOLS:-0}" != "1" ]]; then
  print_title "build_tools.sh skipped!"
  exit 0
fi

command -v 7z >/dev/null || { echo "[ERROR] 7z not found in PATH"; exit 1; }
command -v pyinstaller >/dev/null || { echo "[ERROR] pyinstaller not found"; exit 1; }

# Extract 7z
print_title "[1/3] Extract NX.7z"
echo

NX_7Z="${APP_DIR}/NX.7z"

if [[ -f "${NX_7Z}" ]]; then
  if [[ -z "${PW_VERIFY:-}" ]]; then
    exit 1
  fi

  echo "[INFO] Extracting ${NX_7Z}"
  7z x -aoa -y -bsp0 -bso0 -bse0 \
    -p"${PW_VERIFY}" \
    "${NX_7Z}" -o"${APP_DIR}" \
    || { echo "[ERROR] Extract NX.7z failed"; exit 1; }

  cp -a "${APP_DIR}/misc/." "${TOP_DIR}/misc/"
else
  echo "[INFO] NX.7z not found, skipping"
fi

echo "Extracted NX.7z"
echo

# IMG2BMP
print_title "[2/3] Build IMG2BMP.exe"
echo

IMG2BMP_DIR="${MISC_DIR}/tools/img_converter/hekate_res"
[[ -d "${IMG2BMP_DIR}" ]] || {
  echo "[ERROR] IMG2BMP source dir not found: ${IMG2BMP_DIR}"
  exit 1
}

cd "${IMG2BMP_DIR}"

pyinstaller --clean -F -w -n IMG2BMP \
  --icon "${MISC_DIR}/res/icons/bmp_256x256.ico" \
  --distpath "${MISC_DIR}/tools/output" \
  "./con2bmp.py"

echo
echo "IMG2BMP build completed"
echo

# ASAP Installer
print_title "[3/3] Build ASAP.exe"
echo

ASAP_DIR="${MISC_DIR}/tools/installer"
[[ -d "${ASAP_DIR}" ]] || {
  echo "[ERROR] ASAP installer dir not found: ${ASAP_DIR}"
  exit 1
}

cd "${ASAP_DIR}"

pyinstaller --clean --noupx -F -w -n ASAP \
  --version-file=./source/scripts/detail_info.py \
  --icon "${MISC_DIR}/res/icons/installer_256x256.ico" \
  --add-data "./source/scripts:./source/scripts" \
  --add-data "./source/base64:./source/base64" \
  --add-data "./source/scripts/fat32format.exe:." \
  --add-data "./LICENSE:./" \
  --distpath "${MISC_DIR}/tools/output" \
  ./main.py

echo
echo "ASAP-Installer build completed"
echo
echo "Done"