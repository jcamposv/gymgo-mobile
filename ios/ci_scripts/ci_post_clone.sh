#!/bin/sh

# Xcode Cloud CI script - runs after cloning the repo
set -e

echo "🔧 Installing Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "📋 Flutter version:"
flutter --version

echo "📦 Getting Flutter dependencies..."
cd $CI_WORKSPACE
flutter pub get

echo "🍎 Installing CocoaPods..."
cd $CI_WORKSPACE/ios

# Remove old Pods if exists
rm -rf Pods Podfile.lock

# Install pods
pod install --repo-update

echo "✅ CI setup complete!"
