#!/bin/bash
# Build agent-town static files and package into Flutter assets.
# Run this when you change agent_town_web/ source code.
# After this, just F5 in VS Code to run the Flutter app.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="$(dirname "$SCRIPT_DIR")"
WEB_DIR="$FLUTTER_DIR/agent_town_web"

echo "=== Building agent-town static export ==="
cd "$WEB_DIR"

# Install deps if needed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  pnpm install
fi

# Build static export
pnpm build

echo "=== Packaging into Flutter assets ==="
mkdir -p "$FLUTTER_DIR/assets"
cd out
zip -r "$FLUTTER_DIR/assets/agent_town_web.zip" . -x '*.txt'

echo "=== Done! ==="
echo "Zip size: $(du -sh "$FLUTTER_DIR/assets/agent_town_web.zip" | cut -f1)"
echo "Now just press F5 in VS Code to run the Flutter app."
