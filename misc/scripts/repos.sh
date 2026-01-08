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
    "CTCaer/hekate"
    "CTCaer/hekate=hekate_8GB"

    # Atmosphere / 8GB
    "Atmosphere-NX/Atmosphere"
    "Atmosphere-NX/Atmosphere=Atmosphere_8GB"

    # Homebrew loader and Sphaira
    "switchbrew/nx-hbloader"
    "Yorunokyujitsu/sphaira@test"

    # System modules and overlays
    "ppkantorski/Ultrahand-Overlay@f634fe9"
    "ppkantorski/EdiZon-Overlay@92136c2"
    "masagrator/FPSLocker@e887a22"
    "ppkantorski/NX-FanControl@4c3226e"
    "ppkantorski/ovl-sysmodules@859a805"
    "masagrator/ReverseNX-RT@725eb27"
    "ppkantorski/Status-Monitor-Overlay@f4c876f"
    "ppkantorski/sys-clk@9acf792"
    "borntohonk/sys-patch"

    # Homebrews
    "Slluxx/AmiiboGenerator"
    "HamletDuFromage/aio-switch-updater=ASAP-Updater"
    "impeeza/linkalho"
    "Yorunokyujitsu/DBIPatcher"

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