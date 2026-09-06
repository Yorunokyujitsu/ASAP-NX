#!/usr/bin/env bash
# ================================================
# Repository definitions
#
# Format:
#   owner/repo
#   owner/repo/ref
#
# Rename:
#   repo=dest
#
# Notes:
# - repo, repo=dest         > latest
# - repo@ref, repo=dest@ref > branch or commit
# ================================================

REPOS=()

# Repositories that should be cloned/updated
# but skipped during build.
SKIP_BUILD=(
  # Requires custom libnx
  "Ultrahand-Overlay"
)

if [[ "${ENABLE_CUSTOM:-0}" == "1" ]]; then
  # Custom On - ASAP
  REPOS+=(
    # Hekate (EN: fd82a9b, Hocate: 39417b3)
    "Yorunokyujitsu/hekate@custom"

    # Atmosphere
    "Yorunokyujitsu/Atmosphere@custom"

    # Homebrew loader and Sphaira
    "switchbrew/nx-hbloader"
    "Yorunokyujitsu/sphaira@eacb54b"

    # System modules and overlays (latest libultrahand 2e4df54)
    "ppkantorski/Ultrahand-Overlay@430c044"
    "ppkantorski/EdiZon-Overlay@91e64f7"
    "masagrator/FPSLocker@7b316c9"
    "ppkantorski/NX-FanControl@acf6d39"
    "ppkantorski/ovl-sysmodules@32f1045"
    "ppkantorski/ReverseNX-RT@748f6be"
    "ppkantorski/Status-Monitor-Overlay@84fe9cd"
    "Yorunokyujitsu/Horizon-OC@personal" # personal ( 2.5.1: 66cfbe0 ), test ( 3.0.0: 38ab15a )

    # Homebrews
    "HamletDuFromage/aio-switch-updater=ASAP-Updater@3d38eaa"
    "impeeza/linkalho@a34e7b0"

    # Local
    "__local__/HOC_Patch"
    "__local__/hekate_8GB"
    "__local__/LockPick"
  )
else
  # Custom OFF - Origin
  REPOS+=(
    "CTCaer/hekate"
    "Atmosphere-NX/Atmosphere"
    "switchbrew/nx-hbloader"
    "switchbrew/nx-hbmenu"
    "suchmememanyskill/TegraExplorer"
    "THZoria/Lockpick_RCMaster=Lockpick_RCM"
    "HamletDuFromage/aio-switch-updater"
    "impeeza/linkalho"
  )
fi