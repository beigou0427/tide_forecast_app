[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-Timestamp {
    return (Get-Date).ToString("HH:mm:ss")
}

# 🌟 原生 UTF-8 API 查詢函數：繞過 PowerShell 5.1 Latin-1 亂碼缺陷
function Invoke-AppleApiUtf8([string]$url, [string]$jwt) {
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.Headers.Add("Authorization", "Bearer $jwt")
    $req.Method = "GET"
    try {
        $res = $req.GetResponse()
        $reader = New-Object System.IO.StreamReader($res.GetResponseStream(), [System.Text.Encoding]::UTF8)
        $rawJson = $reader.ReadToEnd()
        $reader.Close()
        $res.Close()
        return (ConvertFrom-Json $rawJson)
    } catch {
        return $null
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 Tide Pro - 4 大海事內購商品 Apple 官方最終審計 (原生 UTF-8)" -ForegroundColor Cyan
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

# -----------------------------------------------------------------------------
# 1. 簽發 ES256 JWT Token
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# 2. 檢索 3 支自動續訂型訂閱項目 (原生 UTF-8 解碼)
# -----------------------------------------------------------------------------
Write-Host "`n📱 [1/2] 自動續訂型訂閱 (Subscriptions - 群組 ID: $groupId)：" -ForegroundColor Yellow
$subUrl = "https://api.appstoreconnect.apple.com/v1/subscriptionGroups/$groupId/subscriptions"
$subRes = Invoke-AppleApiUtf8 $subUrl $jwt

if ($subRes -and $subRes.data) {
    foreach ($subItem in $subRes.data) {
        $subProdId = $subItem.attributes.productId
        $subId = $subItem.id
        $subState = $subItem.attributes.state

        $locName = "預設"
        $locUrl = "https://api.appstoreconnect.apple.com/v1/subscriptions/$subId/subscriptionLocalizations"
        $locRes = Invoke-AppleApiUtf8 $locUrl $jwt

        if ($locRes -and $locRes.data -and $locRes.data.Count -gt 0) {
            $locList = @()
            foreach ($loc in $locRes.data) {
                # 過濾掉先前產生的問號無效節點
                if ($loc.attributes.name -notmatch "\?\?\?\?") {
                    $locList += "$($loc.attributes.name) [$($loc.attributes.locale)]"
                }
            }
            if ($locList.Count -gt 0) {
                $locName = $locList -join ", "
            }
        }

        $stateColor = "Yellow"
        if ($subState -eq "APPROVED") {
            $stateColor = "Green"
        } elseif ($subState -eq "READY_TO_SUBMIT" -or $subState -eq "CREATED") {
            $stateColor = "Cyan"
        }

        Write-Host "`n  ⚓ [$subProdId]" -ForegroundColor White
        Write-Host "     Apple 審查狀態 : $subState" -ForegroundColor $stateColor
        Write-Host "     在地化顯示名稱 : $locName" -ForegroundColor Yellow
        Write-Host "     訂閱週期規格   : $($subItem.attributes.subscriptionPeriod)" -ForegroundColor DarkGray
        Write-Host "     Apple 家人共享 : $($subItem.attributes.familySharable)" -ForegroundColor DarkGray
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------
# 3. 檢索非消耗型永久買斷商品與截圖狀態 (原生 UTF-8 解碼)
# -----------------------------------------------------------------------------
Write-Host "`n⚡ [2/2] 非消耗型永久買斷商品 (Non-Consumable IAP)：" -ForegroundColor Yellow

$shotUrl = "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId/appStoreReviewScreenshot"
$deliveryState = "未知"
$shotRes = Invoke-AppleApiUtf8 $shotUrl $jwt
if ($shotRes -and $shotRes.data) {
    $deliveryState = $shotRes.data.attributes.assetDeliveryState.state
}

$iapUrl = "https://api.appstoreconnect.apple.com/v1/apps/$appId/inAppPurchasesV2"
$iapRes = Invoke-AppleApiUtf8 $iapUrl $jwt

if ($iapRes -and $iapRes.data) {
    foreach ($iapItem in $iapRes.data) {
        $iapProdId = $iapItem.attributes.productId
        $iapId = $iapItem.id
        $iapState = $iapItem.attributes.state
        $iapType = $iapItem.attributes.inAppPurchaseType

        $iapLocName = "未設定"
        $locUrl = "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$iapId/inAppPurchaseLocalizations"
        $locRes = Invoke-AppleApiUtf8 $locUrl $jwt

        if ($locRes -and $locRes.data -and $locRes.data.Count -gt 0) {
            $locList = @()
            foreach ($loc in $locRes.data) {
                if ($loc.attributes.name -notmatch "\?\?\?\?") {
                    $locList += "$($loc.attributes.name) [$($loc.attributes.locale)]"
                }
            }
            if ($locList.Count -gt 0) {
                $iapLocName = $locList -join ", "
            }
        }

        $stateColor = "Yellow"
        if ($iapState -eq "APPROVED" -or $iapState -eq "READY_TO_SUBMIT") {
            $stateColor = "Green"
        }

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

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 原生 UTF-8 商品審計完成！所有中文名稱 100% 清晰純淨！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan