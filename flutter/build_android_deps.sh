#!/bin/bash

set -e -o pipefail

ANDROID_ABI=$1

# Build RustDesk dependencies for Android using vcpkg.json
# Required:
#   1. set VCPKG_ROOT / ANDROID_NDK path environment variables
#   2. vcpkg initialized
#   3. ndk, version: r25c or newer

if [ -z "$ANDROID_NDK_HOME" ]; then
  echo "Failed! Please set ANDROID_NDK_HOME"
  exit 1
fi

if [ -z "$VCPKG_ROOT" ]; then
  echo "Failed! Please set VCPKG_ROOT"
  exit 1
fi

API_LEVEL="21"

# Get directory of this script

SCRIPTDIR="$(readlink -f "$0")"
SCRIPTDIR="$(dirname "$SCRIPTDIR")"

# Check if vcpkg.json is one level up - in root directory of RD

if [ ! -f "$SCRIPTDIR/../vcpkg.json" ]; then
  echo "Failed! Please check where vcpkg.json is!"
  exit 1
fi

# NDK llvm toolchain

HOST_TAG="linux-x86_64" # current platform, set as `ls $ANDROID_NDK/toolchains/llvm/prebuilt/`
TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/$HOST_TAG

function build {
  ANDROID_ABI=$1

  case "$ANDROID_ABI" in
  arm64-v8a)
     ABI=aarch64-linux-android$API_LEVEL
     VCPKG_TARGET=arm64-android
     ;;
  armeabi-v7a)
     ABI=armv7a-linux-androideabi$API_LEVEL
     VCPKG_TARGET=arm-neon-android
     ;;
  x86_64)
     ABI=x86_64-linux-android$API_LEVEL
     VCPKG_TARGET=x64-android
     ;;
  x86)
     ABI=i686-linux-android$API_LEVEL
     VCPKG_TARGET=x86-android
     ;;
  *)
     echo "ERROR: ANDROID_ABI must be one of: arm64-v8a, armeabi-v7a, x86_64, x86" >&2
     return 1
  esac

  echo "*** [$ANDROID_ABI][Start] Build and install vcpkg dependencies"
  pushd "$SCRIPTDIR/.."
  
  # === DEBUG: Print environment and paths ===
  echo "=========================================="
  echo "DEBUG: Environment Variables"
  echo "=========================================="
  echo "VCPKG_ROOT=$VCPKG_ROOT"
  echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME"
  echo "ANDROID_NDK=$ANDROID_NDK"
  echo "VCPKG_TARGET=$VCPKG_TARGET"
  echo "PWD=$(pwd)"
  echo ""
  
  echo "=========================================="
  echo "DEBUG: vcpkg version"
  echo "=========================================="
  $VCPKG_ROOT/vcpkg version || echo "Failed to get vcpkg version"
  echo ""
  
  echo "=========================================="
  echo "DEBUG: vcpkg.json content"
  echo "=========================================="
  cat vcpkg.json
  echo ""
  
  echo "=========================================="
  echo "DEBUG: overlay-ports directory (res/vcpkg)"
  echo "=========================================="
  ls -la res/vcpkg/ || echo "res/vcpkg not found!"
  echo ""
  
  echo "=========================================="
  echo "DEBUG: opus overlay-port files"
  echo "=========================================="
  ls -la res/vcpkg/opus/ || echo "res/vcpkg/opus not found!"
  cat res/vcpkg/opus/vcpkg.json || echo "opus vcpkg.json not found!"
  echo ""
  
  # Run vcpkg install with verbose output
  echo "=========================================="
  echo "DEBUG: Running vcpkg install"
  echo "=========================================="
  echo "Command: $VCPKG_ROOT/vcpkg install --triplet $VCPKG_TARGET --x-install-root=$VCPKG_ROOT/installed --overlay-ports=$SCRIPTDIR/../res/vcpkg"
  
  $VCPKG_ROOT/vcpkg install --triplet $VCPKG_TARGET --x-install-root="$VCPKG_ROOT/installed" --overlay-ports="$SCRIPTDIR/../res/vcpkg"
  
  # === DEBUG: Verify installation ===
  echo "=========================================="
  echo "DEBUG: Checking installed files"
  echo "=========================================="
  echo "Installed directory structure:"
  ls -la "$VCPKG_ROOT/installed/" || echo "installed/ dir not found!"
  echo ""
  
  echo "Target triplet directory:"
  ls -la "$VCPKG_ROOT/installed/$VCPKG_TARGET/" || echo "$VCPKG_TARGET dir not found!"
  echo ""
  
  echo "Include directory:"
  ls -la "$VCPKG_ROOT/installed/$VCPKG_TARGET/include/" || echo "include/ dir not found!"
  echo ""
  
  echo "Opus headers:"
  ls -la "$VCPKG_ROOT/installed/$VCPKG_TARGET/include/opus/" || echo "opus/ dir not found - THIS IS THE PROBLEM!"
  echo ""
  
  echo "Lib directory:"
  ls -la "$VCPKG_ROOT/installed/$VCPKG_TARGET/lib/" || echo "lib/ dir not found!"
  echo ""
  
  echo "Looking for libopus:"
  find "$VCPKG_ROOT/installed/$VCPKG_TARGET/" -name "*opus*" 2>/dev/null || echo "No opus files found!"
  echo "=========================================="
  
  popd
  head -n 100 "${VCPKG_ROOT}/buildtrees/ffmpeg/build-$VCPKG_TARGET-rel-out.log" || true
  echo "*** [$ANDROID_ABI][Finished] Build and install vcpkg dependencies"

if [ -d "$VCPKG_ROOT/installed/arm-neon-android" ]; then
  echo "*** [Start] Move arm-neon-android to arm-android"

  mv "$VCPKG_ROOT/installed/arm-neon-android" "$VCPKG_ROOT/installed/arm-android"

  echo "*** [Finished] Move arm-neon-android to arm-android"
fi
}

if [ ! -z "$ANDROID_ABI" ]; then
  build "$ANDROID_ABI"
else
  echo "Usage: build-android-deps.sh <ANDROID-ABI>" >&2
  exit 1
fi
