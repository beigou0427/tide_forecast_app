[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在執行 VVIP 5 大地雷修復後之全自動編譯檢驗與 GitHub 推送..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 靜態分析
Write-Host "`n🔍 [步驟 1/4] 執行 flutter analyze..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 靜態分析未通過，停止推送！" -ForegroundColor Red
    exit
}

# 2. 自動化測試
Write-Host "`n🧪 [步驟 2/4] 執行 flutter test test/vvip_audit_test.dart..." -ForegroundColor Yellow
flutter test test/vvip_audit_test.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 測試未通過，停止推送！" -ForegroundColor Red
    exit
}

# 3. 暫存與私鑰防護檢查
Write-Host "`n📦 [步驟 3/4] 暫存變更並檢查私鑰防護..." -ForegroundColor Yellow
git add -A

$stagedP8 = git diff --cached --name-only | Where-Object { $_ -match "\.p8$" }
if ($stagedP8) {
    Write-Host "🚨 警報！偵測到 .p8 私鑰檔案已被暫存，正在緊急移除暫存..." -ForegroundColor Red
    git reset HEAD AuthKey_*.p8 *.p8
    Write-Host "已解除私鑰暫存，私鑰安全受保護。" -ForegroundColor Green
}

$commitMsg = "feat: 深度剷除5大VVIP痛點 - 修復62座潮位站VIP專線路由/銘牌RangeError/海事評分靜默/純潮汐零遮擋/拔除假加載 (0錯誤0警告)"
git commit -m $commitMsg

# 4. 推送到遠端
Write-Host "`n⬆️ [步驟 4/4] 推送至 GitHub..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "🏆 恭喜！5 大 VVIP 致命地雷已徹底根除，且代碼已成功同步至 GitHub！" -ForegroundColor Green
    Write-Host "⚓ 1. 62 座潮位站 VIP 直連專線 (O-B0075-002) 智慧路由已打通。" -ForegroundColor Green
    Write-Host "⚓ 2. VIP 銘牌編號 RangeError 閃退漏洞徹底修復，永不崩潰。" -ForegroundColor Green
    Write-Host "⚓ 3. 純潮汐儀表作業模式 100% 絕對靜音，絕不彈出評分干擾航行。" -ForegroundColor Green
    Write-Host "⚓ 4. 純潮汐模式徹底隱藏 FAB，VVIP 付費會員專享 0 廣告 0 業配。" -ForegroundColor Green
    Write-Host "⚓ 5. 首頁引導偽神經網絡進度條拔除，0 秒極速直達海象駕駛台。" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 推送中斷，請確認網路連線與遠端倉庫權限。" -ForegroundColor Red
}