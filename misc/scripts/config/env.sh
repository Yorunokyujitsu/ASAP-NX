#!/usr/bin/env bash
set -euo pipefail

# Top directory
TOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export TOP_DIR

# Sub directiories
APP_DIR="$TOP_DIR/contents"
MISC_DIR="$TOP_DIR/misc"
DIST_DIR="$TOP_DIR/dist"

export APP_DIR MISC_DIR DIST_DIR

mkdir -p "$DIST_DIR"
