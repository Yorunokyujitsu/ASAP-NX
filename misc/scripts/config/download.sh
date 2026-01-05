#!/usr/bin/env bash

download() {
  local tries="${1:-5}"
  shift

  local ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
  local common=(
    -L --fail
    --retry 3 --retry-delay 2
    --connect-timeout 20
    -A "$ua"
  )

  local out=""
  local args=("$@")
  for ((i=0; i<${#args[@]}; i++)); do
    if [[ "${args[i]}" == "-o" && $((i+1)) -lt ${#args[@]} ]]; then
      out="${args[i+1]}"
      break
    fi
  done

  [[ -n "$out" ]] && mkdir -p "$(dirname "$out")"

  local url=""
  for tok in "${args[@]}"; do
    [[ "$tok" =~ ^https?:// ]] && { url="$tok"; break; }
  done

  [[ -z "$url" ]] && {
    echo "[ERROR] download: URL not found in args: $*"
    return 1
  }

  local extra=()
  [[ "$url" == *"tinfoil.media"* ]] && extra+=(-e "https://tinfoil.media/repo/")

  for ((i=1; i<=tries; i++)); do
    echo "[GET] $url"
    curl "${common[@]}" "${extra[@]}" "${args[@]}" && return 0
    echo "[download] retry ${i}/${tries} failed"
    sleep 5
  done

  return 1
}
