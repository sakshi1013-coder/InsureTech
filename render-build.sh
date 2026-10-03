#!/usr/bin/env bash
# Exit on any error
set -o errexit

echo ">>> Cloning Flutter SDK..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo ">>> Verifying Flutter installation..."
flutter --version

echo ">>> Installing dependencies..."
flutter pub get

echo ">>> Building Flutter Web release..."
flutter build web --release --no-tree-shake-icons

echo ">>> Successfully built web bundle in build/web!"
