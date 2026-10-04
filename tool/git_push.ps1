[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在將 Tide Pro VVIP 海事旗艦版成果安全推送到 GitHub..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 暫存所有變更
Write-Host "`n📦 [步驟 1/3] 暫存變更 (git add -A)..." -ForegroundColor Yellow
git add -A

# 2. 安全檢查：確保未將 .p8 私鑰納入暫存
$stagedP8 = git diff --cached --name-only | Where-Object { $_ -match "\.p8$" }
if ($stagedP8) {
    Write-Host "🚨 警報！偵測到 .p8 私鑰檔案已被暫存，正在緊急移除暫存..." -ForegroundColor Red
    git reset HEAD AuthKey_*.p8 *.p8
    Write-Host "已解除私鑰暫存，私鑰安全受保護。" -ForegroundColor Green
}

# 3. 建立語意化 Commit
Write-Host "`n📝 [步驟 2/3] 建立 Git 提交訊息..." -ForegroundColor Yellow
$commitMsg = "feat: VVIP 海事純潮汐標準重塑完畢 - 剷除假情報/業配雜質，封死代幣白嫖，Apple Connect 4大商品就緒 (0錯誤0警告)"
git commit -m $commitMsg

# 4. 推送到遠端倉庫
Write-Host "`n⬆️ [步驟 3/3] 推送到遠端分支 (git push)..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "🎉 恭喜！Tide Pro 專案所有 VVIP 海事代碼與工具已成功推送至 GitHub！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 推送遭遇問題，若尚未綁定遠端分支，請執行: git push -u origin main" -ForegroundColor Yellow
}