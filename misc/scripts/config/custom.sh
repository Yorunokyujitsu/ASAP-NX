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
  "sys-clk/overlay/lib/"
  "sys-patch/overlay/"
  "Ultrahand-Overlay/lib/"
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
    name="$(basename "${patch}" .patch)"
    local target="${APP_DIR}/${name}"

    if [[ ! -d "${target}" ]]; then
      echo "Skip: ${name}.patch (not found)"
      continue
    fi

    echo "Apply: ${name}.patch"

    (
      cd "${target}"
      git apply --3way --ignore-whitespace --whitespace=nowarn "${patch}"
    ) || {
      echo "[ERROR] Failed to apply patch: ${patch}"
      exit 1
    }
  done

  shopt -u nullglob
}

apply_libs_diff_patches() {
  shopt -s nullglob

  declare -A LIB_PATCH_MAP=(
    ["libfancontrol"]="${APP_DIR}/NX-FanControl/lib/libfancontrol"
    ["borealis"]="${APP_DIR}/linkalho/lib/borealis"
    ["zipper"]="${APP_DIR}/linkalho/lib/zipper"
    ["Atmosphere-libs"]="${APP_DIR}/ReverseNX-RT/Overlay/libs/Atmosphere-libs"
  )

  for patch in "${MISC_DIR}/diff/libs"/*.patch; do
    local name
    name="$(basename "${patch}" .patch)"
    local target="${LIB_PATCH_MAP[${name}]:-}"

    if [[ -z "${target}" || ! -d "${target}" ]]; then
      echo "Skip: ${name}.patch (not found)"
      continue
    fi

    echo "Apply: ${name}.patch"

    (
      cd "${target}"
      git apply --3way --ignore-whitespace --whitespace=nowarn "${patch}"
    ) || {
      echo "[ERROR] Failed to apply patch: ${patch}"
      exit 1
    }
  done

  shopt -u nullglob
}


# ASAP Patch Process
# Diff patch
print_title "[1/7] Patch repositories"
echo
apply_main_diff_patches
echo "Done"
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
echo "Done"
echo


# Cleanup
print_title "[4/7] Cleanup repositories"
echo

# aio-switch-updater
safe_rm \
  "${APP_DIR}/ASAP-Updater/ATLAS/scripts/FirmwareDump.te" \
  "${APP_DIR}/ASAP-Updater/ATLAS/scripts/SystemWipe.te" \
  "${APP_DIR}/ASAP-Updater/ATLAS/tools/bin2c/bin2c" \
  "${APP_DIR}/ASAP-Updater/ATLAS/tools/lz/lz77" \
  "${APP_DIR}/ASAP-Updater/resources/i18n" \
  "${APP_DIR}/ASAP-Updater/aiosu-forwarder" \
  "${APP_DIR}/ASAP-Updater/resources/deepsea_icon.png"

# sphaira
#safe_rm \
#  "${APP_DIR}/sphaira/assets/romfs/github/sphaira.json"

#echo "Deleted: aio-switch-updater"
#echo "Deleted: sphaira.json"

# Create New configs
#install -D /dev/null "${APP_DIR}/sphaira/assets/romfs/github/dbi.json" && {
#  printf '{    \n"url": "https://github.com/Yorunokyujitsu/DBIPatcher",\n';
#  printf '    "assets": [\n    {\n      "path": "/switch/DBI/"\n    }\n  ]\n}\n';
#} > "${APP_DIR}/sphaira/assets/romfs/github/dbi.json"
#echo "Created: dbi.json"

#install -D /dev/null "${APP_DIR}/sphaira/assets/romfs/github/horizon.json" && {
#  printf '{    \n"url": "https://github.com/THZoria/NX_Firmware",\n    "assets": [\n';
#  printf '    {\n      "name": "Firmware",\n      "path": "/Firmware/"\n    }\n  ]\n}\n';
#} > "${APP_DIR}/sphaira/assets/romfs/github/horizon.json"
#echo "Created: horizon.json"

#install -D /dev/null "${APP_DIR}/sphaira/assets/romfs/github/picofly.json" && {
#  printf '{    \n"url": "https://github.com/abal1000x/usk",\n    "assets": [\n';
#  printf '    {\n      "name": "update",\n      "path": "/update.bin"\n    }\n  ]\n}\n';
#} > "${APP_DIR}/sphaira/assets/romfs/github/picofly.json"
#echo "Created: picofly.json"
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


# Icon replacements
#cp -f "${MISC_DIR}/res/icons/sphaira_icon.jpg" \
#  "${APP_DIR}/sphaira/assets/icon.jpg" || true
#echo "Replaced: sphaira icon"

cp -f "${MISC_DIR}/res/icons/updater_icon.jpg" \
  "${APP_DIR}/ASAP-Updater/icon.jpg" || true

cp -f "${MISC_DIR}/res/icons/updater_sub_icon.png" \
  "${APP_DIR}/ASAP-Updater/resources/gui_icon.png" || true
echo "Replaced: ASAP-Updater icon"

# Convert LVGL Korean fonts into Hekate and Nyx Custom
python "${MISC_DIR}/tools/repack/main.py"
echo "Done"
echo


# 8GB DRAM Support Patch
print_title "[7/7] 8GB Patches"
echo

# Duplicating Hekate
if [[ -d "${APP_DIR}/hekate" ]]; then
  cp -a "${APP_DIR}/hekate" "${APP_DIR}/hekate_8GB"
  echo "Duplicated: hekate > hekate_8GB"
else
  echo "[ERROR] hekate not found, skipping"
fi

# Duplicating Atmosphere
AMS_8GB="${APP_DIR}/Atmosphere_8GB"
AMS_SECMON="${AMS_8GB}/exosphere/program/source/smc/secmon_smc_info.cpp"
AMS_FUSEE="${AMS_8GB}/libraries/libexosphere/source/fuse/fuse_api.cpp"

rsync -a "${APP_DIR}/Atmosphere/" "${AMS_8GB}/"

for i in {1..200}; do
  if [[ -f "${AMS_SECMON}" && -f "${AMS_FUSEE}" ]]; then
    echo "Duplicated: Atmosphere > Atmosphere_8GB"
    break
  fi
  sleep 0.1
done

if [[ ! -f "${AMS_SECMON}" || ! -f "${AMS_FUSEE}" ]]; then
  echo "[ERROR] Atmosphere_8GB copy incomplete (timeout)"
  exit 1
fi

# Hekate 8GB DRAM
if [[ -f "${APP_DIR}/hekate_8GB/loader/loader.c" ]]; then
  echo "Patching: loader.c"

  sed -i \
    's/\.rcfg\.rsvd_flags[[:space:]]*=[[:space:]]*0,/\.rcfg.rsvd_flags   = RSVD_FLAG_DRAM_8GB,/' \
    "${APP_DIR}/hekate_8GB/loader/loader.c"
  echo "Hekate: supported 8GB DRAM Mode"
else
  echo "[ERROR] loader.c not found, skipping 8GB DRAM Mode"
fi
echo

# Atmosphere 8GB DRAM
if [[ -f "${AMS_SECMON}" ]]; then
  echo "Patching: secmon_smc_info.cpp"

  sed -i \
    's/u32 memory_mode = pkg1::MemoryMode_4GB;/u32 memory_mode = pkg1::MemoryMode_8GB;/' \
    "${AMS_SECMON}"
  sed -i \
    's/pkg1::MemorySize memory_size = pkg1::MemorySize_4GB;/pkg1::MemorySize memory_size = pkg1::MemorySize_8GB;/' \
    "${AMS_SECMON}"
  sed -i \
    's/if (const auto &bcd = GetBootConfig().data; bcd.IsDevelopmentFunctionEnabled()) {/if (const auto \&bcd = GetBootConfig().data; 1) {/' \
    "${AMS_SECMON}"
else
  echo "[ERROR] secmon_smc_info.cpp not found, skipping"
fi

if [[ -f "${AMS_FUSEE}" ]]; then
  echo "Patching: fuse_api.cpp"
  sed -i '
    /DramId GetDramId()/,/}/ {
      s@return static_cast<DramId>(GetDramIdValue(util::BitPack32{GetCommonOdmWord(4)}));@return DramId_AulaSamsung1y8GBX;\
        return static_cast<DramId>(GetDramIdValue(util::BitPack32{GetCommonOdmWord(4)}));@
    }
  ' "${AMS_FUSEE}"
else
  echo "[ERROR] fuse_api.cpp not found, skipping"
fi
echo "Atmosphere: supported 8GB DRAM Mode"
echo "Done"