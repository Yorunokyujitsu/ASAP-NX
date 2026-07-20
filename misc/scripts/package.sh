#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Default config
: "${TOP_DIR:?TOP_DIR not set}"
: "${APP_DIR:?APP_DIR not set}"
: "${MISC_DIR:?MISC_DIR not set}"
: "${DIST_DIR:?DIST_DIR not set}"

source "${MISC_DIR}/scripts/config/log.sh"
source "${MISC_DIR}/scripts/config/urls.sh"
source "${MISC_DIR}/scripts/config/download.sh"

trap 'echo "::error file=package.sh,line=$LINENO::Command failed"' ERR

if [[ "${ENABLE_CUSTOM:-0}" == "1" ]]; then
  PACKAGE_MODE="ASAP"
else
  PACKAGE_MODE="Origin"
fi

print_title "Packaging: ${PACKAGE_MODE}"
echo

require_file() {
  [[ -f "$1" ]] || {
    echo "[ERROR] Missing required file: $1"
    exit 1
  }
}

# URLs"
EMUIIBO_URL="$(gh_release_latest Yorunokyujitsu emuiibo emuiibo.zip)"
# OVLLDR_URL="$(gh_release_latest ppkantorski nx-ovlloader nx-ovlloader.zip)"
OVLLDR_URL="$(gh_release_tag ppkantorski nx-ovlloader v2.0.3 nx-ovlloader.zip)"
DBI_KO_URL="$(gh_release_latest Yorunokyujitsu DBIPatcher DBI_ko.zip)"
DBI_EN_URL="$(gh_release_latest Yorunokyujitsu DBIPatcher DBI_en.zip)"
SALTYNX_URL="$(gh_release_latest masagrator SaltyNX SaltyNX.zip)"
TINFOIL_URL="https://tinfoil.media/repo/Tinfoil%20Applet%20Mode%20%5B20.0%5D%5Bv2%5D.zip"
AMIIBO_GEN_URL="$(gh_release_latest yusufakg AmiiboGenerator AmiiboGenerator.nro)"
SPHAIRA_URL="$(gh_release_latest Yorunokyujitsu sphaira sphaira.nro)"

# Dynamic name zips URLs
HEKATE_URL="$(gh_dynamic_name CTCaer hekate '^hekate_ctcaer.*\.zip$')"
HEKATE_8GB_URL="$(gh_dynamic_name CTCaer hekate '^hekate_ctcaer.*__ram8GB\.bin$')"
MISSIONCON_URL="$(gh_dynamic_name ndeadly MissionControl '^MissionControl.*\.zip$')"
SYSCON_URL="$(gh_dynamic_name o0Zz sys-con '^sys-con.*\.zip$')"

# Configure payload.bin naming for 8GB RAM support
PAYLOAD_8GB="$(basename "$HEKATE_8GB_URL")"

# Version
BUILD_VER="${BUILD_VER:-$(date +'%m%d')}"
require_file "${TOP_DIR}/version.inc"
if grep -q "^\[ASAP\]" "${TOP_DIR}/version.inc"; then
  sed -i \
    "/^\[ASAP\]/,/^\[/{s/^current_version=.*/current_version=${BUILD_VER}/}" \
    "${TOP_DIR}/version.inc"
fi
echo "[INFO] The ASAP version has been set"


# ASAP Custom All in One
package_asap() {
  # Prepare dist
  [[ -n "$DIST_DIR" && "$DIST_DIR" != "/" && -d "$DIST_DIR" ]] \
    || { echo "[FATAL] Invalid DIST_DIR: $DIST_DIR"; exit 1; }

  # Hekate - Background image (asap.bmp)
  cp "${MISC_DIR}/res/screens/asap.png" \
     "${MISC_DIR}/tools/img_converter/hekate_res/background.png"

  python "${MISC_DIR}/tools/img_converter/hekate_res/con2bmp.py"
  rm -f "${MISC_DIR}/tools/img_converter/hekate_res/background.png"

  if [[ -f "${MISC_DIR}/tools/img_converter/hekate_res/background.bmp" ]]; then
    mogrify -rotate -90 "${MISC_DIR}/tools/img_converter/hekate_res/background.bmp"
  else
    echo "[ERROR] background.bmp not found, skip rotate"
  fi

  # Make AIO directories
  mkdir -p "${DIST_DIR}"/atmosphere/{contents/010B6ECF3B30D000/tools,contents/00FF0000636C6BFF/flags,hosts,spl}
  mkdir -p "${DIST_DIR}"/backup/{keys,kips/.OC}
  mkdir -p "${DIST_DIR}"/bootloader/{payloads,sys,res}
  mkdir -p "${DIST_DIR}"/config/{ftpsrv,ultrahand/sounds,ultrahand/assets/notifications}
  mkdir -p "${DIST_DIR}"/switch/{.packages/.offload/ram_expansion,AmiiboGenerator}
  mkdir -p "${DIST_DIR}"/switch/{ASAP-Updater,DBI,linkalho,sphaira,tinfoil/themes/ASAP_Custom}
  mkdir -p "${DIST_DIR}/warmboot_mariko"

  # Downloads ZIP
  download 5 -o "${DIST_DIR}/hekate.zip"              "${HEKATE_URL}"
  download 5 -o "${DIST_DIR}/emuiibo.zip"             "${EMUIIBO_URL}"
  download 5 -o "${DIST_DIR}/missioncontrol.zip"      "${MISSIONCON_URL}"
  download 5 -o "${DIST_DIR}/ovlloader.zip"           "${OVLLDR_URL}"
  download 5 -o "${DIST_DIR}/saltynx.zip"             "${SALTYNX_URL}"
  download 5 -o "${DIST_DIR}/sys-con.zip"             "${SYSCON_URL}"
  download 5 -o "${DIST_DIR}/tinfoil.zip"             "${TINFOIL_URL}"
  download 5 -o "${DIST_DIR}/switch/DBI/DBI.zip"      "${DBI_KO_URL}"

  # Download file
  download 5 -o "${DIST_DIR}/switch/AmiiboGenerator/AmiiboGenerator.nro" "${AMIIBO_GEN_URL}"
  download 5 -o "${DIST_DIR}/switch/sphaira/sphaira.nro" "${SPHAIRA_URL}"

  # Extract
  unzip -oq "${DIST_DIR}/hekate.zip" "bootloader/sys/*" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/switch/DBI/DBI.zip" -d "${DIST_DIR}/switch/DBI"
  unzip -o "${DIST_DIR}/missioncontrol.zip" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/ovlloader.zip" -x "*toolbox.json" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/emuiibo.zip" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/saltynx.zip" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/sys-con.zip" -x "*switch/sys-con.nro" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/tinfoil.zip" -x "*icon*.db" -d "${DIST_DIR}"

  # Remove download zip files
  rm -f "${DIST_DIR}/switch/DBI/DBI.zip"
  find "${DIST_DIR}" -type f -iname '*.zip' -delete

  # Config inis
  install -D -m 0644 /dev/null "${DIST_DIR}/atmosphere/hosts/emummc.txt" && {
    printf '# Block Nintendo Servers\n127.0.0.1 *nintendo*\n';
    printf '95.216.149.205 *conntest.nintendowifi.net\n95.216.149.205 *ctest.cdn.nintendo.net\n';
  } > "${DIST_DIR}/atmosphere/hosts/emummc.txt"

  install -D /dev/null "${DIST_DIR}/bootloader/hekate_ipl.ini" && {
    printf '[config]\nautoboot=1\nautoboot_list=1\nbootwait=1\nbacklight=80';
  } > "${DIST_DIR}/bootloader/hekate_ipl.ini"

  install -D /dev/null "${DIST_DIR}/bootloader/ini/aio_update.ini" && {
    printf '[ASAP Update]\npayload=bootloader/payloads/ATLAS.bin\nlogopath=bootloader/res/asap.bmp';
  } > "${DIST_DIR}/bootloader/ini/aio_update.ini"

  install -D /dev/null "${DIST_DIR}/bootloader/ini/ams_cfw.ini" && {
    printf '[CFW]\npayload=bootloader/payloads/fusee.bin\nlogopath=bootloader/res/asap.bmp';
  } > "${DIST_DIR}/bootloader/ini/ams_cfw.ini"

  install -D /dev/null "${DIST_DIR}/bootloader/ini/ams_wbfix.ini" && {
    printf '[Stock]\npkg3=atmosphere/package3\nstock=1\nemummc_force_disable=1\nlogopath=bootloader/res/asap.bmp';
  } > "${DIST_DIR}/bootloader/ini/ams_wbfix.ini"

  #install -D -m 0644 /dev/null "${DIST_DIR}/config/sys-clk/config_.ini" && {
  #  printf '# App config options example: Zelda BOTW\n# Add tid line: [Application Title ID]\n';
  #  printf '# Options: docked, handheld, handheld_charging, handheld_charging_usb, handheld_charging_official\n';
  #  printf '# Add at the end of options: _cpu, _gpu, _mem = value\n;[01007EF00011E000]\n;docked_cpu=1224\n';
  #  printf ';handheld_charging_cpu=1224\n;handheld_mem=1600\n\n# Default settings\n';
  #  printf '[values]\ngpu_vmin_offset=0\nauto_gpu_vmin=1\nreversenx_sync=0\n';
  #  printf 'auto_cpu_boost=0\nboost_gpu_override=0\nuncapped_clocks=1\n';
  #} > "${DIST_DIR}/config/sys-clk/config_.ini"

  install -D -m 0644 /dev/null "${DIST_DIR}/config/sys-clk/config_.ini" && {
    printf '[values]\n; Defines how often sys-clk log temperatures, in milliseconds (set 0 to disable)\n';
    printf 'temp_log_interval_ms=0\n; Defines how often sys-clk writes to the CSV, in milliseconds (set 0 to disable)\n';
    printf 'csv_write_interval_ms=0\n\n; Example #1: BOTW\n; Overclock CPU when docked\n';
    printf '; Overclock MEM to docked clocks when handheld\n;[01007EF00011E000]\n;docked_cpu=1224\n;handheld_mem=1600\n\n';
    printf '; Example #2: Picross\n; Underclock to save battery\n;[0100BA0003EEA000]\n;handheld_cpu=816\n';
    printf ';handheld_gpu=153\n;handheld_mem=800\n';
  } > "${DIST_DIR}/config/sys-clk/config_.ini"

  install -D -m 0644 /dev/null "${DIST_DIR}/config/sphaira/config_.ini" && {
    printf '[config]\nftp_enabled=1\nmtp_enabled=1\nnxlink_enabled=0\ninstall_emummc=1\n';
    printf 'skip_nca_hash_verify=0\nskip_rsa_header_fixed_key_verify=1\n';
    printf 'skip_rsa_npdm_fixed_key_verify=0\nlower_system_version=0\n';
    printf '[dump]\nappend_folder_with_xci=0\nuse_nacp_name=1\n';
  } > "${DIST_DIR}/config/sphaira/config_.ini"

  install -D /dev/null "${DIST_DIR}/config/ultrahand/ram_4gb.ini" && {
    printf '[config]\n8gb=1';
  } > "${DIST_DIR}/config/ultrahand/ram_4gb.ini"

  install -D /dev/null "${DIST_DIR}/config/ultrahand/packages.ini" && {
    printf '[Extra Setting+]\npriority=0\n\n[System Clock+]\npriority=1\n\n[OC Toolkit]\npriority=2\nhide=true';
   } > "${DIST_DIR}/config/ultrahand/packages.ini"

  install -D /dev/null "${DIST_DIR}/switch/.packages/config.ini" && {
    printf '[Horizon-OC]\nfooter=On\n\n[Master Volume]\nindex=30\nvalue=150';
  } > "${DIST_DIR}/switch/.packages/config.ini"

  install -D /dev/null "${DIST_DIR}/boot.ini" && {
    printf '[payload]\nfile=payload.bin';
  } > "${DIST_DIR}/boot.ini"

  if [[ -f "${DIST_DIR}/config/sys-con/config.ini" ]]; then
    mv "${DIST_DIR}/config/sys-con/config.ini" \
       "${DIST_DIR}/config/sys-con/config_.ini"
  fi

  if [[ -f "${DIST_DIR}/config/MissionControl/missioncontrol.ini.template" ]]; then
    mv "${DIST_DIR}/config/MissionControl/missioncontrol.ini.template" \
       "${DIST_DIR}/config/MissionControl/missioncontrol_.ini"
  fi

  touch "${DIST_DIR}/atmosphere/contents/00FF0000636C6BFF/flags/boot2.flag"
  touch "${DIST_DIR}/atmosphere/contents/010B6ECF3B30D000/flag"

  # Uncompress kip
  KIP_DIR="${APP_DIR}/HOC_Patch/stratosphere/loader/out/nintendo_nx_arm64_armv8a/release"
  hactool -t kip1 "${KIP_DIR}/loader.kip" --uncompress="${KIP_DIR}/hoc.kip"

  # Packaging
  AMS_DIR="${APP_DIR}/Atmosphere/out/nintendo_nx_arm64_armv8a/release/atmosphere-out"
  MEM_DIR="${APP_DIR}/AMS_40MB/out/nintendo_nx_arm64_armv8a/release/atmosphere-out"

  cp -r "${AMS_DIR}/atmosphere/config" "${DIST_DIR}/atmosphere"
  cp -r "${AMS_DIR}/atmosphere/hbl_html" "${DIST_DIR}/atmosphere"
  cp -r "${AMS_DIR}/switch" "${DIST_DIR}"
  cp -r "${APP_DIR}/NX-FanControl/out/atmosphere" "${DIST_DIR}"
  cp -r "${APP_DIR}/NX-FanControl/out/switch" "${DIST_DIR}"
  cp -r "${APP_DIR}/uh_pack/"* "${DIST_DIR}/switch/.packages"
  cp -r "${APP_DIR}/Ultrahand-Overlay/common/audio_mastervolume" "${DIST_DIR}/atmosphere/exefs_patches"
  cp -r "${MISC_DIR}/tools/aeskey" "${DIST_DIR}/backup/keys/PartialAesKeyCrack"
  #cp -r "${MISC_DIR}/cache" "${DIST_DIR}/warmboot_mariko"

  cp -f -T "${MISC_DIR}/mod/hwfly_toolbox.bin" "${DIST_DIR}/atmosphere/contents/010B6ECF3B30D000/tools/htb"
  cp -f -T "${MISC_DIR}/mod/instinct_toolbox.bin" "${DIST_DIR}/atmosphere/contents/010B6ECF3B30D000/tools/itb"
  cp -f -T "${MISC_DIR}/mod/picofly_toolbox.bin" "${DIST_DIR}/atmosphere/contents/010B6ECF3B30D000/tools/ptb"
  cp -f -T "${MISC_DIR}/ini/cleanup.ini" "${DIST_DIR}/atmosphere/contents/010B6ECF3B30D000/clup"

  cp -f "${APP_DIR}/Ultrahand-Overlay/sounds/"*.wav "${DIST_DIR}/config/ultrahand/sounds"

  cp "${MISC_DIR}/tools/img_converter/hekate_res/background.bmp" "${DIST_DIR}/bootloader/res/asap.bmp"
  cp "${TOP_DIR}/version.inc" "${DIST_DIR}/atmosphere/config"
  cp "${APP_DIR}/HOC_Patch/exosphere/out/nintendo_nx_arm64_armv8a/release/exosphere.bin" "${DIST_DIR}/atmosphere/config/exosphere.bin"
  cp "${KIP_DIR}/hoc.kip" "${DIST_DIR}/backup/kips/.OC/loader.kip"
  cp "${APP_DIR}/Horizon-OC/Source/hoc-clk/sysmodule/out/hoc-clk.nsp" "${DIST_DIR}/atmosphere/contents/00FF0000636C6BFF/exefs.nsp"
  cp "${APP_DIR}/Horizon-OC/Source/hoc-clk/overlay/out/horizon-oc-overlay.ovl" "${DIST_DIR}/switch/.overlays/horizon-oc-overlay.ovl"
  cp "${APP_DIR}/nx-hbloader/hbl.nsp" "${DIST_DIR}/atmosphere/spl/spl.nsp"
  cp "${AMS_DIR}/atmosphere/package3" "${DIST_DIR}/atmosphere"
  cp "${AMS_DIR}/atmosphere/stratosphere.romfs" "${DIST_DIR}/atmosphere"
  cp "${AMS_DIR}/bootloader/payloads/fusee.bin" "${DIST_DIR}/bootloader/payloads"
  cp "${MEM_DIR}/atmosphere/package3" "${DIST_DIR}/switch/.packages/.offload/ram_expansion/package3_40mb"
  cp "${MEM_DIR}/atmosphere/stratosphere.romfs" "${DIST_DIR}/switch/.packages/.offload/ram_expansion/stratosphere_40mb.romfs"
  cp "${MEM_DIR}/bootloader/payloads/fusee.bin" "${DIST_DIR}/switch/.packages/.offload/ram_expansion/fusee_40mb.bin"
  cp "${APP_DIR}/ASAP-Updater/ATLAS/output/ATLAS.bin" "${DIST_DIR}/bootloader/payloads"
  cp "${APP_DIR}/LockPick/output/auto_lockpick.bin" "${DIST_DIR}/bootloader/payloads"
  cp "${MISC_DIR}/ini/update.ini" "${DIST_DIR}/bootloader/update.te"
  cp "${APP_DIR}/hekate/output/hekate.bin" "${DIST_DIR}/bootloader/update.bin"
  cp "${APP_DIR}/hekate/output/hekate.bin" "${DIST_DIR}/payload.bin"
  cp "${APP_DIR}/hekate/output/nyx.bin" "${DIST_DIR}/bootloader/sys"
  cp "${APP_DIR}/hekate_8GB/output/hekate.bin" "${DIST_DIR}/switch/.packages/.offload/ram_expansion/hekate_8gb.bin"
  cp "${APP_DIR}/FPSLocker/FPSLocker.ovl" "${DIST_DIR}/switch/.overlays"
  cp "${APP_DIR}/EdiZon-Overlay/out/ovlEdiZon.ovl" "${DIST_DIR}/switch/.overlays"
  cp "${APP_DIR}/Ultrahand-Overlay/ovlmenu.ovl" "${DIST_DIR}/switch/.overlays"
  cp "${APP_DIR}/ovl-sysmodules/ovlSysmodules.ovl" "${DIST_DIR}/switch/.overlays"
  cp "${APP_DIR}/ReverseNX-RT/Overlay/ReverseNX-RT-ovl.ovl" "${DIST_DIR}/switch/.overlays"
  cp "${APP_DIR}/Status-Monitor-Overlay/Status-Monitor-Overlay.ovl" "${DIST_DIR}/switch/.overlays"
  cp "${APP_DIR}/ASAP-Updater/ASAP-Updater.nro" "${DIST_DIR}/switch/ASAP-Updater/ASAP-Updater_.nro"
  cp "${APP_DIR}/ASAP-Updater/.ASAP-Updater.nro.star" "${DIST_DIR}/switch/ASAP-Updater"
  cp "${APP_DIR}/linkalho/linkalho.nro" "${DIST_DIR}/switch/linkalho"
  #cp "${APP_DIR}/sphaira/build/Release/sphaira.nro" "${DIST_DIR}/switch/sphaira"
  #cp "${APP_DIR}/DBIPatcher/dist/DBI.nro" "${DIST_DIR}/switch/DBI/DBI.845.nro"
  cp "${MISC_DIR}/ini/dbi.ini" "${DIST_DIR}/switch/DBI/dbi.config"
  cp "${MISC_DIR}/res/icons/logo.png" "${DIST_DIR}/switch/tinfoil/themes/ASAP_Custom"
  cp "${MISC_DIR}/res/screens/bg.png" "${DIST_DIR}/switch/tinfoil/themes/ASAP_Custom"
  cp "${MISC_DIR}/json/tinfoil_theme.json" "${DIST_DIR}/switch/tinfoil/themes/ASAP_Custom/settings.json"
  cp "${MISC_DIR}/json/tinfoil_options.json" "${DIST_DIR}/switch/tinfoil/options.json"
  cp "${MISC_DIR}/res/misc/hoc.rgba" "${DIST_DIR}/config/ultrahand/assets/notifications/hoc.rgba"
  cp "${MISC_DIR}/res/misc/res.pak" "${DIST_DIR}/bootloader/sys"
  cp "${MISC_DIR}/ini/overlays.ini" "${DIST_DIR}/config/ultrahand"
  cp "${MISC_DIR}/ini/ftpsrv.ini" "${DIST_DIR}/config/ftpsrv/config_.ini"
  cp "${MISC_DIR}/mod/boot.dat" "${DIST_DIR}"
  cp "${MISC_DIR}/cache/wb_16.bin" "${DIST_DIR}/warmboot_mariko"
  cp "${MISC_DIR}/cache/wb_17.bin" "${DIST_DIR}/warmboot_mariko"

  # Temporary
  # cp -r "${APP_DIR}/hekate" "${DIST_DIR}"

  # ASAP Current version
  sed -i '/^\[latest_version\]/,/^\[/d' \
    "${DIST_DIR}/atmosphere/config/version.inc"

  # Cleanup emuiibo lang.json
  find "${DIST_DIR}/emuiibo/overlay/lang" -maxdepth 1 -type f -name '*.json' \
    ! -name 'en.json' ! -name 'ko.json' ! -name 'ja.json' -delete

  # ASAP.zip
  mkdir -p "${TOP_DIR}/ASAP"
  rsync -a "${DIST_DIR}/" "${TOP_DIR}/ASAP/"
  (
    cd "${DIST_DIR}"
    zip -r "ASAP.zip" .
  )
  mkdir -p "${DIST_DIR}/output"
  mv "${DIST_DIR}/ASAP.zip" "${DIST_DIR}/output"
  mv "${TOP_DIR}/ASAP" "${DIST_DIR}"

  # update.zip
  mkdir -p "${DIST_DIR}/temp/"{atmosphere/config,bootloader/payloads,switch/.packages/.offload/ram_expansion}
  cp -r "${DIST_DIR}/ASAP/bootloader/sys" "${DIST_DIR}/temp/bootloader"
  cp -r "${DIST_DIR}/ASAP/switch/.packages/.offload" "${DIST_DIR}/temp/switch/.packages"
  cp "${DIST_DIR}/ASAP/atmosphere/config/version.inc" "${DIST_DIR}/temp/atmosphere/config"
  cp "${DIST_DIR}/ASAP/atmosphere/package3" "${DIST_DIR}/temp/atmosphere"
  cp "${DIST_DIR}/ASAP/atmosphere/package3" "${DIST_DIR}/temp/switch/.packages/.offload/ram_expansion"
  cp "${DIST_DIR}/ASAP/atmosphere/stratosphere.romfs" "${DIST_DIR}/temp/atmosphere"
  cp "${DIST_DIR}/ASAP/atmosphere/stratosphere.romfs" "${DIST_DIR}/temp/switch/.packages/.offload/ram_expansion"
  cp "${DIST_DIR}/ASAP/bootloader/payloads/ATLAS.bin" "${DIST_DIR}/temp/bootloader/payloads"
  cp "${DIST_DIR}/ASAP/bootloader/payloads/fusee.bin" "${DIST_DIR}/temp/bootloader/payloads"
  cp "${DIST_DIR}/ASAP/bootloader/payloads/fusee.bin" "${DIST_DIR}/temp/bootloader/payloads"
  cp "${DIST_DIR}/ASAP/bootloader/payloads/fusee.bin" "${DIST_DIR}/temp/switch/.packages/.offload/ram_expansion"
  cp "${DIST_DIR}/ASAP/bootloader/update.bin" "${DIST_DIR}/temp/bootloader"
  cp "${DIST_DIR}/ASAP/payload.bin" "${DIST_DIR}/temp/switch/.packages/.offload/ram_expansion/hekate_4gb.bin"
  cp "${DIST_DIR}/ASAP/payload.bin" "${DIST_DIR}/temp"

  (
    cd "${DIST_DIR}/temp"
    zip -r "update.zip" .
  )
  mv "${DIST_DIR}/temp/update.zip" "${DIST_DIR}/output"

  # oc.zip
  mkdir -p "${DIST_DIR}/oc/"{atmosphere/{contents,config,kips},backup,config/sys-clk,switch/.overlays}
  cp -r "${DIST_DIR}/ASAP/atmosphere/contents/00FF0000636C6BFF" "${DIST_DIR}/oc/atmosphere/contents"
  cp -r "${DIST_DIR}/ASAP/backup/kips" "${DIST_DIR}/oc/backup"
  cp "${DIST_DIR}/ASAP/atmosphere/config/exosphere.bin" "${DIST_DIR}/oc/atmosphere/config"
  cp "${DIST_DIR}/ASAP/backup/kips/.OC/loader.kip" "${DIST_DIR}/oc/atmosphere/kips"
  cp "${DIST_DIR}/ASAP/config/sys-clk/config_.ini" "${DIST_DIR}/oc/config/sys-clk/config.ini"
  cp "${DIST_DIR}/ASAP/switch/.overlays/horizon-oc-overlay.ovl" "${DIST_DIR}/oc/switch/.overlays"

  (
    cd "${DIST_DIR}/oc"
    zip -r "oc.zip" .
  )
  mv "${DIST_DIR}/oc/oc.zip" "${DIST_DIR}/output"

  # oc_ext.zip
  mkdir -p "${DIST_DIR}/oc/switch/Benchmark-Toolbox"
  rm -rf "${DIST_DIR}/oc/atmosphere"
  rm -rf "${DIST_DIR}/oc/backup"
  rm -rf "${DIST_DIR}/oc/config"
  rm -rf "${DIST_DIR}/oc/switch/.overlays"
  cp "${APP_DIR}/Horizon-OC/Source/Benchmark-Toolbox/Benchmark-Toolbox.nro" "${DIST_DIR}/oc/switch/Benchmark-Toolbox"
  
  (
    cd "${DIST_DIR}/oc"
    zip -r "oc_ext.zip" .
  )
  mv "${DIST_DIR}/oc/oc_ext.zip" "${DIST_DIR}/output"
}


