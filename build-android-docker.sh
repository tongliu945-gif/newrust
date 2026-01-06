#!/bin/bash

# RustDesk Android APK 构建脚本 (使用 Docker)
# 在 macOS 上运行，使用 Linux Docker 容器构建

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKER_IMAGE="rustdesk-android-builder"

echo "================================================"
echo "RustDesk Android APK Builder (Docker)"
echo "================================================"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行！请启动 Docker Desktop"
    exit 1
fi

echo "✅ Docker 已运行"

# 构建 Docker 镜像
echo ""
echo "📦 构建 Docker 镜像（首次运行会比较慢，需要下载依赖）..."
docker build -t ${DOCKER_IMAGE} -f Dockerfile.android .

# 运行构建
echo ""
echo "🔨 开始构建 Android APK..."
docker run --rm \
    -v "${PROJECT_DIR}:/app" \
    -w /app \
    ${DOCKER_IMAGE}

# 检查输出
if [ -f "${PROJECT_DIR}/flutter/build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo ""
    echo "================================================"
    echo "✅ 构建成功！"
    echo "================================================"
    echo "APK 位置: flutter/build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    ls -lh "${PROJECT_DIR}/flutter/build/app/outputs/flutter-apk/app-release.apk"
else
    echo ""
    echo "❌ 构建失败，未找到 APK 文件"
    exit 1
fi

