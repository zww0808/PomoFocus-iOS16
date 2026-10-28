#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodebuild >/dev/null || { echo '需要 macOS + Xcode'; exit 1; }
mkdir -p dist
xcodebuild -project PomoFocus.xcodeproj -scheme PomoFocus -configuration Release -sdk iphoneos -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
APP="build/Build/Products/Release-iphoneos/PomoFocus.app"
[ -f "$APP/PomoFocus" ] || { echo "未找到应用可执行文件"; exit 1; }
rm -rf dist/Payload
mkdir -p dist/Payload
cp -R "$APP" dist/Payload/
(cd dist && zip -qry PomoFocus-iOS16-unsigned.ipa Payload)
rm -rf dist/Payload
echo "输出：dist/PomoFocus-iOS16-unsigned.ipa"
echo '提醒：这是未签名 IPA；TrollStore 可尝试导入，但是否安装成功取决于设备环境及签名规则。'
