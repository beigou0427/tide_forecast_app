#!/bin/bash
# 🌟 Tide Pro - Mac 終端機全自動克隆與環境修復引導腳本
set -e

echo "============================================================"
echo "🍏 歡迎來到 Mac 終端機！正在檢查 CocoaPods 與 Flutter 環境..."
echo "============================================================"

# 1. 檢查 Flutter 是否加入 PATH
if ! command -v flutter &> /dev/null; then
    echo "⚠️ 未偵測到 flutter 指令！請確認已安裝 Flutter SDK 並加入環境變數。"
    exit 1
fi

# 2. 清理與安裝 Dart 依賴
echo "📦 [1/3] 正在拉取 Flutter 依賴套件 (flutter pub get)..."
flutter pub get

# 3. 進入 iOS 重建 CocoaPods
echo "🍏 [2/3] 正在為 Apple Silicon 重建 iOS Pods 依賴庫..."
cd ios
rm -rf Podfile.lock Pods .symlinks
pod install --repo-update
cd ..

echo "============================================================"
echo "🎉 [3/3] 部署大功告成！"
echo "👉 若要開啟 Xcode 請執行: open ios/Runner.xcworkspace"
echo "👉 若要直接啟動除錯請執行: flutter run"
echo "============================================================"