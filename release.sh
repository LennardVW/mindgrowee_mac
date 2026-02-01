#!/bin/bash

# MindGrowee_mac Release Build Script
# Usage: ./release.sh [version]

set -e

VERSION=${1:-"1.0.0"}
BUILD_NUMBER=${2:-$(date +%Y%m%d%H%M)}

echo "🚀 MindGrowee_mac Release Builder"
echo "=================================="
echo "Version: $VERSION"
echo "Build: $BUILD_NUMBER"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build/release
rm -rf Build/

# Build for release
echo "🔨 Building for release..."
swift build -c release

# Create app bundle structure
echo "📦 Creating app bundle..."
APP_NAME="MindGrowee"
APP_BUNDLE="Build/$APP_NAME.app"

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp .build/release/mindgrowee_mac "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.mindgrowee.mac</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 MindGrowee. All rights reserved.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Copy resources
cp -r Assets/* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
cp Sources/mindgrowee_mac/InfoPlist.strings "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
cp Sources/mindgrowee_mac/Localizable.xcstrings "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "✅ App bundle created: $APP_BUNDLE"
echo ""

# Create DMG
echo "💿 Creating DMG..."
DMG_NAME="Build/MindGrowee-$VERSION.dmg"

# Create temporary directory for DMG
mkdir -p Build/dmg
cp -r "$APP_BUNDLE" Build/dmg/

# Create README for DMG
cat > Build/dmg/README.txt << EOF
MindGrowee $VERSION
==================

Thank you for downloading MindGrowee!

Installation:
1. Drag MindGrowee.app to your Applications folder
2. Launch from Applications or Launchpad
3. Enjoy tracking your habits!

Support:
- Email: support@mindgrowee.app
- GitHub: https://github.com/LennardVW/mindgrowee_mac

© 2026 MindGrowee
EOF

# Create DMG (requires create-dmg tool)
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "MindGrowee $VERSION" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --app-drop-link 450 185 \
        --icon "MindGrowee.app" 150 185 \
        "$DMG_NAME" \
        Build/dmg/
    echo "✅ DMG created: $DMG_NAME"
else
    echo "⚠️  create-dmg not installed. Skipping DMG creation."
    echo "   Install with: brew install create-dmg"
fi

# Cleanup
rm -rf Build/dmg

# Codesign (if identity available)
if security find-identity -v -p codesigning | grep -q "Developer ID"; then
    echo "🔏 Code signing..."
    codesign --force --deep --sign "Developer ID Application" "$APP_BUNDLE"
    echo "✅ App signed"
else
    echo "⚠️  No Developer ID found. Skipping code signing."
    echo "   App will show 'unidentified developer' warning."
fi

# Notarize (if credentials available)
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_PASSWORD" ]; then
    echo "📤 Notarizing..."
    xcrun notarytool submit "$DMG_NAME" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait
    
    xcrun stapler staple "$DMG_NAME"
    echo "✅ Notarization complete"
fi

echo ""
echo "🎉 Release build complete!"
echo "=========================="
echo "App: $APP_BUNDLE"
echo "DMG: $DMG_NAME"
echo ""
echo "Next steps:"
echo "1. Test the app thoroughly"
echo "2. Upload DMG to GitHub releases"
echo "3. Update website download link"
