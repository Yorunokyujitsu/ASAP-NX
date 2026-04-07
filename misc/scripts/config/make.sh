#!/usr/bin/env bash
set -euo pipefail

# Default config
: "${APP_DIR:?APP_DIR not set}"
: "${MISC_DIR:?MISC_DIR not set}"
: "${ENABLE_ATMOSPHERE:=1}"

source "${MISC_DIR}/scripts/config/log.sh"
source "${MISC_DIR}/scripts/repos.sh"

for entry in "${REPOS[@]}"; do
  spec="$entry"

  if [[ "$spec" == *"="* ]]; then
    dest="${spec#*=}"
    spec="${spec%%=*}"
  else
    dest="${spec##*/}"
  fi

  dest="${dest%%@*}"
  dir="${APP_DIR}/${dest}"

  [[ -d "$dir" ]] || continue

  # Atmosphere (upstream)
  if [[ "$dest" == "Atmosphere" ]]; then
    [[ "$ENABLE_ATMOSPHERE" == "1" ]] || continue
    print_title "[BUILD] ${dest}"

    if [[ "${ENABLE_CUSTOM:-0}" == "1" ]]; then
      make -C "$dir" -f atmosphere.mk dist-no-debug -j12
    else
      make -C "$dir" -f atmosphere.mk dist-no-debug
    fi

    echo "${dest} build completed"
    echo
    continue
  fi

  # Works only with DBIPatcher forks derived from Yorunokyujitsu’s repository.
  if [[ "$dest" == "DBIPatcher" ]]; then
    source "$dir/config.txt"

    DBI_PATCHER="$dir/bin/dbipatcher"
    BLPT_DIR="$dir/translate/blueprints/blueprint.${ver}.txt"
    LANG_DIR="$dir/translate/lang.${lang}.txt"
    DBI_FILE="$dir/dbi/DBI.${ver}.ru.nro"

    print_title "[BUILD] ${dest}"
    make -C "$dir" -j"$(nproc)"
    echo "${dest} build completed"
    echo

    mkdir -p "$dir/dist"

    origin_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"

    if [[ "$origin_url" =~ github.com[:/]+Yorunokyujitsu/DBIPatcher(\.git)?$ ]]; then
      sed -i '1438s|=[[:space:]]*.*|={0}-{1}  FW: {2}-{3}|' "${LANG_DIR}"
    fi

    "${DBI_PATCHER}" --patch "${BLPT_DIR}" --nro "${DBI_FILE}" \
      --lang "${LANG_DIR}" --out "$dir/dist/DBI.nro"

    if [[ "$origin_url" =~ github.com[:/]+Yorunokyujitsu/DBIPatcher(\.git)?$ ]]; then
      cd "$dir" && python "./font/font_patch.py" "${lang}" "$dir/dist/DBI.nro"
    fi

    echo "${dest} patches DBI.nro"
    echo
    continue
  fi

  # aio-switch-updater
  if [[ "$dest" == "aio-switch-updater" ]]; then
    print_title "[BUILD] ${dest}"
    make -C "$dir/aiosu-forwarder" -j"$(nproc)"
    make -C "$dir" -j"$(nproc)"
    echo "${dest} build completed"
    echo
    continue
  fi

  # nx-hbmenu
  if [[ "$dest" == "nx-hbmenu" ]]; then
    print_title "[BUILD] ${dest}"
    make -C "$dir" nx -j"$(nproc)"
    echo "${dest} build completed"
    echo
    continue
  fi

  # NX-FanControl (make all)
  if [[ "$dest" == "NX-FanControl" ]]; then
    print_title "[BUILD] ${dest}"
    make -C "$dir" all
    echo "${dest} build completed"
    echo
    continue
  fi

  # MissionControl (make dist)
  if [[ "$dest" == "MissionControl" ]]; then
    print_title "[BUILD] ${dest}"
    make -C "$dir" dist
    echo "${dest} build completed"
    echo
    continue
  fi

  # sphaira (cmake preset: Release, Dev)
  if [[ "$dest" == "sphaira" ]]; then
    print_title "[BUILD] ${dest}"
    cmake -S "$dir" --preset Release
    cmake --build "$dir/build/Release" --parallel "$(nproc)"
    echo "${dest} build completed"
    echo
    continue
  fi

  # sys-clk (script build)
  if [[ "$dest" == "sys-clk" ]]; then
    print_title "[BUILD] ${dest}"
    chmod +x "$dir/build.sh" || true
    "$dir/build.sh"
    echo "${dest} build completed"
    echo
    continue
  fi

  [[ -f "$dir/Makefile" ]] || continue

  # Default make -j$(nproc) repos
  print_title "[BUILD] ${dest}"
  make -C "$dir" -j"$(nproc)"
  echo "${dest} build completed"
  echo
done

echo "Done"