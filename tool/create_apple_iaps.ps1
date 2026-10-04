Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍎 正在透過 REST API 自動建立 Apple 官方 4 大海事商品..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"

if (Test-Path ".\tool\target_app_id.txt") {
    $cachedId = (Get-Content ".\tool\target_app_id.txt").Trim()
    if ($cachedId) { $appId = $cachedId }
}

# 1. 載入金鑰並簽發 ES256 JWT Token
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

# 2. 確保「訂閱群組 (Subscription Group)」存在
Write-Host "📦 [步驟 1/3] 檢查或建立訂閱群組 (Tide Pro Subscriptions)..." -ForegroundColor Yellow
$groupId = $null

try {
    $existingGroups = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/apps/$appId/subscriptionGroups" -Headers $headers -Method Get
    if ($null -ne $existingGroups.data -and $existingGroups.data.Count -gt 0) {
        $groupId = $existingGroups.data[0].id
        Write-Host "  ✅ 找到既有訂閱群組: $($existingGroups.data[0].attributes.referenceName) (ID: $groupId)" -ForegroundColor Green
    }
} catch {}

if ($null -eq $groupId) {
    $createGroupBody = @"
{
  "data": {
    "type": "subscriptionGroups",
    "attributes": {
      "referenceName": "Tide Pro Subscriptions"
    },
    "relationships": {
      "app": {
        "data": {
          "type": "apps",
          "id": "$appId"
        }
      }
    }
  }
}
"@
    try {
        $groupRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptionGroups" -Headers $headers -Method Post -Body $createGroupBody
        $groupId = $groupRes.data.id
        Write-Host "  🎉 成功建立新訂閱群組: Tide Pro Subscriptions (ID: $groupId)" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ 建立訂閱群組失敗: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) { Write-Host "  詳情: $($_.ErrorDetails.Message)" -ForegroundColor Red }
    }
}

# 3. 建立 3 支自動續訂型商品 (Subscriptions)
Write-Host "`n📱 [步驟 2/3] 正在建立 3 支自動續訂型商品..." -ForegroundColor Yellow

$subList = @(
    @{
        Id = "com.beigou.tide_app.pro_weekly"
        Name = "週費體驗版"
        Period = "ONE_WEEK"
        Family = "false"
        Level = 3
    },
    @{
        Id = "com.beigou.tide_app.pro_monthly"
        Name = "月度專業版"
        Period = "ONE_MONTH"
        Family = "false"
        Level = 2
    },
    @{
        Id = "com.beigou.tide_app.pro_yearly"
        Name = "年度指揮官計畫"
        Period = "ONE_YEAR"
        Family = "true"
        Level = 1
    }
)

if ($null -ne $groupId) {
    foreach ($item in $subList) {
        $productId = $item.Id
        $productName = $item.Name
        $period = $item.Period
        $family = $item.Family
        $level = $item.Level

        $createSubBody = @"
{
  "data": {
    "type": "subscriptions",
    "attributes": {
      "name": "$productName",
      "productId": "$productId",
      "subscriptionPeriod": "$period",
      "familySharable": $family,
      "groupLevel": $level
    },
    "relationships": {
      "group": {
        "data": {
          "type": "subscriptionGroups",
          "id": "$groupId"
        }
      }
    }
  }
}
"@
        try {
            $subRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptions" -Headers $headers -Method Post -Body $createSubBody
            Write-Host "  ✅ 成功建立訂閱商品: $productName ($productId) [Apple ID: $($subRes.data.id)]" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -match "409" -or ($_.ErrorDetails.Message -and $_.ErrorDetails.Message -match "already exists")) {
                Write-Host "  ℹ️ 訂閱商品已存在: $productName ($productId)" -ForegroundColor Cyan
            } else {
                Write-Host "  ❌ 建立訂閱失敗 ($productId): $($_.Exception.Message)" -ForegroundColor Red
                if ($_.ErrorDetails.Message) { Write-Host "  詳情: $($_.ErrorDetails.Message)" -ForegroundColor Red }
            }
        }
    }
} else {
    Write-Host "  ⚠️ 未取得訂閱群組 ID，跳過建立訂閱。" -ForegroundColor Yellow
}

# 4. 建立 1 支永久買斷非消耗型商品 (Non-Consumable IAP)
Write-Host "`n⚡ [步驟 3/3] 正在建立非消耗型買斷商品 (終身創始席次)..." -ForegroundColor Yellow

$lifetimeId = "com.beigou.tide_app.pro_lifetime"
$lifetimeName = "終身創始席次"

$createIapBody = @"
{
  "data": {
    "type": "inAppPurchases",
    "attributes": {
      "name": "$lifetimeName",
      "productId": "$lifetimeId",
      "inAppPurchaseType": "NON_CONSUMABLE"
    },
    "relationships": {
      "app": {
        "data": {
          "type": "apps",
          "id": "$appId"
        }
      }
    }
  }
}
"@

try {
    $iapRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases" -Headers $headers -Method Post -Body $createIapBody
    Write-Host "  ✅ 成功建立非消耗型買斷商品: $lifetimeName ($lifetimeId) [Apple ID: $($iapRes.data.id)]" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -match "409" -or ($_.ErrorDetails.Message -and $_.ErrorDetails.Message -match "already exists")) {
        Write-Host "  ℹ️ 買斷商品已存在: $lifetimeName ($lifetimeId)" -ForegroundColor Cyan
    } else {
        Write-Host "  ❌ 建立買斷商品失敗: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) { Write-Host "  詳情: $($_.ErrorDetails.Message)" -ForegroundColor Red }
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 Apple 官方伺服器內購建立作業已執行完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan