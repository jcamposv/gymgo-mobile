#!/bin/sh

# Xcode Cloud CI script - runs after cloning the repo
set -e

echo "📂 Current directory: $(pwd)"
echo "📂 CI_WORKSPACE: $CI_WORKSPACE"
echo "📂 Listing workspace:"
ls -la $CI_WORKSPACE || true

# Find the project root (where pubspec.yaml is)
if [ -f "$CI_WORKSPACE/pubspec.yaml" ]; then
    PROJECT_ROOT="$CI_WORKSPACE"
elif [ -f "$CI_WORKSPACE/mobile/pubspec.yaml" ]; then
    PROJECT_ROOT="$CI_WORKSPACE/mobile"
else
    # Default to workspace
    PROJECT_ROOT="$CI_WORKSPACE"
fi

echo "📂 Project root: $PROJECT_ROOT"

echo "🔧 Installing Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "📋 Flutter version:"
flutter --version

echo "📦 Getting Flutter dependencies..."
cd "$PROJECT_ROOT"
flutter pub get

echo "🍎 Installing CocoaPods..."
cd "$PROJECT_ROOT/ios"

# Install pods
pod install --repo-update

echo "✅ CI setup complete!"
