Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 正在向 Apple 官方伺服器設定繁體中文 (zh-Hant) 在地化資料..." -ForegroundColor Cyan
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

# 2. 為 3 支訂閱項目建立或更新 zh-Hant 本地化
Write-Host "📝 [步驟 1/2] 正在為訂閱項目建立/更新繁體中文 (zh-Hant) 顯示名稱與說明..." -ForegroundColor Yellow

$subConfigs = @{
    "com.beigou.tide_app.pro_weekly" = @{
        Name = "週費體驗版"
        Desc = "解鎖全台 85 測站光纖直連、全站離線預載與滿潮防困礁警報"
    }
    "com.beigou.tide_app.pro_monthly" = @{
        Name = "月度專業版"
        Desc = "解鎖全台 85 測站光纖直連、全站離線預載與滿潮防困礁警報"
    }
    "com.beigou.tide_app.pro_yearly" = @{
        Name = "年度指揮官計畫"
        Desc = "主力推薦 · 支援 Apple 家人共享 · 85 測站光纖直連與離線神盾"
    }
}

try {
    $subRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptionGroups/$groupId/subscriptions?include=subscriptionLocalizations" -Headers $headers -Method Get
    $subs = $subRes.data
    $locs = $subRes.included

    foreach ($subItem in $subs) {
        $subProductId = $subItem.attributes.productId
        $subId = $subItem.id

        if ($subConfigs.ContainsKey($subProductId)) {
            $targetName = $subConfigs[$subProductId].Name
            $targetDesc = $subConfigs[$subProductId].Desc

            # 檢查既有 zh-Hant 本地化 ID
            $existingLoc = $null
            if ($null -ne $locs) {
                $existingLoc = $locs | Where-Object { 
                    $_.type -eq "subscriptionLocalizations" -and 
                    $_.relationships.subscription.data.id -eq $subId -and 
                    $_.attributes.locale -eq "zh-Hant" 
                }
            }

            if ($null -ne $existingLoc) {
                # 更新既有本地化
                $locId = $existingLoc.id
                $patchBody = @"
{
  "data": {
    "type": "subscriptionLocalizations",
    "id": "$locId",
    "attributes": {
      "name": "$targetName",
      "description": "$targetDesc"
    }
  }
}
"@
                try {
                    $patchRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptionLocalizations/$locId" -Headers $headers -Method Patch -Body $patchBody
                    Write-Host "  ✅ 繁體中文已更新: $targetName ($subProductId)" -ForegroundColor Green
                } catch {
                    Write-Host "  ℹ️ 繁體中文維持設定: $targetName ($subProductId)" -ForegroundColor Cyan
                }
            } else {
                # 建立全新本地化
                $createBody = @"
{
  "data": {
    "type": "subscriptionLocalizations",
    "attributes": {
      "name": "$targetName",
      "description": "$targetDesc",
      "locale": "zh-Hant"
    },
    "relationships": {
      "subscription": {
        "data": {
          "type": "subscriptions",
          "id": "$subId"
        }
      }
    }
  }
}
"@
                try {
                    $postRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptionLocalizations" -Headers $headers -Method Post -Body $createBody
                    Write-Host "  🎉 成功建立繁體中文: $targetName ($subProductId)" -ForegroundColor Green
                } catch {
                    Write-Host "  ⚠️ 建立提示 ($subProductId): $($_.Exception.Message)" -ForegroundColor DarkGray
                    if ($_.ErrorDetails.Message) { Write-Host "     詳情: $($_.ErrorDetails.Message)" -ForegroundColor DarkGray }
                }
            }
        }
    }
} catch {
    Write-Host "❌ 訂閱查詢失敗: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. 排查買斷型項目 (com.beigou.tide_app.pro_lifetime)
Write-Host "`n🔍 [步驟 2/2] 正在嘗試建立或診斷買斷型項目 (com.beigou.tide_app.pro_lifetime)..." -ForegroundColor Yellow

$lifetimeCreateBody = @"
{
  "data": {
    "type": "inAppPurchases",
    "attributes": {
      "name": "終身創始席次",
      "productId": "com.beigou.tide_app.pro_lifetime",
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
    $lifetimeRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases" -Headers $headers -Method Post -Body $lifetimeCreateBody
    Write-Host "  🎉 成功在 Apple 後台建立非消耗型買斷商品: 終身創始席次 [ID: $($lifetimeRes.data.id)]" -ForegroundColor Green
} catch {
    Write-Host "  Apple 伺服器回傳狀態: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.ErrorDetails.Message) {
        Write-Host "  Apple 原始回傳詳情: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 作業執行完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan