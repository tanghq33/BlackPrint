#!/bin/bash
set -e

APP_NAME="BlackPrint"
BUILD_DIR="build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
ENTITLEMENTS="$APP_NAME/$APP_NAME.entitlements"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Building $APP_NAME..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  -destination "platform=macOS" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" \
  build

echo "Stripping extended attributes..."
xattr -cr "$APP_PATH"

echo "Signing (ad-hoc)..."
codesign --force --deep --sign - \
  --entitlements "$ENTITLEMENTS" "$APP_PATH"

echo "Creating DMG..."
bash "$SCRIPT_DIR/create-dmg/create-dmg" \
  --volname "$APP_NAME" \
  --window-size 500 320 \
  --icon-size 96 \
  --icon "$APP_NAME.app" 150 160 \
  --app-drop-link 350 160 \
  --no-internet-enable \
  --skip-jenkins \
  "$DMG_PATH" \
  "$APP_PATH"

echo "Done: $DMG_PATH"
