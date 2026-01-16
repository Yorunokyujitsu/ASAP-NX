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

if [[ "${ENABLE_CUSTOM:-0}" == "1" ]]; then
  # Custom On - ASAP
  REPOS+=(
    # Hekate / 8GB
    "CTCaer/hekate@3af777f"
    "CTCaer/hekate=hekate_8GB@3af777f"

    # Atmosphere / 8GB
    "Atmosphere-NX/Atmosphere@5056ab2"
    "Atmosphere-NX/Atmosphere=Atmosphere_8GB@5056ab2"

    # Homebrew loader and Sphaira
    "switchbrew/nx-hbloader"
    "Yorunokyujitsu/sphaira@test"

    # System modules and overlays (latest libultrahand f053eaa)
    "ppkantorski/Ultrahand-Overlay@77bd239"
    "ppkantorski/EdiZon-Overlay@835e2fd"
    "masagrator/FPSLocker@e887a22"
    "ppkantorski/NX-FanControl@4c3226e"
    "ppkantorski/ovl-sysmodules@73bb9cf"
    "masagrator/ReverseNX-RT@725eb27"
    "ppkantorski/Status-Monitor-Overlay@7000377"
    "ppkantorski/sys-clk@d6bc69d"
    "borntohonk/sys-patch@6904ed6"

    # Homebrews
    "HamletDuFromage/aio-switch-updater=ASAP-Updater@3d38eaa"
    "impeeza/linkalho@a34e7b0"
    #"Yorunokyujitsu/DBIPatcher"

    # Local
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
    #"impeeza/sys-patch"
    "HamletDuFromage/aio-switch-updater"
    "impeeza/linkalho"
  )
fi