Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍎 Tide Pro 潮汐表 - App Store Connect 自動化設定與規格中樞" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 本專案權威海事配置規格
$bundleId = "com.beigou.tideForecastApp"
$appName = "潮汐表 Pro - 釣魚海象浪高與風速預報，老船長 AI 出海決策"
$privacyUrl = "https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009"
$eulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

$products = @(
    @{
        ID = "com.beigou.tide_app.pro_weekly"
        Type = "自動續訂訂閱 (Auto-Renewable Subscription)"
        Name = "週費體驗版"
        Price = "NT$ 60 / 週"
        Trial = "無"
    },
    @{
        ID = "com.beigou.tide_app.pro_monthly"
        Type = "自動續訂訂閱 (Auto-Renewable Subscription)"
        Name = "月度專業版"
        Price = "NT$ 120 / 月"
        Trial = "無"
    },
    @{
        ID = "com.beigou.tide_app.pro_yearly"
        Type = "自動續訂訂閱 (Auto-Renewable Subscription)"
        Name = "年度指揮官計畫"
        Price = "NT$ 990 / 年"
        Trial = "7 天免費試用 (相容 Apple 家人共享)"
    },
    @{
        ID = "com.beigou.tide_app.pro_lifetime"
        Type = "非消耗型項目 (Non-Consumable)"
        Name = "終身創始席次"
        Price = "NT$ 2,990 (一次性買斷)"
        Trial = "永久享有特權"
    }
)

Write-Host "`n📱 [App 基本設定規格]" -ForegroundColor Yellow
Write-Host "• Bundle Identifier : $bundleId"
Write-Host "• 應用程式名稱       : $appName"
Write-Host "• 隱私權政策 (URL)   : $privacyUrl"
Write-Host "• 使用者授權合約(URL): $eulaUrl"

Write-Host "`n💎 [StoreKit 4 大內購商品規格矩陣 (嚴格對齊專案程式碼)]" -ForegroundColor Yellow
foreach ($p in $products) {
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  項目名稱 : $($p.Name) [$($p.Type)]" -ForegroundColor White
    Write-Host "  商品 ID  : $($p.ID)" -ForegroundColor Green
    Write-Host "  定價金額 : $($p.Price)" -ForegroundColor Cyan
    Write-Host "  試用/優惠: $($p.Trial)" -ForegroundColor Yellow
}
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

# 檢查本機是否有 App Store Connect API Key (.p8)
$keyFiles = Get-ChildItem -Path . -Filter "AuthKey_*.p8" -Recurse -ErrorAction SilentlyContinue

if ($keyFiles.Count -gt 0) {
    Write-Host "`n🔑 偵測到 App Store Connect API 私鑰: $($keyFiles[0].Name)" -ForegroundColor Green
    Write-Host "可直接透過 REST API (https://api.appstoreconnect.apple.com/v1/) 進行無人值守建立！"
} else {
    Write-Host "`n💡 [指令與手動快速設定指引]" -ForegroundColor Cyan
    Write-Host "若要使用純指令建立商品，請前往 Apple 官方後台取得 API 密鑰："
    Write-Host "1. 前往 App Store Connect -> [使用者與存取權] -> [整合 / 密鑰] (Keys)"
    Write-Host "2. 點擊「產生 API 密鑰」，取得：Issuer ID, Key ID，並下載 AuthKey_xxxx.p8 放入本專案"
    Write-Host "3. 若要在網頁後台手動秒建，請直接對照上方綠色【商品 ID】與【定價】填入即可，5 分鐘即可完成！"
}