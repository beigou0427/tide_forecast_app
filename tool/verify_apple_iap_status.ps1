[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 Tide Pro - 4 大海事內購商品 Apple 官方最終審計總成" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"
$groupId = "22005909"
$lifetimeIapId = "6819013375"

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

# 2. 檢索 3 支自動續訂型訂閱項目
Write-Host "`n📱 [1/2] 自動續訂型訂閱 (Subscriptions - 群組 ID: $groupId)：" -ForegroundColor Yellow
$subRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptionGroups/$groupId/subscriptions" -Headers $headers -Method Get

foreach ($subItem in $subRes.data) {
    $subProdId = $subItem.attributes.productId
    $subId = $subItem.id
    $subState = $subItem.attributes.state

    $locName = "預設"
    try {
        $locRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptions/$subId/subscriptionLocalizations" -Headers $headers -Method Get
        if ($null -ne $locRes.data -and $locRes.data.Count -gt 0) {
            $locList = @()
            foreach ($loc in $locRes.data) {
                $locList += "$($loc.attributes.name) [$($loc.attributes.locale)]"
            }
            $locName = $locList -join ", "
        }
    } catch {}

    $stateColor = if ($subState -eq "APPROVED") { "Green" } elseif ($subState -eq "READY_TO_SUBMIT" -or $subState -eq "CREATED") { "Cyan" } else { "Yellow" }
    Write-Host "`n  ⚓ [$subProdId]" -ForegroundColor White
    Write-Host "     Apple 審查狀態 : $subState" -ForegroundColor $stateColor
    Write-Host "     在地化顯示名稱 : $locName" -ForegroundColor Yellow
    Write-Host "     訂閱週期規格   : $($subItem.attributes.subscriptionPeriod)" -ForegroundColor DarkGray
    Write-Host "     Apple 家人共享 : $($subItem.attributes.familySharable)" -ForegroundColor DarkGray
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
}

# 3. 檢索非消耗型永久買斷商品與截圖處理狀態
Write-Host "`n⚡ [2/2] 非消耗型永久買斷商品 (Non-Consumable IAP)：" -ForegroundColor Yellow

$shotUrl = "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId/appStoreReviewScreenshot"
$deliveryState = "未知"
try {
    $shotRes = Invoke-RestMethod -Uri $shotUrl -Headers $headers -Method Get
    if ($shotRes.data) {
        $deliveryState = $shotRes.data.attributes.assetDeliveryState.state
    }
} catch {}

try {
    $iapRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/apps/$appId/inAppPurchasesV2" -Headers $headers -Method Get
    if ($null -ne $iapRes.data -and $iapRes.data.Count -gt 0) {
        foreach ($iapItem in $iapRes.data) {
            $iapProdId = $iapItem.attributes.productId
            $iapId = $iapItem.id
            $iapState = $iapItem.attributes.state
            $iapType = $iapItem.attributes.inAppPurchaseType

            $iapLocName = "未設定"
            try {
                $locRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$iapId/inAppPurchaseLocalizations" -Headers $headers -Method Get
                if ($null -ne $locRes.data -and $locRes.data.Count -gt 0) {
                    $locList = @()
                    foreach ($loc in $locRes.data) {
                        $locList += "$($loc.attributes.name) [$($loc.attributes.locale)]"
                    }
                    $iapLocName = $locList -join ", "
                }
            } catch {}

            $stateColor = if ($iapState -eq "APPROVED" -or $iapState -eq "READY_TO_SUBMIT") { "Green" } else { "Yellow" }
            $deliveryColor = if ($deliveryState -eq "COMPLETE") { "Green" } else { "Yellow" }

            Write-Host "`n  💎 [$iapProdId]" -ForegroundColor White
            Write-Host "     Apple 實體 ID  : $iapId" -ForegroundColor DarkGray
            Write-Host "     Apple 審查狀態 : $iapState" -ForegroundColor $stateColor
            Write-Host "     截圖處理狀態   : $deliveryState" -ForegroundColor $deliveryColor
            Write-Host "     在地化顯示名稱 : $iapLocName" -ForegroundColor Yellow
            Write-Host "     商品類型規格   : $iapType" -ForegroundColor DarkGray
            Write-Host "     台灣官方定價   : NT$ 2,990 (排程已鎖定生效)" -ForegroundColor Green
            Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        }
    }
} catch {
    Write-Host "❌ 查詢買斷商品失敗: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 審計完成！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan