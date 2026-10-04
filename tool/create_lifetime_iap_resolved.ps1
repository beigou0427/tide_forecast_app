Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "⚡ 正在向 Apple 官方伺服器建立買斷商品 (Lifetime) 並配置中文..." -ForegroundColor Cyan
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

# 2. 建立非消耗型買斷商品 (使用唯一的內部參考名稱 Tide Pro Lifetime Access)
$lifetimeId = "com.beigou.tide_app.pro_lifetime"
$internalRefName = "Tide Pro Lifetime Access"

$createIapBody = @"
{
  "data": {
    "type": "inAppPurchases",
    "attributes": {
      "name": "$internalRefName",
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

Write-Host "📡 [步驟 1/2] 正在建立非消耗型商品本體..." -ForegroundColor Yellow

$newIapId = $null
try {
    $res = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases" -Headers $headers -Method Post -Body $createIapBody
    $newIapId = $res.data.id
    Write-Host "🎉 成功建立買斷商品！Apple 實體 ID: $newIapId" -ForegroundColor Green
} catch {
    Write-Host "❌ 建立本體異常: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host $reader.ReadToEnd() -ForegroundColor Red
    }
}

# 3. 綁定繁體中文 (zh-Hant) 對外展示名稱與說明
if ($null -ne $newIapId) {
    Write-Host "`n📝 [步驟 2/2] 正在為買斷商品設定繁體中文 (zh-Hant) 顯示名稱..." -ForegroundColor Yellow
    $locBody = @"
{
  "data": {
    "type": "inAppPurchaseLocalizations",
    "attributes": {
      "name": "終身創始席次",
      "description": "永久享有全台 85 測站光纖直連、全站離線預載與老船長 AI 推論",
      "locale": "zh-Hant"
    },
    "relationships": {
      "inAppPurchaseV2": {
        "data": {
          "type": "inAppPurchases",
          "id": "$newIapId"
        }
      }
    }
  }
}
"@
    try {
        $locRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseLocalizations" -Headers $headers -Method Post -Body $locBody
        Write-Host "🎉 成功建立買斷商品繁體中文在地化！" -ForegroundColor Green
        Write-Host "  顯示名稱 : 終身創始席次" -ForegroundColor Cyan
        Write-Host "  商品 ID  : $lifetimeId" -ForegroundColor Cyan
    } catch {
        Write-Host "⚠️ 本地化設定提示: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            Write-Host $reader.ReadToEnd() -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 買斷商品終極建立流程完成！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan