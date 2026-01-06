#!/bin/bash
set -e

echo "========================================="
echo "Building RustDesk Android APK in Docker"
echo "========================================="

cd /app

# 跳过 vcpkg 依赖构建，直接编译 Rust 库
# Android 构建不需要 hwcodec 相关的 vcpkg 依赖
echo "Skipping vcpkg dependencies for Android build..."

# 设置环境变量
export ANDROID_NDK_HOME=/opt/android-sdk/ndk/25.1.8937393
export PATH="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}"

# 编译 Rust 库（arm64），使用 flutter 和 mediacodec 特性
echo "Building Rust library for aarch64-linux-android..."
cargo ndk --platform 21 --target aarch64-linux-android build --release --features "flutter,mediacodec,use_dasp"

# 复制库文件到 jniLibs
echo "Copying library files..."
mkdir -p /app/flutter/android/app/src/main/jniLibs/arm64-v8a
cp target/aarch64-linux-android/release/liblibrustdesk.so /app/flutter/android/app/src/main/jniLibs/arm64-v8a/

# 构建 Flutter APK
echo "Building Flutter APK..."
cd /app/flutter

# 使用项目自带的 Flutter
export PATH="/app/flutter/bin:$PATH"
flutter pub get
flutter build apk --release --target-platform android-arm64

echo "========================================="
echo "Build completed!"
echo "APK location: /app/flutter/build/app/outputs/flutter-apk/app-release.apk"
echo "========================================="

