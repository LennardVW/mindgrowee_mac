#!/bin/bash

# Build script for MindGrowee macOS app

set -e

echo "🏗️ Building MindGrowee..."

# Build
echo "Running swift build..."
swift build

# Run tests
echo "Running tests..."
swift test

echo "✅ Build successful!"

# Optional: Create app bundle
if [ "$1" == "--bundle" ]; then
    echo "Creating app bundle..."
    
    BUILD_DIR=".build/debug"
    APP_NAME="MindGrowee.app"
    CONTENTS="$APP_NAME/Contents"
    
    # Clean previous bundle
    rm -rf "$APP_NAME"
    
    # Create bundle structure
    mkdir -p "$CONTENTS/MacOS"
    mkdir -p "$CONTENTS/Resources"
    
    # Copy executable
    cp "$BUILD_DIR/mindgrowee_mac" "$CONTENTS/MacOS/MindGrowee"
    
    # Create Info.plist
    cat > "$CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MindGrowee</string>
    <key>CFBundleIdentifier</key>
    <string>com.mindgrowee.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MindGrowee</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
    
    echo "✅ App bundle created: $APP_NAME"
fi
