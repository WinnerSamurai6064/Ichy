#!/bin/bash
set -e

echo "=== IEchilli Vercel Build ==="

# Install Flutter SDK
FLUTTER_VERSION="3.22.2"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION..."
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz
  tar -xf /tmp/flutter.tar.xz -C "$HOME"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "Flutter version:"
flutter --version

# Move into flutter app directory
cd flutter_app

# Disable analytics / telemetry
flutter config --no-analytics

# Get dependencies
flutter pub get

# Build for web
flutter build web \
  --release \
  --web-renderer canvaskit \
  --dart-define=FLUTTER_WEB_USE_SKIA=true

echo "=== Build complete. Output in flutter_app/build/web ==="
