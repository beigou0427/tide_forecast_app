[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 Tide Pro - App Store 官方版本查詢與 3 分鐘送審指引" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"

if (Test-Path ".\tool\target_app_id.txt") {
    $cachedId = (Get-Content ".\tool\target_app_id.txt").Trim()
    if ($cachedId) { $appId = $cachedId }
}

# 1. 簽發 ES256 JWT Token
$rawKey = (Get-Content $p8Path | Where-Object { $_ -notmatch '^-' }) -join ''
$keyBytes = [System.Convert]::FromBase64String($rawKey)
$cngKey = [System.Security.Cryptography.CngKey]::Import($keyBytes, [System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
$dsa = New-Object System.Security.Cryptography.ECDsaCng($cngKey)

function Base64UrlEncode([byte[]]$bytes) {
    [System.Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

$headerJson = "{`"alg`":`"ES256`",`"kid`":`"$keyId`",`"typ`":`"JWT`"}"
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$exp = $now + 1200
$payloadJson = "{`"iss`":`"$issuerId`",`"iat`":$now,`"exp`":$exp,`"aud`":`"appstoreconnect-v1`"}"

$unsignedToken = (Base64UrlEncode([System.Text.Encoding]::UTF8.GetBytes($headerJson))) + "." + (Base64UrlEncode([System.Text.Encoding]::UTF8.GetBytes($payloadJson)))
$sigBytes = $dsa.SignData([System.Text.Encoding]::UTF8.GetBytes($unsignedToken))
$jwt = "$unsignedToken." + (Base64UrlEncode($sigBytes))

$headers = @{
    "Authorization" = "Bearer $jwt"
    "Content-Type"  = "application/json"
}

# 2. 查詢 App Store Connect 中的現行版本狀態
Write-Host "📡 正在向 Apple 查詢現有 App Store 版本狀態..." -ForegroundColor Yellow
$versionUrl = "https://api.appstoreconnect.apple.com/v1/apps/$appId/appStoreVersions"

try {
    $verRes = Invoke-RestMethod -Uri $versionUrl -Headers $headers -Method Get
    if ($verRes.data) {
        foreach ($v in $verRes.data) {
            $verString = $v.attributes.versionString
            $verState = $v.attributes.appStoreState
            Write-Host "  • 商店版本 : $verString [狀態: $verState]" -ForegroundColor (if ($verState -eq "READY_FOR_SALE") { "Green" } else { "Cyan" })
        }
    }
} catch {
    Write-Host "⚠️ 版本查詢提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "`n============================================================" -ForegroundColor Yellow
Write-Host "📋 【最後 3 分鐘：App Store 提審最終操作清單】" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

Write-Host "第 1 步：前往 App Store Connect 網頁" -ForegroundColor White
Write-Host "  👉 點擊開啟：https://appstoreconnect.apple.com/apps/$appId/appstore" -ForegroundColor Cyan

Write-Host "`n第 2 步：新增版本或進入現有草稿 (例如 2.6.0)" -ForegroundColor White
Write-Host "  • 若目前無草稿，點擊左側版本旁的「+」號，新增版本（版本號輸入：2.6.0）" -ForegroundColor Gray

Write-Host "`n第 3 步：關聯剛建立的 2 支 READY_TO_SUBMIT 商品" -ForegroundColor White
Write-Host "  • 在該版本的頁面中向下滾動，找到【App 內購買項目和訂閱】(In-App Purchases and Subscriptions)" -ForegroundColor Gray
Write-Host "  • 點擊「+」選擇：" -ForegroundColor Gray
Write-Host "      1. 週費體驗版 (com.beigou.tide_app.pro_weekly)" -ForegroundColor Green
Write-Host "      2. 終身創始席次 (com.beigou.tide_app.pro_lifetime)" -ForegroundColor Green
Write-Host "  • 點擊「完成」將這兩項商品與版本正式綁定！" -ForegroundColor Gray

Write-Host "`n第 4 步：獲取構建版本 (IPA Build)" -ForegroundColor White
Write-Host "  • 前往 GitHub Actions 頁面：https://github.com/beigou0427/tide_forecast_app/actions" -ForegroundColor Cyan
Write-Host "  • 點擊「Build & Verify iOS Release」工作流 -> 點擊「Run workflow」按鈕" -ForegroundColor Gray
Write-Host "  • 雲端 macOS 會自動跑完編譯，在 Artifacts 下載產出的 TidePro_Release.ipa 即可！" -ForegroundColor Gray

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 指引已就緒！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan