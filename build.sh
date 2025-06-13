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
    # MACOSX_DEPLOYMENT_TARGET 환경 변수가 비어있지 않은지 확인하고 PyInstaller 옵션에 추가
    if [ -n "$MACOSX_DEPLOYMENT_TARGET" ]; then
        echo "Using explicit --macos-target-version: $MACOSX_DEPLOYMENT_TARGET"
        pyinstaller "${PYINSTALLER_OPTS[@]}" --macos-target-version "$MACOSX_DEPLOYMENT_TARGET" "$ENTRY_POINT"
    else
        echo "Warning: MACOSX_DEPLOYMENT_TARGET is not set. PyInstaller will use its default."
        pyinstaller "${PYINSTALLER_OPTS[@]}" "$ENTRY_POINT"
    fi

    if [ ! -d "dist/$APP_NAME.app" ]; then
        echo "Error: PyInstaller did not create the .app bundle correctly."
        exit 1
    fi
    echo "$APP_NAME.app bundle created successfully."

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
