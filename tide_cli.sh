#!/bin/zsh

case "$1" in
  snap)
    DIR="$HOME/Desktop/AppStore_Screenshots"
    mkdir -p "$DIR"
    NAME="${2:-screenshot_$(date +%s)}"
    FILE="$DIR/${NAME}.png"
    xcrun simctl io booted screenshot "$FILE"
    echo -e "\033[32m📸 [截圖完成] 原寸像素已擷取至：$FILE\033[0m"
    ;;

  build)
    echo -e "\033[36m🚀 正在啟動 Tide Pro 本地 Release 混淆編譯與打包...\033[0m"
    flutter build ipa --release \
      --export-options-plist=ios/exportOptions.plist \
      --obfuscate \
      --split-debug-info=build/app/outputs/symbols
    echo -e "\033[32m✅ 本地 IPA 生成完成！路徑：build/ios/ipa/\033[0m"
    ;;

  ship)
    echo -e "\033[33m⚡ 正在打包 Git 標籤並推送至 GitHub 觸發雲端自動發布...\033[0m"
    git add .
    git commit -m "feat(release): Tide Pro v2.6.0+5 Flagship Edition" || true
    git tag -d v2.6.0 2>/dev/null || true
    git push origin :refs/tags/v2.6.0 2>/dev/null || true
    git tag -a v2.6.0 -m "Release Tide Pro v2.6.0+5 Flagship"
    git push origin HEAD --tags
    echo -e "\033[32m"
    echo "═══════════════════════════════════════════════════════════════"
    echo " 🚀 [雲端發布管線已啟動] 請至 GitHub Actions 檢閱雲端進度："
    echo "    https://github.com/beigou0427/tide_forecast_app/actions"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "\033[0m"
    ;;

  *)
    echo -e "\033[33m"
    echo "⚓【Tide Pro 旗艦戰艦指令手冊】"
    echo "  ./tide_cli.sh snap [名稱]   - 0秒自動擷取模擬器當前畫面至桌面 (符合 App Store 規範)"
    echo "  ./tide_cli.sh build        - 本地正式編譯混淆 Release IPA"
    echo "  ./tide_cli.sh ship         - 一鍵推送至雲端 CI/CD 自動投遞進 TestFlight"
    echo -e "\033[0m"
    ;;
esac
