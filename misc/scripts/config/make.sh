#!/usr/bin/env bash
set -euo pipefail

# Default config
: "${APP_DIR:?APP_DIR not set}"
: "${MISC_DIR:?MISC_DIR not set}"
: "${ENABLE_ATMOSPHERE:=1}"

source "${MISC_DIR}/scripts/config/log.sh"
source "${MISC_DIR}/scripts/repos.sh"

skip_build() {
  local repo="$1"

  for skip in "${SKIP_BUILD[@]}"; do
    [[ "$repo" == "$skip" ]] && return 0
  done

  return 1
}

repo_info() {
  spec="$1"

  if [[ "$spec" == *"="* ]]; then
    dest="${spec#*=}"
    spec="${spec%%=*}"
  else
    dest="${spec##*/}"
  fi

  dest="${dest%%@*}"
  dir="${APP_DIR}/${dest}"
}

for entry in "${REPOS[@]}"; do
  repo_info "$entry"

  [[ -d "$dir" ]] || continue

  if skip_build "$dest"; then
    echo "[SKIP BUILD] ${dest}"
    continue
  fi

  # Repos requiring specific libnx versions are built last.
  if [[ "$dest" == "Ultrahand-Overlay" || "$dest" == "sphaira" || \
        "$dest" == "Atmosphere" || "$dest" == "HOC_Patch" ]]; then
    continue
  fi

  # Atmosphere (upstream)
  #if [[ "$dest" == "Atmosphere" ]]; then
  #  [[ "$ENABLE_ATMOSPHERE" == "1" ]] || continue
  #  print_title "[BUILD] ${dest}"

  #  if [[ "${ENABLE_CUSTOM:-0}" == "1" ]]; then
  #    make -C "$dir" -f atmosphere.mk dist-no-debug -j12
  #  else
  #    make -C "$dir" -f atmosphere.mk dist-no-debug
  #  fi

  #  echo "${dest} build completed"
  #  echo
  #  continue
  #fi

  # Atmosphere (only loader + exosphere)
  #if [[ "$dest" == "HOC_Patch" ]]; then
  #  print_title "[BUILD] ${dest}"

  #  if [[ -d "$dir/stratosphere/loader" ]]; then
  #    make -C "$dir/stratosphere/loader" -j"$(nproc)"
  #  fi

  #  if [[ -d "$dir/exosphere" ]]; then
  #    make -C "$dir/exosphere" -j"$(nproc)"
  #  fi

  #  echo "Atmosphere partial build completed"
  #  echo
  #  continue
  #fi

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

  # sys-clk (script build)
  if [[ "$dest" == "sys-clk" ]]; then
    print_title "[BUILD] ${dest}"
    chmod +x "$dir/build.sh" || true
    "$dir/build.sh"
    echo "${dest} build completed"
    echo
    continue
  fi

  # Horizon-OC (script build)
  if [[ "$dest" == "Horizon-OC" ]]; then
    print_title "[BUILD] ${dest}"
    chmod +x "$dir/Source/hoc-clk/build.sh" || true
    "$dir/Source/hoc-clk/build.sh"
    print_title "[BUILD] Benchmark-Toolbox"
    make -C "$dir/Source/Benchmark-Toolbox" -j"$(nproc)"
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

# Ultrahand-Overlay requires ppkantorski/libnx.
for entry in "${REPOS[@]}"; do
  repo_info "$entry"

  [[ "$dest" == "Ultrahand-Overlay" ]] || continue
  [[ -d "$dir" ]] || break
  skip_build "$dest" && break

  print_title "[BUILD] ${dest}"

  rm -rf /tmp/ultrahand-libnx
  git clone --recurse-submodules https://github.com/ppkantorski/libnx.git /tmp/ultrahand-libnx
  make -C /tmp/ultrahand-libnx install -j"$(nproc)"

  make -C "$dir"
  echo "${dest} build completed"
  echo
  break
done

# sphaira requires the latest switchbrew/libnx
# and the custom iosupport branch of newlib.
for entry in "${REPOS[@]}"; do
  repo_info "$entry"

  [[ "$dest" == "sphaira" ]] || continue
  [[ -d "$dir" ]] || break
  skip_build "$dest" && break

  print_title "[BUILD] ${dest}"

  rm -rf /tmp/sphaira-newlib /tmp/sphaira-libnx
  git clone --branch iosupport https://github.com/R-YaTian/newlib.git /tmp/sphaira-newlib
  git clone --recurse-submodules https://github.com/switchbrew/libnx.git /tmp/sphaira-libnx

  (
    cd /tmp/sphaira-newlib
    bash ./build-libgloss-local.sh
  )
  make -C /tmp/sphaira-libnx install -j"$(nproc)"

  # sphaira (cmake preset: Release, Dev)
  cmake -S "$dir" --preset Release
  cmake --build "$dir/build/Release" --parallel "$(nproc)"
  echo "${dest} build completed"
  echo
  break
done

# Atmosphere requires hexkyz/libnx.
for entry in "${REPOS[@]}"; do
  repo_info "$entry"

  [[ "$dest" == "Atmosphere" ]] || continue
  [[ -d "$dir" ]] || break
  skip_build "$dest" && break
  [[ "$ENABLE_ATMOSPHERE" == "1" ]] || break

  print_title "[BUILD] ${dest}"

  rm -rf /tmp/atmosphere-libnx
  git clone --recurse-submodules https://github.com/hexkyz/libnx.git /tmp/atmosphere-libnx
  make -C /tmp/atmosphere-libnx install -j"$(nproc)"

  if [[ "${ENABLE_CUSTOM:-0}" == "1" ]]; then
    make -C "$dir" -f atmosphere.mk dist-no-debug -j12
  else
    make -C "$dir" -f atmosphere.mk dist-no-debug
  fi

  echo "${dest} build completed"
  echo
  break
done

# HOC_Patch is built after Atmosphere.
for entry in "${REPOS[@]}"; do
  repo_info "$entry"

  [[ "$dest" == "HOC_Patch" ]] || continue
  [[ -d "$dir" ]] || break
  skip_build "$dest" && break

  print_title "[BUILD] ${dest}"

  if [[ -d "$dir/stratosphere/loader" ]]; then
    make -C "$dir/stratosphere/loader" -j"$(nproc)"
  fi

  if [[ -d "$dir/exosphere" ]]; then
    make -C "$dir/exosphere" -j"$(nproc)"
  fi

  echo "Atmosphere partial build completed"
  echo
  break
done

echo "Done"