[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在將 Tide Pro 最新省額度手動工作流推送到 GitHub..." -ForegroundColor Cyan
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
$commitMsg = "ci: 優化 GitHub Actions 為手動 workflow_dispatch 觸發，保證日常推送 0 額度消耗"
git commit -m $commitMsg

# 4. 推送到遠端倉庫
Write-Host "`n⬆️ [步驟 3/3] 推送到遠端分支 (git push)..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "🎉 恭喜！最新配置已成功推送到 GitHub，日常 push 0 額度消耗已正式生效！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 推送遭遇問題，請檢查網路連線或遠端分支權限！" -ForegroundColor Yellow
}