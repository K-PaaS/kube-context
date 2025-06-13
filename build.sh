#!/bin/bash

# This script builds the Kubernetes Context Manager application into a single executable file.
# It detects the operating system and adjusts the build process accordingly.

# App name
APP_NAME="KubeContextManager"

# Entry point script
ENTRY_POINT="run.py"

# Detect OS
OS="$(uname)"

PYINSTALLER_OPTS=(
    --name "$APP_NAME"
    --onefile
    --windowed
    --hidden-import="PySide6.QtSvg"
    --hidden-import="PySide6.QtWidgets"
    --hidden-import="PySide6.QtGui"
    --hidden-import="PySide6.QtCore"
    --osx-bundle-identifier "com.kpaas.kubecontextmanager"
)

echo "========================================"
echo "Building $APP_NAME for $OS..."
echo "========================================"

# MACOSX_DEPLOYMENT_TARGET 환경 변수가 GitHub Actions 워크플로우에서 설정되어 넘어오는지 확인
echo "Detected MACOSX_DEPLOYMENT_TARGET: $MACOSX_DEPLOYMENT_TARGET"
echo "========================================"

# Clean up previous builds
rm -rf build dist "$APP_NAME.app" "$APP_NAME.dmg"

# Build the application
if [ "$OS" == "Darwin" ]; then
    echo "Running PyInstaller for macOS..."
    # --macos-target-version 옵션 제거
    pyinstaller "${PYINSTALLER_OPTS[@]}" "$ENTRY_POINT"

    if [ ! -d "dist/$APP_NAME.app" ]; then
        echo "Error: PyInstaller did not create the .app bundle correctly."
        exit 1
    fi
    echo "$APP_NAME.app bundle created successfully."

    # PlistBuddy를 사용하여 LSMinimumSystemVersion 설정
    PLIST_FILE="dist/$APP_NAME.app/Contents/Info.plist"
    if [ -f "$PLIST_FILE" ] && [ -n "$MACOSX_DEPLOYMENT_TARGET" ]; then
        echo "Setting LSMinimumSystemVersion to $MACOSX_DEPLOYMENT_TARGET in $PLIST_FILE"
        /usr/libexec/PlistBuddy -c "Delete :LSMinimumSystemVersion" "$PLIST_FILE" 2>/dev/null # 기존 값 삭제 (오류 무시)
        /usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string $MACOSX_DEPLOYMENT_TARGET" "$PLIST_FILE"
    else
        echo "Warning: Info.plist not found or MACOSX_DEPLOYMENT_TARGET not set. Skipping LSMinimumSystemVersion update."
    fi

    echo "Creating DMG..."
    create-dmg \
      --volname "$APP_NAME" \
      --window-pos 200 120 \
      --window-size 800 400 \
      --icon-size 100 \
      --icon "$APP_NAME.app" 200 190 \
      --hide-extension "$APP_NAME.app" \
      --app-drop-link 600 185 \
      "dist/$APP_NAME.dmg" \
      "dist/$APP_NAME.app"
    
    if [ ! -f "dist/$APP_NAME.dmg" ]; then
        echo "Error: create-dmg did not create the .dmg file."
        exit 1
    fi
    echo "$APP_NAME.dmg created successfully."

else
    echo "Unsupported OS for this build script: $OS. This script is primarily for macOS DMG creation."
    exit 1
fi

echo "========================================"
echo "Build successful!"
echo "Executable created in the 'dist' directory."
echo "========================================"
