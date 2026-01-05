#!/usr/bin/env bash

# GitHub URL generators
GITHUB_URL="https://github.com"
GITHUB_RAW_URL="https://raw.githubusercontent.com"
GITHUB_API_URL="https://api.github.com/repos"

# Repo URL
gh_repo() {
  local owner="$1"
  local repo="$2"
  echo "$GITHUB_URL/$owner/$repo"
}

# Raw file
gh_raw() {
  local owner="$1"
  local repo="$2"
  local ref="$3"
  local path="$4"
  echo "$GITHUB_RAW_URL/$owner/$repo/$ref/$path"
}

# Archive zip
gh_archive() {
  local owner="$1"
  local repo="$2"
  local ref="$3"
  echo "$GITHUB_URL/$owner/$repo/archive/refs/$ref.zip"
}

# Latest release asset
gh_release_latest() {
  local owner="$1"
  local repo="$2"
  local filename="$3"
  echo "$GITHUB_URL/$owner/$repo/releases/latest/download/$filename"
}

# Specific tag release asset
gh_release_tag() {
  local owner="$1"
  local repo="$2"
  local tag="$3"
  local filename="$4"
  echo "$GITHUB_URL/$owner/$repo/releases/download/$tag/$filename"
}

# Dynamic filename asset
gh_dynamic_name() {
  local owner="$1" repo="$2" pattern="$3"
  local json url

  for _ in {1..5}; do
    json="$(curl -fsSL "$GITHUB_API_URL/$owner/$repo/releases/latest")" && break
    sleep 2
  done

  [[ -z "$json" ]] && return 1

  if command -v jq >/dev/null 2>&1; then
    url="$(printf '%s' "$json" \
      | jq -r --arg re "$pattern" \
        '.assets[] | select(.name | test($re)) | .browser_download_url' \
      | head -n1)"
  else
    url="$(printf '%s' "$json" \
      | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p' \
      | grep -E "$pattern" | head -n1)"
  fi

  [[ -n "$url" ]] || return 1
  printf '%s\n' "$url"
}