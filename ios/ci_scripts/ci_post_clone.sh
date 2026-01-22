#!/bin/sh

# Xcode Cloud CI script - runs after cloning the repo

echo "🔧 Installing Flutter..."
# Clone Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "📦 Getting Flutter dependencies..."
cd $CI_PRIMARY_REPOSITORY_PATH/mobile
flutter pub get

echo "🍎 Installing CocoaPods dependencies..."
cd $CI_PRIMARY_REPOSITORY_PATH/mobile/ios
pod install

echo "✅ CI setup complete!"
