[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🌐 Tide Pro - 正在啟動 GitHub Actions 雲端 macOS-14 建置導航..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$workflowUrl = "https://github.com/beigou0427/tide_forecast_app/actions/workflows/build_ios.yml"
$workflowFile = ".\.github\workflows\build_ios.yml"

# 1. 檢查工作流檔案是否存在
if (!(Test-Path $workflowFile)) {
    Write-Host "⚠️ 警告：本機尚未偵測到 $workflowFile，請先確認檔案已建立！" -ForegroundColor Yellow
} else {
    Write-Host "✅ 成功鎖定本地工作流檔案: $workflowFile" -ForegroundColor Green
}

# 2. 提示即刻操作步驟
Write-Host "`n📋 【GitHub Actions 雲端 3 分鐘打包指南】" -ForegroundColor Yellow
Write-Host "  步驟 1：網頁將自動開啟專屬工作流頁面" -ForegroundColor White
Write-Host "  步驟 2：點擊右側的【Run workflow】按鈕 -> 點擊綠色【Run workflow】確認" -ForegroundColor Cyan
Write-Host "  步驟 3：GitHub 最新 macOS-14 (M2 晶片) 主機將在 4~6 分鐘內跑完 21 項測試並編譯" -ForegroundColor Gray
Write-Host "  步驟 4：建置完成後，在該頁面下方的【Artifacts】點擊下載：" -ForegroundColor White
Write-Host "          📦 TidePro_Release_v2.6.0_b5.zip" -ForegroundColor Green
Write-Host "  步驟 5：解壓縮後即為正式提審的 Release 封包，直接上傳至 App Store Connect！" -ForegroundColor White

Write-Host "`n🚀 正在為您開啟瀏覽器..." -ForegroundColor Cyan
Start-Process $workflowUrl

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "✅ 瀏覽器已直達工作流頁面！請依照上方 5 步驟領取最新 Release IPA！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green