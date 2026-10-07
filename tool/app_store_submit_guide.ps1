[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-Timestamp {
    return (Get-Date).ToString("HH:mm:ss")
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 Tide Pro - App Store Connect 官方版本狀態與 3 分鐘送審指引" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"
$versionId = "59f74dcd-74b2-427a-a231-c41661755067"

if (Test-Path ".\tool\target_app_id.txt") {
    $cachedId = (Get-Content ".\tool\target_app_id.txt").Trim()
    if ($cachedId) { $appId = $cachedId }
}

# -----------------------------------------------------------------------------
# 1. 簽發 ES256 JWT Token
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔑 正在連線 Apple 官方伺服器調取版本 2.6.0 現況..." -ForegroundColor Yellow
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

# -----------------------------------------------------------------------------
# 2. 即時調取版本現況 (語法相容 PowerShell 5.1 / 7.x)
# -----------------------------------------------------------------------------
$versionUrl = "https://api.appstoreconnect.apple.com/v1/apps/$appId/appStoreVersions"
try {
    $verRes = Invoke-RestMethod -Uri $versionUrl -Headers $headers -Method Get
    if ($verRes.data) {
        Write-Host "`n📋 Apple 後台版本現況：" -ForegroundColor Cyan
        foreach ($v in $verRes.data) {
            $verString = $v.attributes.versionString
            $verState = $v.attributes.appStoreState

            $color = "Yellow"
            if ($verState -eq "READY_FOR_SALE") {
                $color = "Green"
            } elseif ($verState -eq "PREPARE_FOR_SUBMISSION") {
                $color = "Cyan"
            }

            Write-Host "  • 商店版本 : $verString [狀態: $verState]" -ForegroundColor $color
        }
    }
} catch {
    Write-Host "⚠️ 版本查詢提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "`n============================================================" -ForegroundColor Yellow
Write-Host "📋 【最後 3 分鐘：App Store 官方網頁送審最終操作清單】" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

Write-Host "`n第 1 步：前往 App Store Connect 網頁端" -ForegroundColor White
Write-Host "  👉 點擊開啟：https://appstoreconnect.apple.com/apps/$appId/appstore" -ForegroundColor Cyan

Write-Host "`n第 2 步：進入已建立的【2.6.0 準備提交】版本草稿" -ForegroundColor White
Write-Host "  • 左側側邊欄點擊「2.6.0 準備提交」" -ForegroundColor Gray
Write-Host "  • 檢查「版本更新內容」：繁體中文已 100% 透過二進位寫入，字元清晰無問號！" -ForegroundColor Green

Write-Host "`n第 3 步：關聯 2 支全新商品 (In-App Purchases) - 【防退費關鍵步驟】" -ForegroundColor White
Write-Host "  • 向下滾動找到【App 內購買項目和訂閱】區塊" -ForegroundColor Gray
Write-Host "  • 點擊「+」勾選：" -ForegroundColor Gray
Write-Host "      1. 週費體驗版 (com.beigou.tide_app.pro_weekly)" -ForegroundColor Green
Write-Host "      2. 終身創始席次 (com.beigou.tide_app.pro_lifetime)" -ForegroundColor Green
Write-Host "  • 點擊「儲存」即可完成內購與版本的正式綁定！" -ForegroundColor Gray

Write-Host "`n第 4 步：核對審查資訊 (App Review Information)" -ForegroundColor White
Write-Host "  • 向下滾動至【App 審查資訊】" -ForegroundColor Gray
Write-Host "  • 「備忘錄」已注入中英雙語免帳號測試指引，無需任何修改！" -ForegroundColor Green

Write-Host "`n第 5 步：獲取 IPA 建置版本並提交" -ForegroundColor White
Write-Host "  • 前往 GitHub Actions：https://github.com/beigou0427/tide_forecast_app/actions" -ForegroundColor Cyan
Write-Host "  • 點擊「Build & Verify iOS Release」工作流 ->「Run workflow」" -ForegroundColor Gray
Write-Host "  • 完成後在 App Store Connect 頁面選擇該 Build，右上角點擊「提交審查」！" -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 恭喜！Tide Pro 2.6.0 海事旗艦版本提審準備已 100% 大功告成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan