Write-Host "🚀 正在將 Tide Pro 潮汐表 VVIP 海事純淨旗艦版推送至 GitHub..." -ForegroundColor Cyan

# 1. 加入所有變更
Write-Host "`n📦 [步驟 1/3] 暫存所有重構變更 (git add -A)..." -ForegroundColor Yellow
git add -A

# 2. 建立海事語意化提交訊息
Write-Host "`n📝 [步驟 2/3] 建立 Git Commit..." -ForegroundColor Yellow
$commitMsg = "feat: 重構海事純潮汐旗艦版 - 剷除假情報/業配雜質，錨定官方潮汐極值，封死代幣白嫖漏洞，修復編譯警告"
git commit -m $commitMsg

# 3. 推送至遠端倉庫
Write-Host "`n⬆️ [步驟 3/3] 推送至 GitHub (git push)..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "🎉 恭喜！Tide Pro 旗艦重構成果已 100% 成功同步至 GitHub！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ 推送中斷，若尚未設定遠端分支請執行：git push -u origin main" -ForegroundColor Red
}