#!/bin/bash
# Vercel Deployment Script for Flutter Web

echo "🔥 Cloning Flutter Stable..."
git clone https://github.com/flutter/flutter.git -b stable

echo "🔧 Exporting Flutter Path..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "📦 Installing Dependencies..."
flutter pub get

echo "🏗 Building Flutter Web..."
flutter build web --release

echo "✅ Build Complete!"
