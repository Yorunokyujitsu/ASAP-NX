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
    # Hekate (EN: f688f65)
    "Yorunokyujitsu/hekate@custom"

    # Atmosphere
    "Yorunokyujitsu/Atmosphere@custom"

    # Homebrew loader and Sphaira
    "switchbrew/nx-hbloader"
    #"Yorunokyujitsu/sphaira@test"

    # System modules and overlays (latest libultrahand 5dc0b63)
    "ppkantorski/Ultrahand-Overlay@f580fd9"
    "ppkantorski/EdiZon-Overlay@835e2fd"
    "masagrator/FPSLocker@76f3619"
    "ppkantorski/NX-FanControl@4c3226e"
    "ppkantorski/ovl-sysmodules@73bb9cf"
    "masagrator/ReverseNX-RT@725eb27"
    "ppkantorski/Status-Monitor-Overlay@3d1204b"
    "ppkantorski/sys-clk@d6bc69d"
    "borntohonk/sys-patch@f51f916"

    # Homebrews
    "HamletDuFromage/aio-switch-updater=ASAP-Updater@3d38eaa"
    "impeeza/linkalho@a34e7b0"
    #"Yorunokyujitsu/DBIPatcher"

    # Local
    "__local__/hekate_8GB"
    "__local__/Atmosphere_8GB"
    "__local__/LockPick"
  )
else
  # Custom OFF - Origin
  REPOS+=(
    "CTCaer/hekate"
    "Atmosphere-NX/Atmosphere"
    "switchbrew/nx-hbloader"
    "switchbrew/nx-hbmenu"
    #"ITotalJustice/sphaira"
    "suchmememanyskill/TegraExplorer"
    "impeeza/Lockpick_RCMDecScots=Lockpick_RCM"
    #"impeeza/sys-patch"
    "HamletDuFromage/aio-switch-updater"
    "impeeza/linkalho"
  )
fi