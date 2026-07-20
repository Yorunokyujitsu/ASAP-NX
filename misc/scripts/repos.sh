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
    # Hekate (EN: f688f65)
    "Yorunokyujitsu/hekate@custom"

    # Atmosphere
    "Yorunokyujitsu/Atmosphere@custom"

    # Homebrew loader and Sphaira
    "switchbrew/nx-hbloader"
    #"Yorunokyujitsu/sphaira@test"

    # System modules and overlays (latest libultrahand 856ddbd)
    "ppkantorski/Ultrahand-Overlay@2d0621a"
    "ppkantorski/EdiZon-Overlay@91e64f7"
    "masagrator/FPSLocker@7b316c9"
    "ppkantorski/NX-FanControl@acf6d39"
    "ppkantorski/ovl-sysmodules@32f1045"
    "ppkantorski/ReverseNX-RT@748f6be"
    "ppkantorski/Status-Monitor-Overlay@84fe9cd"
    "Yorunokyujitsu/Horizon-OC@test" # d9906a7

    # Homebrews
    "HamletDuFromage/aio-switch-updater=ASAP-Updater@3d38eaa"
    "impeeza/linkalho@a34e7b0"

    # Local
    "__local__/HOC_Patch"
    "__local__/AMS_40MB"
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
    "impeeza/Lockpick_RCMDecScots=Lockpick_RCM"
    "HamletDuFromage/aio-switch-updater"
    "impeeza/linkalho"
  )
fi