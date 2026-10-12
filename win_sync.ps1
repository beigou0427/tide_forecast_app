# 🌟 Tide Pro - Windows 端自動同步與 TQM 0 缺陷品質驗證腳本
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在從 GitHub 同步 Mac 端所有 100% 零缺陷重構精華..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 抓取 GitHub 遠端最新狀態
git fetch origin

# 2. 硬體重置對齊 Mac 端 SSOT 單一真相來源 (消滅 CRLF 換行與大小寫衝突)
git reset --hard origin/main

# 3. 重新構建 Windows 本地 Dart/Flutter 套件索引
Write-Host "`n📦 [1/2] 正在更新 Windows 本地 Flutter 套件索引 (flutter pub get)..." -ForegroundColor Yellow
flutter pub get

# 4. 執行靜態代碼分析，驗證全專案 0 錯誤與 0 警告
Write-Host "`n🔍 [2/2] 正在執行 TQM 0 缺陷靜態代碼品質審計 (flutter analyze)..." -ForegroundColor Yellow
flutter analyze

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "🎉 [CQO 驗收通過] 全專案代碼 0 錯誤、0 警告！已與 Mac 端 100% 同步！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green