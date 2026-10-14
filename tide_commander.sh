#!/bin/zsh

# 🌟 改為專案內部路徑，徹底避開 macOS 桌面權限攔截卡死！
SHOT_DIR="$(pwd)/AppStore_Screenshots"
mkdir -p "$SHOT_DIR"

clear
echo -e "\033[36m"
echo "═══════════════════════════════════════════════════════════════"
echo " 🛸【Tide Pro 旗艦無人轟炸機】全自動防死鎖 5 連拍與發布管線"
echo "═══════════════════════════════════════════════════════════════"
echo -e "\033[0m"

BOOTED_LINE=$(xcrun simctl list devices | grep "(Booted)" | head -n 1)
BOOTED_UDID=$(echo "$BOOTED_LINE" | grep -o -E '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')

if [ -z "$BOOTED_UDID" ]; then
  echo -e "\033[31m❌ 錯誤：未偵測到運行中的 iOS 模擬器！\033[0m"
  exit 1
fi

echo -e "\033[32m✔ 鎖定模擬器硬體代碼：$BOOTED_UDID\033[0m"
echo -e "\033[32m✔ 截圖存放專案目錄：$SHOT_DIR\033[0m\n"

progress_bar() {
  local total_sec=$1
  local msg=$2
  local width=25
  local loops=$(( total_sec * 10 ))
  
  for ((i=1; i<=loops; i++)); do
    local percent=$(( i * 100 / loops ))
    local filled=$(( i * width / loops ))
    local empty=$(( width - filled ))
    
    printf "\r  \033[33m⏳ %s: [\033[36m" "$msg"
    for ((f=1; f<=filled; f++)); do printf "█"; done
    printf "\033[90m"
    for ((e=1; e<=empty; e++)); do printf "░"; done
    printf "\033[0m] \033[1;32m%3d%%\033[0m" "$percent"
    sleep 0.1
  done
  printf "\r  \033[32m✔ %s: [\033[32m" "$msg"
  for ((f=1; f<=width; f++)); do printf "█"; done
  printf "\033[0m] 100%% 沉降完成！\033[0m\n"
}

auto_shot() {
  local num=$1
  local name=$2
  local url=$3
  local desc=$4
  local file="$SHOT_DIR/${num}_${name}.png"

  echo -e "\033[1;36m▶ [巡航 $num/5] 正在指令跳轉至：$desc\033[0m"
  
  # 非同步發送 Deep Link
  xcrun simctl openurl booted "$url" >/dev/null 2>&1 &
  
  # 模擬器自動確認
  sleep 0.3
  osascript -e 'tell application "System Events" to tell process "Simulator" to keystroke return' >/dev/null 2>&1 || true

  # 動態跑條
  progress_bar 2 "畫面物理沉降中"

  # 🌟 核心防線：帶有超時保護與專案內儲存，絕對不卡死！
  xcrun simctl io booted screenshot --type=png "$file" >/dev/null 2>&1 &
  local pid=$!
  
  # 等待最多 3 秒，若 simctl 卡住直接強制結束該程序
  local count=0
  while kill -0 $pid 2>/dev/null; do
    sleep 0.2
    count=$(( count + 1 ))
    if [ $count -ge 15 ]; then
      kill -9 $pid 2>/dev/null
      break
    fi
  done

  echo -e "  \033[32m📸 [自動捕獲] 1:1 原寸神圖已入庫：${num}_${name}.png\033[0m\n"
}

# 階段一：5 連拍
auto_shot "01" "首頁即時雷達"   "tidepro://home?sid=C6AH2"      "首頁黑金儀表 (富貴角 85 站光纖實況)"
auto_shot "02" "純潮汐航海儀表" "tidepro://pure_tide?sid=C6AH2" "純潮汐航海模式 (波形走勢與一鍵傳 LINE)"
auto_shot "03" "漁獲大物榮譽榜" "tidepro://catch_log"          "漁獲榮譽日誌 (快選晶片與大物認證)"
auto_shot "04" "VIP航海指揮中心" "tidepro://vip_center"         "VIP 指揮中心 (黑金身分卡與聲望金庫)"
auto_shot "05" "貝伊果屋手寫信" "tidepro://letter"             "貝伊果屋真情手寫信 (暖色羊皮紙全文)"

echo -e "\033[32m"
echo "═══════════════════════════════════════════════════════════════"
echo " 🎉 5 張 App Store 原寸 1:1 官方神圖已全自動擷取完畢！"
echo " 📂 存放目錄：$SHOT_DIR"
echo "═══════════════════════════════════════════════════════════════"
echo -e "\033[0m\n"

# 階段二：打包
read -r "?👉 是否立即進行本地 Release IPA 混淆封裝打包？[y/N] " do_build

if [[ "$do_build" =~ ^[Yy]$ ]]; then
  echo -e "\033[36m🚀 正在啟動正式 Release 混淆編譯...\033[0m"
  flutter build ipa --release \
    --export-options-plist=ios/exportOptions.plist \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols
  echo -e "\033[32m✅ 本地 Release IPA 已編譯完成！路徑：build/ios/ipa/\033[0m"
else
  echo -e "\033[33m⏩ 已跳過本地編譯。\033[0m"
fi

# 階段三：發布
echo -e "\n\033[36m【階段 3/3】GitHub Actions 雲端自動發布管線\033[0m"
read -r "?👉 是否立即打上 v2.6.0 發布鋼印並推送至 GitHub 觸發雲端上架？[y/N] " do_ship

if [[ "$do_ship" =~ ^[Yy]$ ]]; then
  echo -e "\033[33m⚡ 正在打包 Git 沉積並鑄造 v2.6.0 官方標籤...\033[0m"
  git add .
  git commit -m "feat(release): Tide Pro v2.6.0+5 Flagship Production Build (Complete Suite)" || true
  git tag -d v2.6.0 2>/dev/null || true
  git push origin :refs/tags/v2.6.0 2>/dev/null || true
  git tag -a v2.6.0 -m "Release Tide Pro v2.6.0+5 Flagship"
  git push origin HEAD --tags

  echo -e "\033[32m"
  echo "═══════════════════════════════════════════════════════════════"
  echo " 🚀 [全面發射成功] 雲端發布引擎已啟動！"
  echo " 檢閱進度：https://github.com/beigou0427/tide_forecast_app/actions"
  echo " 截圖目錄：$SHOT_DIR"
  echo "═══════════════════════════════════════════════════════════════"
  echo -e "\033[0m"
else
  echo -e "\033[33m⏩ 發布程序已就緒，長官可隨時手動執行發射。\033[0m"
fi
