#!/bin/sh
set -eu

REPO_URL="https://github.com/xZepyx/whyis.git"
TMP_DIR="/tmp/whyis-install"
BIN_NAME="whyis"
BIN_TARGET="/usr/bin/$BIN_NAME"
DATA_DIR="/usr/share/whyis"

printf "Do you want to install whyis? (y/N): "
if ! read ans </dev/tty; then
  echo "Aborted."
  exit 1
fi

case "$ans" in
  y|Y) ;;
  *)
    echo "Aborted."
    exit 0
    ;;
esac

rm -rf "$TMP_DIR"
git clone "$REPO_URL" "$TMP_DIR"
cd "$TMP_DIR"

if ! command -v nim >/dev/null 2>&1; then
  echo "Nim is not installed."
  exit 1
fi

nim c -d:release whyis.nim

sudo mkdir -p "$DATA_DIR"
sudo cp symptoms.db "$DATA_DIR/"
sudo cp -r collectors "$DATA_DIR/"
sudo cp -r rules "$DATA_DIR/"

sudo mv whyis "$BIN_TARGET"
sudo chmod +x "$BIN_TARGET"

rm -rf "$TMP_DIR"

echo "whyis installed successfully"
