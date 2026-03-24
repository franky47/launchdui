#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="LaunchdUI"
APP_BUNDLE=".build/release/$APP_NAME.app"
INSTALL_DIR="/Applications"

# Build and bundle
"$SCRIPT_DIR/scripts/bundle.sh"

# Install
echo "Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_BUNDLE" "$INSTALL_DIR/$APP_NAME.app"

echo "Installed: $INSTALL_DIR/$APP_NAME.app"
