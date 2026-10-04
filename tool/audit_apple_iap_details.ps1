Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 正在向 Apple 官方伺服器深度審計 4 大商品就緒度..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"
$groupId = "22005909"

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

# 2. 深度查詢 3 支訂閱項目
Write-Host "📡 正在檢驗訂閱項目 (Subscriptions) 狀態..." -ForegroundColor Yellow
$subUrl = "https://api.appstoreconnect.apple.com/v1/subscriptionGroups/$groupId/subscriptions?include=subscriptionLocalizations"

try {
    $subRes = Invoke-RestMethod -Uri $subUrl -Headers $headers -Method Get
    $subs = $subRes.data
    $locs = $subRes.included

    foreach ($s in $subs) {
        $itemProductId = $s.attributes.productId
        $state = $s.attributes.state
        $itemSubId = $s.id
        
        $localName = "未設定"
        if ($null -ne $locs) {
            $matchedLoc = $locs | Where-Object { $_.type -eq "subscriptionLocalizations" -and $_.relationships.subscription.data.id -eq $itemSubId }
            if ($matchedLoc) {
                $localName = "$($matchedLoc.attributes.name) ($($matchedLoc.attributes.locale))"
            }
        }
        
        $stateColor = if ($state -eq "READY_TO_SUBMIT" -or $state -eq "APPROVED") { "Green" } else { "Yellow" }
        Write-Host "  • 商品 ID : $itemProductId" -ForegroundColor Cyan
        Write-Host "    Apple 審查狀態: $state" -ForegroundColor $stateColor
        Write-Host "    中文顯示名稱  : $localName" -ForegroundColor White
        Write-Host "    訂閱週期      : $($s.attributes.subscriptionPeriod)" -ForegroundColor DarkGray
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "❌ 查詢訂閱失敗: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 深度查詢 1 支終身買斷非消耗型商品 (切換至官方標準端點)
Write-Host "`n📡 正在檢驗買斷項目 (Non-Consumable IAP) 狀態..." -ForegroundColor Yellow
$iapUrl = "https://api.appstoreconnect.apple.com/v1/apps/$appId/inAppPurchasesV2?include=inAppPurchaseLocalizations"

try {
    $iapRes = Invoke-RestMethod -Uri $iapUrl -Headers $headers -Method Get
    $iaps = $iapRes.data
    $iapLocs = $iapRes.included

    foreach ($iap in $iaps) {
        $itemProductId = $iap.attributes.productId
        $state = $iap.attributes.state
        $itemIapId = $iap.id

        $localName = "未設定"
        if ($null -ne $iapLocs) {
            $matchedLoc = $iapLocs | Where-Object { $_.type -eq "inAppPurchaseLocalizations" -and $_.relationships.inAppPurchaseV2.data.id -eq $itemIapId }
            if ($matchedLoc) {
                $localName = "$($matchedLoc.attributes.name) ($($matchedLoc.attributes.locale))"
            }
        }

        $stateColor = if ($state -eq "READY_TO_SUBMIT" -or $state -eq "APPROVED") { "Green" } else { "Yellow" }
        Write-Host "  • 商品 ID : $itemProductId" -ForegroundColor Cyan
        Write-Host "    Apple 審查狀態: $state" -ForegroundColor $stateColor
        Write-Host "    中文顯示名稱  : $localName" -ForegroundColor White
        Write-Host "    項目型態      : $($iap.attributes.inAppPurchaseType)" -ForegroundColor DarkGray
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "❌ 查詢買斷失敗: $($_.Exception.Message)" -ForegroundColor Red
}