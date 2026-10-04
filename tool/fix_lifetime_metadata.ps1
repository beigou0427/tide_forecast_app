[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 正在以 UTF-8 精確修復買斷商品名稱並對齊 Apple 主語言..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"
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
    "Content-Type"  = "application/json; charset=utf-8"
}

# 2. 查詢 App 的 Primary Locale
Write-Host "📡 [步驟 1/3] 正在向 Apple 查詢 App 主語言 (Primary Locale)..." -ForegroundColor Yellow
$primaryLocale = "zh-Hant"

try {
    $appRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/apps/$appId" -Headers $headers -Method Get
    if ($appRes.data.attributes.primaryLocale) {
        $primaryLocale = $appRes.data.attributes.primaryLocale
        Write-Host "  ✅ 鎖定 App 官方主語言: $primaryLocale" -ForegroundColor Green
    }
} catch {
    Write-Host "  ℹ️ 預設採用 zh-Hant" -ForegroundColor DarkGray
}

# 3. 查詢目前既有的 localizations
$existingLocsUrl = "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId/inAppPurchaseLocalizations"
$existingLocMap = @{}

try {
    $locsRes = Invoke-RestMethod -Uri $existingLocsUrl -Headers $headers -Method Get
    if ($locsRes.data) {
        foreach ($loc in $locsRes.data) {
            $existingLocMap[$loc.attributes.locale] = $loc.id
        }
    }
} catch {}

# 4. 以 UTF-8 二進位精準更新/建立繁體中文 (zh-Hant)
Write-Host "`n📝 [步驟 2/3] 正在以純淨 UTF-8 寫入繁體中文 (zh-Hant) 名稱..." -ForegroundColor Yellow

$zhName = "終身創始席次"
$zhDesc = "永久享有全台 85 測站光纖直連、全站離線預載與老船長 AI 水文推論"

if ($existingLocMap.ContainsKey("zh-Hant")) {
    $locId = $existingLocMap["zh-Hant"]
    $patchBody = @"
{
  "data": {
    "type": "inAppPurchaseLocalizations",
    "id": "$locId",
    "attributes": {
      "name": "$zhName",
      "description": "$zhDesc"
    }
  }
}
"@
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($patchBody)
    try {
        Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseLocalizations/$locId" -Headers $headers -Method Patch -Body $utf8Bytes | Out-Null
        Write-Host "  ✅ 繁體中文名稱已修復為: $zhName" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ 更新繁中提示: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    $createBody = @"
{
  "data": {
    "type": "inAppPurchaseLocalizations",
    "attributes": {
      "name": "$zhName",
      "description": "$zhDesc",
      "locale": "zh-Hant"
    },
    "relationships": {
      "inAppPurchaseV2": {
        "data": {
          "type": "inAppPurchases",
          "id": "$lifetimeIapId"
        }
      }
    }
  }
}
"@
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($createBody)
    try {
        Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseLocalizations" -Headers $headers -Method Post -Body $utf8Bytes | Out-Null
        Write-Host "  ✅ 成功建立繁體中文: $zhName" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ 建立繁中提示: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 5. 確保英文 (en-US) 本地化也存在 (滿足多數 App 主語言要求)
Write-Host "`n📝 [步驟 3/3] 正在確保英文 (en-US) 本地化完整對齊..." -ForegroundColor Yellow

$enName = "Lifetime Founder Access"
$enDesc = "Lifetime access to 85 station fiber-optic direct lines, offline hydro data, and AI tide briefings."

if ($existingLocMap.ContainsKey("en-US")) {
    Write-Host "  ℹ️ 英文 (en-US) 已存在，維持設定。" -ForegroundColor Cyan
} else {
    $createEnBody = @"
{
  "data": {
    "type": "inAppPurchaseLocalizations",
    "attributes": {
      "name": "$enName",
      "description": "$enDesc",
      "locale": "en-US"
    },
    "relationships": {
      "inAppPurchaseV2": {
        "data": {
          "type": "inAppPurchases",
          "id": "$lifetimeIapId"
        }
      }
    }
  }
}
"@
    $utf8EnBytes = [System.Text.Encoding]::UTF8.GetBytes($createEnBody)
    try {
        Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseLocalizations" -Headers $headers -Method Post -Body $utf8EnBytes | Out-Null
        Write-Host "  ✅ 成功補齊英文主語言: $enName" -ForegroundColor Green
    } catch {
        Write-Host "  ℹ️ 英文設定提示: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# 6. 最終驗證狀態
Write-Host "`n🔍 正在向 Apple 重新檢索買斷商品最新狀態..." -ForegroundColor Yellow
try {
    $latestRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId" -Headers $headers -Method Get
    $finalState = $latestRes.data.attributes.state
    $finalColor = if ($finalState -eq "READY_TO_SUBMIT" -or $finalState -eq "APPROVED") { "Green" } else { "Yellow" }
    Write-Host "  🎉 Apple 官方最新審查狀態: $finalState" -ForegroundColor $finalColor
} catch {}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 修復作業執行完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan