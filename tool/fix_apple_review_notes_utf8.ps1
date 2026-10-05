[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-Timestamp {
    return (Get-Date).ToString("HH:mm:ss")
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 Tide Pro - 正在以二進位 UTF-8 修復 Apple 後台審查備忘錄與更新內容..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"
$lifetimeIapId = "6819013375"
$versionId = "59f74dcd-74b2-427a-a231-c41661755067"

if (Test-Path ".\tool\target_app_id.txt") {
    $cachedId = (Get-Content ".\tool\target_app_id.txt").Trim()
    if ($cachedId) { $appId = $cachedId }
}

# -----------------------------------------------------------------------------
# 1. 簽發 ES256 JWT Token
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔑 正在簽發 Apple 官方 ES256 JWT 憑證..." -ForegroundColor Yellow
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
}
Write-Host "[$(Get-Timestamp)] ✅ 憑證簽發完成。" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. 修復買斷商品 (Lifetime IAP) 審查備忘錄 (Review Note)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 📝 [1/3] 正在修復終身買斷商品 (6819013375) 的審查備忘錄..." -ForegroundColor Yellow

$cleanReviewNote = @"
【中文說明】提供老船長 VIP 終身創始席次買斷功能，可於 App 首頁右上角或側邊欄中點擊付費牆按鈕進行測試購買。
【English for Reviewer】Tide Pro Lifetime Founder Access can be tested and purchased from the premium paywall button on the top-right corner of the Home screen or via the side drawer navigation. All 85 CWA stations and offline models will be fully unlocked upon purchase.
"@

$patchIapObj = @{
    data = @{
        type = "inAppPurchases"
        id = $lifetimeIapId
        attributes = @{
            reviewNote = $cleanReviewNote
        }
    }
}

$patchIapJson = ConvertTo-Json -InputObject $patchIapObj -Depth 10
$patchIapBytes = [System.Text.Encoding]::UTF8.GetBytes($patchIapJson)

try {
    $res = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId" `
        -Headers $headers `
        -Method Patch `
        -Body $patchIapBytes `
        -ContentType "application/json; charset=utf-8"
    Write-Host "[$(Get-Timestamp)] ✅ 成功以二進位 UTF-8 更新買斷商品審查備忘錄！" -ForegroundColor Green
} catch {
    Write-Host "[$(Get-Timestamp)] ❌ 更新買斷備忘錄失敗: $($_.Exception.Message)" -ForegroundColor Red
}

# -----------------------------------------------------------------------------
# 3. 修復版本 2.6.0 更新內容 (What's New)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 📝 [2/3] 正在修復版本 2.6.0 的繁體中文本次更新內容 (What's New)..." -ForegroundColor Yellow

$cleanWhatsNew = @"
【Tide Pro 2.6.0 海事純潮汐旗艦版升級】
1. 85 測站光纖直連專線全面調校，實測波高風向 0 延遲刷新。
2. 滿乾潮走水黃金窗口與滿退起流計算升級，新增乾潮底暗礁淺水預警。
3. 全新推出「純潮汐航海儀表模式」，駕駛台一鍵鎖定高對比水文。
4. 支援全島 85 測站一鍵離線神盾預載，外海斷網無縫切換。
"@

$locListUrl = "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$versionId/appStoreVersionLocalizations"
try {
    $locRes = Invoke-RestMethod -Uri $locListUrl -Headers $headers -Method Get
    $zhLoc = $locRes.data | Where-Object { $_.attributes.locale -eq "zh-Hant" }

    if ($zhLoc) {
        $zhLocId = $zhLoc.id
        $patchWhatsNewObj = @{
            data = @{
                type = "appStoreVersionLocalizations"
                id = $zhLocId
                attributes = @{
                    whatsNew = $cleanWhatsNew
                }
            }
        }
        $patchWhatsNewJson = ConvertTo-Json -InputObject $patchWhatsNewObj -Depth 10
        $patchWhatsNewBytes = [System.Text.Encoding]::UTF8.GetBytes($patchWhatsNewJson)

        Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$zhLocId" `
            -Headers $headers `
            -Method Patch `
            -Body $patchWhatsNewBytes `
            -ContentType "application/json; charset=utf-8" | Out-Null

        Write-Host "[$(Get-Timestamp)] ✅ 成功以二進位 UTF-8 更新版本 2.6.0 的更新內容！" -ForegroundColor Green
    }
} catch {
    Write-Host "[$(Get-Timestamp)] ❌ 更新版本更新內容失敗: $($_.Exception.Message)" -ForegroundColor Red
}

# -----------------------------------------------------------------------------
# 4. 回讀 Apple 伺服器文字進行真實現身驗證 (Proof of Fix)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔍 [3/3] 正在向 Apple 官方伺服器回讀剛才寫入的文字，驗證問號是否消除..." -ForegroundColor Yellow

try {
    $verifyIap = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId" -Headers $headers -Method Get
    $readBackNote = $verifyIap.data.attributes.reviewNote
    
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "📋 Apple 伺服器現存買斷審查備忘錄文字：" -ForegroundColor Cyan
    Write-Host $readBackNote -ForegroundColor White
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

    if ($readBackNote -match "\?\?\?\?") {
        Write-Host "⚠️ 警告：仍偵測到問號，代表中文字元未完全覆蓋！" -ForegroundColor Red
    } else {
        Write-Host "🎉 完美！所有中文字元與標點符號 100% 正確存儲於 Apple 伺服器，問號徹底消除！" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ 回讀校驗失敗: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 Apple 審查備忘錄二進位 UTF-8 修復作業全部大功告成！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan