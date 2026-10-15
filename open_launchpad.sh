#!/bin/zsh

SHOT_DIR="$(pwd)/AppStore_Screenshots"

echo -e "\033[36m🚀 正在為長官打開【Tide Pro 雲端作戰指揮中心】...\033[0m"

# 1. 在 Finder 中彈出 5 張神級截圖目錄
if [ -d "$SHOT_DIR" ]; then
  open "$SHOT_DIR"
  echo -e "\033[32m✔ 截圖目錄已在 Finder 中展開，準備拖曳上傳！\033[0m"
fi

# 2. 自動在 Safari 打開 GitHub Actions 雲端編譯進度
open "https://github.com/beigou0427/tide_forecast_app/actions"
echo -e "\033[32m✔ GitHub Actions 雲端進度頁面已開啟！\033[0m"

# 3. 自動在 Safari 打開 App Store Connect 管理後台
open "https://appstoreconnect.apple.com/apps/6761328495/appstore"
echo -e "\033[32m✔ App Store Connect 提審後台已開啟！\033[0m"

echo -e "\n\033[33m═══════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;32m🎉 戰鬥艦橋已就緒！請長官在 Safari 中檢閱雲端綠燈，完成最終提審！\033[0m"
echo -e "\033[33m═══════════════════════════════════════════════════════════════\033[0m\n"
