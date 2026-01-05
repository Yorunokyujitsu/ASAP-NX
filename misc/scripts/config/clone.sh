#!/usr/bin/env bash
set -euo pipefail

# Default config
: "${APP_DIR:?APP_DIR not set}"
: "${MISC_DIR:?MISC_DIR not set}"

source "${MISC_DIR}/scripts/config/log.sh"
source "${MISC_DIR}/scripts/config/urls.sh"
source "${MISC_DIR}/scripts/repos.sh"

print_title "Clone repositories"

mkdir -p "${APP_DIR}"

for entry in "${REPOS[@]}"; do
  spec="$entry"

  if [[ "$spec" == __local__/* ]]; then
    local_name="${spec#__local__/}"
    echo "[SKIP] local project: ${local_name}"
    echo
    continue
  fi

  dest=""
  if [[ "$spec" == *"="* ]]; then
    dest="${spec#*=}"
    spec="${spec%%=*}"
  fi

  branch=""
  if [[ "$spec" == *"@"* ]]; then
    branch="${spec#*@}"
    spec="${spec%%@*}"
  fi

  owner="${spec%%/*}"
  repo="${spec##*/}"

  [[ -z "$dest" ]] && dest="$repo"

  url="$(gh_repo "$owner" "$repo")"
  path="${APP_DIR}/${dest}"

  rm -rf "$path"

  if [[ -n "$branch" ]]; then
    git clone --recursive --branch "$branch" "$url" "$path" >/dev/null 2>&1 \
      || {
        git clone --recursive "$url" "$path" >/dev/null 2>&1
        git -C "$path" checkout "$branch" >/dev/null 2>&1
      }
  else
    git clone --recursive "$url" "$path" >/dev/null 2>&1
  fi

  git -C "$path" fetch --tags --force >/dev/null 2>&1 || true
  git -C "$path" submodule update --init --recursive >/dev/null 2>&1

  head="$(git -C "$path" rev-parse --short HEAD 2>/dev/null || echo "?")"

  branch_label="default"
  if [[ -n "$branch" ]]; then
    if [[ "$branch" =~ ^[0-9a-f]{7,40}$ ]]; then
      branch_label="commit"
    else
      branch_label="$branch"
    fi
  fi

  echo "[CLONE] ${repo} - ${owner}"
  echo "  branch    : ${branch_label} (${head})"

  while read -r line; do
    [[ -z "$line" ]] && continue
    sha="$(awk '{print $1}' <<<"$line" | tr -d '+-')"
    sm_path="$(awk '{print $2}' <<<"$line")"
    sm_name="$(basename "$sm_path")"
    echo "  submodule : ${sm_name} (${sha:0:7})"
  done < <(git -C "$path" submodule status --recursive 2>/dev/null || true)

  if [[ "$dest" != "$repo" ]]; then
    echo "  rename    : ${dest}"
  fi

  echo
done

echo "Done"
