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

    # System modules and overlays (latest libultrahand 8159e43)
    "ppkantorski/Ultrahand-Overlay@2ba22aa"
    "ppkantorski/EdiZon-Overlay@835e2fd"
    "masagrator/FPSLocker@1d7f081"
    "ppkantorski/NX-FanControl@91fccf8"
    "ppkantorski/ovl-sysmodules@6b5dc4f"
    "masagrator/ReverseNX-RT@725eb27"
    "ppkantorski/Status-Monitor-Overlay@1335710"
    "ppkantorski/sys-clk@9d23400"
    "borntohonk/sys-patch" #35d2c25

    # Homebrews
    "HamletDuFromage/aio-switch-updater=ASAP-Updater@3d38eaa"
    "impeeza/linkalho@a34e7b0"
    #"Yorunokyujitsu/DBIPatcher"

    # Local
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