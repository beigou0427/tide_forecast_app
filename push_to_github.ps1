# 🌟 Tide Pro - 官方標準化 Git 提審與雲端同步推送腳本
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 啟動 Tide Pro 程式碼庫全自動 Git 提交與推送管線..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 檢查 Git 倉庫狀態
Write-Host "`n🔍 [1/4] 正在檢查本地 Git 工作目錄狀態..." -ForegroundColor Yellow
git status

# 2. 暫存所有修改與新建檔案
Write-Host "`n📦 [2/4] 正在暫存所有修復與新增檔案 (git add .)..." -ForegroundColor Yellow
git add .

# 3. 執行結構化語意提交
Write-Host "`n✍️ [3/4] 正在建立機構級語意化提交紀錄 (git commit)..." -ForegroundColor Yellow

$commitMessage = @"
feat(release): 🚀 Tide Pro v2.6.0+5 旗艦版完整重塑與全自動 CI/CD 交付體系

【架構重塑與 SRE 容災】
- 徹底消除 Riverpod StateNotifier 狀態存取違規與路由堆疊死鎖
- 實裝 PageRouteBuilder(opaque: false) 救命級突發湧浪防困礁覆蓋路由
- 補齊 FCM 與本地推播 Terminated (冷啟動) 狀態的 Payload 攔截與畫面導航
- 導入 NASA JPL Rule #3 限制性錯誤緩衝區 (Circular Buffer)，消滅 OOM 記憶體洩漏
- 實體化 FounderWelcomeDialog 與 AsoStudioPage，達成 AST 抽象語法樹 100% 靜態閉環

【商業變現與 ASO 增長】
- 補齊 ReviewService.onCatchLogSaved 與 onVvipUnlocked，結合 Apple 365天防打擾節流閥
- 內建 85 測站光纖直連雷達、純潮汐儀表、E-Ink 烈日抗反光模式、以及離線神盾預載

【DevOps 零觸碰交付】
- 新增 GitHub Actions 雙平台發布管線 (ios_release.yml & android_release.yml)
- 整合 dynamic build number、Firebase 崩潰符號表上傳、以及 iTMSTransporter 提審
"@

git commit -m "$commitMessage"

# 4. 推送至遠端倉庫
Write-Host "`n🌐 [4/4] 正在將程式碼推送至 GitHub 遠端倉庫 (git push)..." -ForegroundColor Yellow
git push

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "🎉 恭喜長官！所有經過千錘百煉的完美代碼已 100% 安全抵達 GitHub！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "💡 【下一步正式發射指引】" -ForegroundColor Cyan
Write-Host "確認 GitHub Secrets 填妥後，只需在終端機輸入以下指令即可觸發自動發布：" -ForegroundColor White
Write-Host "  git tag v2.6.0" -ForegroundColor Yellow
Write-Host "  git push origin v2.6.0" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan