#!/usr/bin/env bash
# Install the app from this clone and put its launcher on PATH.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/bin"
OPEN_APP=1
for arg in "$@"; do
  case "$arg" in
    --no-open) OPEN_APP=0 ;;
    -h|--help)
      echo "Usage: install.sh [target_bin_dir] [--no-open]"
      exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 2 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done
if [[ "$OPEN_APP" -eq 1 ]]; then
  bash "$ROOT/setup_mac.sh"
else
  bash "$ROOT/setup_mac.sh" --no-open
fi
mkdir -p "$TARGET_DIR"
ln -sf "$ROOT/video-hq" "$TARGET_DIR/video-hq"
echo "Launcher: $TARGET_DIR/video-hq"
case ":${PATH:-}:" in
  *":$TARGET_DIR:"*) ;;
  *) echo "Add to your shell profile: export PATH=\"$TARGET_DIR:\$PATH\"" ;;
esac