# Original Hekate and Atmosphere All in One
package_origin() {
  mkdir -p "${DIST_DIR}"
  mkdir -p "${DIST_DIR}"/atmosphere/hosts
  mkdir -p "${DIST_DIR}"/{config,switch/{aio-switch-updater,Daybreak,DBI,Haze,Reboot_to_payload,linkalho}}

  # Downloads
  download 5 -o "${DIST_DIR}/hekate.zip" "${HEKATE_URL}"
  download 5 -o "${DIST_DIR}/${PAYLOAD_8GB}" "${HEKATE_8GB_URL}"
  download 5 -o "${DIST_DIR}/DBI.zip"    "${DBI_EN_URL}"

  # Extract
  mapfile -t ATM_ZIPS < <(
    find "${APP_DIR}/Atmosphere/out/nintendo_nx_arm64_armv8a/release" \
      -maxdepth 1 -type f -name 'atmosphere-*.zip' ! -name '*-debug.zip')

  (( ${#ATM_ZIPS[@]} == 1 )) || exit 1

  unzip -o "${ATM_ZIPS[0]}" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/hekate.zip" -d "${DIST_DIR}"
  unzip -o "${DIST_DIR}/DBI.zip" -d "${DIST_DIR}/switch/DBI"

  # Config inis
  install -D -m 0644 /dev/null "${DIST_DIR}/atmosphere/config/system_settings.ini" && {
    printf '[usb]\nusb30_force_enabled=u8!0x1\n\n';
    printf '[erpt]\ndisable_automatic_report_cleanup=u8!0x1\n\n';
    printf '[atmosphere]\ndmnt_cheats_enabled_by_default=u8!0x0\ndmnt_always_save_cheat_toggles=u8!0x1\n';
    printf 'enable_dns_mitm=u8!0x1\nadd_defaults_to_dns_hosts=u8!0x1\nenable_external_bluetooth_db=u8!0x1\n\n';
    printf '[olsc]\ndefault_auto_upload_global_setting = u8!0x0\n';
  } > "${DIST_DIR}/atmosphere/config/system_settings.ini"

  install -D -m 0644 /dev/null "${DIST_DIR}/atmosphere/config/override_config.ini" && {
    printf '[hbl_config]\ntitle_id=010000000000100D\noverride_any_app=true\npath=atmosphere/hbl.nsp\n';
    printf 'override_key=R\n\n[default_config]\noverride_key=!L\ncheat_enable_key=!L\n';
  } > "${DIST_DIR}/atmosphere/config/override_config.ini"

  install -D -m 0644 /dev/null "${DIST_DIR}/atmosphere/hosts/emummc.txt" && {
    printf '# Block Nintendo Servers\n127.0.0.1 *nintendo*\n';
    printf '95.216.149.205 *conntest.nintendowifi.net\n95.216.149.205 *ctest.cdn.nintendo.net\n';
  } > "${DIST_DIR}/atmosphere/hosts/emummc.txt"

  install -D -m 0644 /dev/null "${DIST_DIR}/bootloader/hekate_ipl.ini" && {
    printf '[config]\nautoboot=0\nautoboot_list=0\nbootwait=1\nnoticker=0\nautohosoff=2\n';
    printf 'autonogc=0\nbootprotect=0\nupdater2p=0\nbacklight=100\n\n';
    printf '[CFW (SD Card)]\npkg3=atmosphere/package3\nemummcforce=1\n\n';
    printf '[CFW (eMMC)]\npkg3=atmosphere/package3\nemummc_force_disable=1\n\n';
    printf '[CFW (fusee.bin)]\npayload=bootloader/payloads/fusee.bin\n\n';
    printf '[Warmboot Error Fix (eMMC)]\npkg3=atmosphere/package3\nstock=1\nemummc_force_disable=1';
  } > "${DIST_DIR}/bootloader/hekate_ipl.ini"

  install -D /dev/null "${DIST_DIR}/boot.ini" && {
    printf '[payload]\nfile=payload.bin';
  } > "${DIST_DIR}/boot.ini"

  install -D -m 0644 /dev/null "${DIST_DIR}/exosphere.ini" && {
    printf '[exosphere]\ndebugmode=1\ndebugmode_user=0\ndisable_user_exception_handlers=0\n';
    printf 'enable_user_pmu_access=0\nblank_prodinfo_sysmmc=0\nblank_prodinfo_emummc=1\n';
    printf 'allow_writing_to_cal_sysmmc=0\nlog_port=0\nlog_baud_rate=115200\nlog_inverted=0\n';
  } > "${DIST_DIR}/exosphere.ini"

  # Packaging
  cp "${APP_DIR}/Atmosphere/out/nintendo_nx_arm64_armv8a/release/fusee.bin" "${DIST_DIR}/bootloader/payloads"
  cp "${APP_DIR}/hekate/output/nyx.bin" "${DIST_DIR}/bootloader/sys"
  cp "${APP_DIR}/hekate/output/hekate.bin" "${DIST_DIR}/bootloader/update.bin"
  cp "${APP_DIR}/hekate/output/hekate.bin" "${DIST_DIR}/payload.bin"
  cp "${APP_DIR}/nx-hbloader/hbl.nsp" "${DIST_DIR}/atmosphere"
  cp "${APP_DIR}/nx-hbmenu/nx-hbmenu.nro" "${DIST_DIR}/hbmenu.nro"
  cp "${APP_DIR}/TegraExplorer/output/TegraExplorer.bin" "${DIST_DIR}/bootloader/payloads"
  cp "${APP_DIR}/Lockpick_RCM/output/Lockpick_RCM.bin" "${DIST_DIR}/bootloader/payloads"
  cp "${APP_DIR}/aio-switch-updater/aio-switch-updater.nro" "${DIST_DIR}/switch/aio-switch-updater"
  cp "${APP_DIR}/linkalho/linkalho.nro" "${DIST_DIR}/switch/linkalho"
  cp "${MISC_DIR}/mod/boot.dat" "${DIST_DIR}"
  #cp -r "${APP_DIR}/sys-patch/out/atmosphere" "${DIST_DIR}"

  mv "${DIST_DIR}/switch/daybreak.nro" "${DIST_DIR}/switch/Daybreak"
  mv "${DIST_DIR}/switch/haze.nro" "${DIST_DIR}/switch/Haze"
  mv "${DIST_DIR}/switch/reboot_to_payload.nro" "${DIST_DIR}/switch/Reboot_to_payload"

  # Remove download zip and files
  find "${DIST_DIR}" -type f -iname '*.zip' -delete

  (
    cd "${DIST_DIR}"
    zip -r "custom.zip" .
  )
  mkdir -p "${DIST_DIR}/output"
  mv "${DIST_DIR}/custom.zip" "${DIST_DIR}/output/"
}

if [[ "$PACKAGE_MODE" == "ASAP" ]]; then
  package_asap
else
  package_origin
fi
echo "${PACKAGE_MODE} Build Completed"