#!/usr/bin/env bash
set -euo pipefail

# Default config
: "${TOP_DIR:?TOP_DIR not set}"
: "${APP_DIR:?APP_DIR not set}"
: "${MISC_DIR:?MISC_DIR not set}"

source "${MISC_DIR}/scripts/config/log.sh"

# Enable switch
if [[ "${ENABLE_CUSTOM:-0}" != "1" ]]; then
  print_title "Custom patch skipped!"
  exit 0
fi

# zipper path
LINKALHO="${APP_DIR}/linkalho/lib/"

# libultrahand path
LIB_PATHS=(
  "EdiZon-Overlay/libs/"
  "NX-FanControl/overlay/lib/"
  "ovl-sysmodules/libs/"
  "ReverseNX-RT/Overlay/libs/"
  "Status-Monitor-Overlay/lib/"
  "sys-clk/overlay/lib/"
  "sys-patch/overlay/"
  "Ultrahand-Overlay/lib/"
)

# Helpers
replace_with_ultrahand() {
  local base="$1"
  local ultra="${APP_DIR}/${base}/libultrahand"
  local tesla="${APP_DIR}/${base}/libtesla"

  [[ -d "${APP_DIR}/${base}" ]] || return 0

  echo "Replace: ${base}libultrahand"

  rm -rf "$ultra" "$tesla"

  git clone --recursive --quiet -b test \
    https://github.com/Yorunokyujitsu/libultrahand \
    "$ultra" \
    || { echo "[ERROR] clone failed"; exit 1; }

  ln -snf libultrahand "$tesla"
}

replace_linkalho_libs() {
  local base="$1"

  [[ -d "$base" ]] || return 0

  echo "Replace: linkalho/lib/zipper"

  rm -rf "${base}zipper"
  mkdir -p "$base"

  git clone --recursive --quiet \
    https://github.com/HamletDuFromage/zipper \
    "${base}zipper"
}

safe_rm() {
  for p in "$@"; do
    [[ -e "$p" ]] && rm -rf "$p"
  done
}

# Replacement - libultrahand, zipper
print_title "[1/4] Libraries replacement"
echo

for base in "${LIB_PATHS[@]}"; do
  replace_with_ultrahand "$base"
done

if [[ -d "${LINKALHO}" ]]; then
  replace_linkalho_libs "${LINKALHO}"
fi

echo

# Rename - TegraExplorer
print_title "[2/4] Rename TegraExplorer > ATLAS (ASAP-Updater)"
echo

if [[ -d "${APP_DIR}/ASAP-Updater/TegraExplorer" ]]; then
  echo "Renamed: TegraExplorer > ATLAS"

  rm -rf "${APP_DIR}/ASAP-Updater/ATLAS"
  mv "${APP_DIR}/ASAP-Updater/TegraExplorer" \
     "${APP_DIR}/ASAP-Updater/ATLAS"
fi

echo

# Cleanup
print_title "[3/4] Cleanup some repos"
echo

safe_rm \
  "${APP_DIR}/ASAP-Updater/ATLAS/scripts/FirmwareDump.te" \
  "${APP_DIR}/ASAP-Updater/ATLAS/scripts/SystemWipe.te" \
  "${APP_DIR}/ASAP-Updater/ATLAS/tools/bin2c/bin2c" \
  "${APP_DIR}/ASAP-Updater/ATLAS/tools/lz/lz77" \
  "${APP_DIR}/ASAP-Updater/resources/i18n" \
  "${APP_DIR}/ASAP-Updater/aiosu-forwarder" \
  "${APP_DIR}/ASAP-Updater/include/download_payload_page.hpp" \
  "${APP_DIR}/ASAP-Updater/include/hide_tabs_page.hpp" \
  "${APP_DIR}/ASAP-Updater/include/net_page.hpp" \
  "${APP_DIR}/ASAP-Updater/include/payload_page.hpp" \
  "${APP_DIR}/ASAP-Updater/source/download_payload_page.cpp" \
  "${APP_DIR}/ASAP-Updater/source/hide_tabs_page.cpp" \
  "${APP_DIR}/ASAP-Updater/source/net_page.cpp" \
  "${APP_DIR}/ASAP-Updater/source/payload_page.cpp" \
  "${APP_DIR}/ASAP-Updater/resources/deepsea_icon.png"

safe_rm \
  "${APP_DIR}/sphaira/assets/romfs/github/sphaira.json"

# Extract NX.7z
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

echo "Done"
echo

# Patch resources
print_title "[4/4] Resource processing"
echo

# Atmosphere boot, fatal logo conversion
python "${MISC_DIR}/tools/img_converter/ams_res/ams_img_conv.py"

# AmiiboGenerator
AMIIBO_HDR="${APP_DIR}/AmiiboGenerator/source/amiibo.hpp"

if [[ -f "$AMIIBO_HDR" ]]; then
  echo "Fix incorrect header include"
  sed -i 's/#include[[:space:]]*"UTIL.hpp"/#include "util.hpp"/' "$AMIIBO_HDR"
fi

# Copy LVGL Korean fonts into Hekate
if [[ -d "${MISC_DIR}/tools/lvgl_utils/output" ]]; then
  cp -r "${MISC_DIR}/tools/lvgl_utils/output/"* \
    "${APP_DIR}/hekate/bdk/libs/lvgl/lv_fonts" || true
fi

# Icon replacements
cp -f "${MISC_DIR}/res/icons/sphaira_icon.jpg" \
  "${APP_DIR}/sphaira/assets/icon.jpg" || true

cp -f "${MISC_DIR}/res/icons/updater_icon.jpg" \
  "${APP_DIR}/ASAP-Updater/icon.jpg" || true

cp -f "${MISC_DIR}/res/icons/updater_sub_icon.png" \
  "${APP_DIR}/ASAP-Updater/resources/gui_icon.png" || true

echo "Done"
echo
