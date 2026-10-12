#!/bin/bash
# 🌟 Tide Pro - Mac Xcode 授權簽署與 CocoaPods 零缺陷修復腳本
set -e

echo "============================================================"
echo "🍏 [1/3] 正在請求 macOS 權限以自動同意 Xcode 授權合約..."
echo "============================================================"
sudo xcodebuild -license accept

echo "============================================================"
echo "🍏 [2/3] 進入 ios 目錄執行 CocoaPods 原生依賴安裝..."
echo "============================================================"
cd ios
rm -rf Podfile.lock Pods .symlinks
pod install --repo-update
cd ..

echo "============================================================"
echo "🎉 [3/3] CocoaPods 原生庫建置大功告成！正在啟動 Xcode..."
echo "============================================================"
open ios/Runner.xcworkspace