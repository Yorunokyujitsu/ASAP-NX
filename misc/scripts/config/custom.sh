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
  #"FPSLocker/libs/"
  "NX-FanControl/overlay/lib/"
  "ovl-sysmodules/libs/"
  "ReverseNX-RT/Overlay/libs/"
  "Status-Monitor-Overlay/lib/"
  "Ultrahand-Overlay/lib/"
  "Horizon-OC/Source/hoc-clk/overlay/lib/"
)

# Helpers
safe_rm() {
  for p in "$@"; do
    [[ -e "$p" ]] && rm -rf "$p"
  done
}

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

apply_main_diff_patches() {
  shopt -s nullglob

  for patch in "${MISC_DIR}/diff/main"/*.patch; do
    local name
    local target

    name="$(basename "${patch}" .patch)"
    target="${APP_DIR}/${name}"

    if [[ ! -d "${target}" ]]; then
      echo "Skip: ${name}.patch (target not found)"
      continue
    fi

    printf "Apply: %s.patch..." "${name}"

    if (
      cd "${target}"
      git apply --3way --ignore-whitespace --whitespace=nowarn "${patch}" >/dev/null 2>&1
    ); then
      echo "Done"
    else
      echo "Failed"
      echo "[ERROR] Failed to apply patch: ${patch}"
      exit 1
    fi
  done

  shopt -u nullglob
}

apply_libs_diff_patches() {
  shopt -s nullglob

  declare -A LIB_PATCH_MAP=(
    ["libfancontrol"]="${APP_DIR}/NX-FanControl/lib/libfancontrol"
    ["borealis"]="${APP_DIR}/linkalho/lib/borealis"
    ["zipper"]="${APP_DIR}/linkalho/lib/zipper"
  )

  for patch in "${MISC_DIR}/diff/libs"/*.patch; do
    local name
    local target

    name="$(basename "${patch}" .patch)"
    target="${LIB_PATCH_MAP[${name}]:-}"

    if [[ -z "${target}" || ! -d "${target}" ]]; then
      echo "Skip: ${name}.patch (target not found)"
      continue
    fi

    printf "Apply: %s.patch..." "${name}"

    if (
      cd "${target}"
      git apply --3way --ignore-whitespace --whitespace=nowarn "${patch}" >/dev/null 2>&1
    ); then
      echo "Done"
    else
      echo "Failed"
      echo "[ERROR] Failed to apply patch: ${patch}"
      exit 1
    fi
  done

  shopt -u nullglob
}


# ASAP Patch Process
# Diff patch
print_title "[1/7] Patch repositories"
echo
apply_main_diff_patches
echo


# Replacement - libultrahand, zipper
print_title "[2/7] Libraries replacement"
echo

for base in "${LIB_PATHS[@]}"; do
  replace_with_ultrahand "$base"
done

if [[ -d "${LINKALHO}" ]]; then
  replace_linkalho_libs "${LINKALHO}"
fi

# Rename - TegraExplorer
echo "Renamed: TegraExplorer > ATLAS"
if [[ -d "${APP_DIR}/ASAP-Updater/TegraExplorer" ]]; then
  mv "${APP_DIR}/ASAP-Updater/TegraExplorer" \
     "${APP_DIR}/ASAP-Updater/ATLAS"
fi
echo "Done"
echo


# libraries patch
print_title "[3/7] Patch libraries"
echo
apply_libs_diff_patches
echo


# Cleanup
print_title "[4/7] Cleanup repositories"
echo

# atmosphere
safe_rm \
  "${APP_DIR}/Atmosphere/stratosphere/loader/source/ldr_embedded_am_patches.inc" \
  "${APP_DIR}/Atmosphere/stratosphere/loader/source/ldr_embedded_usb_patches.inc"
echo "Deleted: embedded patches inc"

# aio-switch-updater
safe_rm \
  "${APP_DIR}/ASAP-Updater/ATLAS/scripts/FirmwareDump.te" \
  "${APP_DIR}/ASAP-Updater/ATLAS/scripts/SystemWipe.te" \
  "${APP_DIR}/ASAP-Updater/ATLAS/tools/bin2c/bin2c" \
  "${APP_DIR}/ASAP-Updater/ATLAS/tools/lz/lz77" \
  "${APP_DIR}/ASAP-Updater/resources/i18n" \
  "${APP_DIR}/ASAP-Updater/aiosu-forwarder" \
  "${APP_DIR}/ASAP-Updater/resources/deepsea_icon.png"
echo "Deleted: aio-switch-updater"

# sphaira
safe_rm \
  "${APP_DIR}/sphaira/assets/romfs/github/sphaira.json"
echo "Deleted: sphaira.json"

# Create New configs
install -D /dev/null "${APP_DIR}/sphaira/assets/romfs/github/dbi.json" && {
  printf '{    \n"url": "https://github.com/Yorunokyujitsu/DBIPatcher",\n';
  printf '    "assets": [\n    {\n      "path": "/switch/DBI/"\n    }\n  ]\n}\n';
} > "${APP_DIR}/sphaira/assets/romfs/github/dbi.json"
echo "Created: dbi.json"

install -D /dev/null "${APP_DIR}/sphaira/assets/romfs/github/horizon.json" && {
  printf '{    \n"url": "https://github.com/THZoria/NX_Firmware",\n    "assets": [\n';
  printf '    {\n      "name": "Firmware",\n      "path": "/Firmware/"\n    }\n  ]\n}\n';
} > "${APP_DIR}/sphaira/assets/romfs/github/horizon.json"
echo "Created: horizon.json"

install -D /dev/null "${APP_DIR}/sphaira/assets/romfs/github/picofly.json" && {
  printf '{    \n"url": "https://github.com/abal1000x/usk",\n    "assets": [\n';
  printf '    {\n      "name": "update",\n      "path": "/update.bin"\n    }\n  ]\n}\n';
} > "${APP_DIR}/sphaira/assets/romfs/github/picofly.json"
echo "Created: picofly.json"
echo "Done"
echo


# Extract NX.7z
print_title "[5/7] Extract custom files"
echo

NX_7Z="${APP_DIR}/NX.7z"

if [[ -f "${NX_7Z}" ]]; then
  if [[ -z "${PW_VERIFY:-}" ]]; then
    exit 1
  fi

  7z x -aoa -y -bsp0 -bso0 -bse0 \
    -p"${PW_VERIFY}" \
    "${NX_7Z}" -o"${APP_DIR}" \
    || { echo "[ERROR] Extract NX.7z failed"; exit 1; }

  cp -a "${APP_DIR}/misc/." "${TOP_DIR}/misc/"
  echo "Extracted: ASAP-UI.ttf"
  echo "Extracted: CascadiaMono-Custom.ttf"
  echo "Extracted: NotoSansKR-Custom.ttf"
  echo "Extracted: fichiercle.bin"
  echo "Extracted: repack tools"
  echo "Extracted: ASAP-Installer"
else
  echo "[ERROR] NX.7z not found, skipping"
fi
echo "Done"
echo


# Patch resources
print_title "[6/7] Resource processing"
echo

# Atmosphere boot, fatal logo conversion
python "${MISC_DIR}/tools/img_converter/ams_res/ams_img_conv.py"

# Hekate bootlogo conversion
python "${MISC_DIR}/tools/img_converter/hekate_res/bootlogo.py"

# Icon replacements
cp -f "${MISC_DIR}/res/icons/sphaira_icon.jpg" \
  "${APP_DIR}/sphaira/assets/icon.jpg" || true
echo "Replaced: sphaira icon"

cp -f "${MISC_DIR}/res/icons/updater_icon.jpg" \
  "${APP_DIR}/ASAP-Updater/icon.jpg" || true

cp -f "${MISC_DIR}/res/icons/updater_sub_icon.png" \
  "${APP_DIR}/ASAP-Updater/resources/gui_icon.png" || true
echo "Replaced: ASAP-Updater icon"

cp -f "${MISC_DIR}/res/icons/hoc_bench_icon.jpg" \
  "${APP_DIR}/Horizon-OC/Source/Benchmark-Toolbox/icon.jpg" || true

cp -f "${MISC_DIR}/res/icons/hoc_bench_sub_icon.png" \
  "${APP_DIR}/Horizon-OC/Source/Benchmark-Toolbox/resources/img/logo.png" || true
echo "Replaced: Horizon-OC icon"

# Convert LVGL Korean fonts into Hekate and Nyx Custom
python "${MISC_DIR}/tools/repack/main.py"
echo "Done"
echo


# 8GB DRAM Support / loader, exosphere patches
print_title "[7/7] Patches"
echo

# Duplicating Hekate
if [[ -d "${APP_DIR}/hekate" ]]; then
  cp -a "${APP_DIR}/hekate" "${APP_DIR}/hekate_8GB"
  echo "Duplicated: hekate > hekate_8GB"
else
  echo "[ERROR] hekate not found, skipping"
fi

# Hekate 8GB DRAM (RSVD_FLAG_DRAM_8GB = 0x01)
if [[ -f "${APP_DIR}/hekate_8GB/loader/loader.c" ]]; then
  echo "Patching: loader.c"

  sed -i \
    's/\.rcfg\.rsvd_flags[[:space:]]*=[[:space:]]*0,/\.rcfg.rsvd_flags   = RSVD_FLAG_DRAM_8GB,/' \
    "${APP_DIR}/hekate_8GB/loader/loader.c"
  echo "Hekate: supported 8GB DRAM Mode"
else
  echo "[ERROR] loader.c not found, skipping 8GB DRAM Mode"
fi

# loader.kip, exosphere.bin
if [[ -d "${APP_DIR}/Atmosphere" ]]; then
  EXO_SRC="${APP_DIR}/Horizon-OC/Source/Atmosphere-Patches"
  cp -a "${APP_DIR}/Atmosphere" "${APP_DIR}/HOC_Patch"
  rm -rf "${APP_DIR}/HOC_Patch/stratosphere/loader/source/oc"
  cp -a "${APP_DIR}/Horizon-OC/Source/Atmosphere/stratosphere/"* "${APP_DIR}/HOC_Patch/stratosphere"
  cp "${EXO_SRC}/secmon_emc_access_table_data.inc" "${APP_DIR}/HOC_Patch/exosphere/program/source/smc"
  cp "${EXO_SRC}/secmon_define_emc_access_table.inc" "${APP_DIR}/HOC_Patch/exosphere/program/source/smc"
  cp "${EXO_SRC}/secmon_rtc_pmc_access_table_data.inc" "${APP_DIR}/HOC_Patch/exosphere/program/source/smc"
  cp "${EXO_SRC}/secmon_define_rtc_pmc_access_table.inc" "${APP_DIR}/HOC_Patch/exosphere/program/source/smc"
  cp "${EXO_SRC}/secmon_smc_register_access.cpp" "${APP_DIR}/HOC_Patch/exosphere/program/source/smc"
  cp "${EXO_SRC}/secmon_smc_handler.cpp" "${APP_DIR}/HOC_Patch/exosphere/program/source/smc"
  cp "${EXO_SRC}/secmon_memory_layout.hpp" "${APP_DIR}/HOC_Patch/libraries/libexosphere/include/exosphere/secmon"
  echo "Duplicated: exosphere and stratosphere"
  echo "Atmosphere: supported horizon-oc"
else
  echo "[ERROR] exosphere or stratosphere not found, skipping"
fi

echo "Done"