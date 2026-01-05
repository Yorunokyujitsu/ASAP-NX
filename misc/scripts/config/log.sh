#!/usr/bin/env bash

print_title() {
  local title="$1"
  local pad=4
  local width=$(( ${#title} + pad * 2 ))
  local line
  printf -v line '%*s' "$width" ''
  line=${line// /'='}

  echo
  echo "$line"
  printf "%*s%s%*s\n" "$pad" '' "$title" "$pad" ''
  echo "$line"
  echo
}
