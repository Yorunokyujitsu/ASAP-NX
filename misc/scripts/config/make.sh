#!/usr/bin/env bash
set -euo pipefail

# Default config
: "${APP_DIR:?APP_DIR not set}"
: "${MISC_DIR:?MISC_DIR not set}"

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

  # Atmosphere_8GB (only fusee + exosphere)
  if [[ "$dest" == "Atmosphere_8GB" ]]; then
    print_title "[BUILD] ${dest}"

    if [[ -d "$dir/fusee" ]]; then
      make -C "$dir/fusee" -j"$(nproc)"
    fi

    if [[ -d "$dir/exosphere" ]]; then
      make -C "$dir/exosphere" -j"$(nproc)"
    fi

    echo "${dest} partial build completed"
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