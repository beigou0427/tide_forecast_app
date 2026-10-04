Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🔍 正在向 Apple 官方伺服器調取買斷商品 (Lifetime) 409 錯誤細節..." -ForegroundColor Cyan
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

# 2. 請求建立並捕獲完整 HTTP Error Stream
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

Write-Host "📡 正在調用 POST /v2/inAppPurchases 並攔截伺服器原始回傳..." -ForegroundColor Yellow

try {
    $res = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases" -Headers $headers -Method Post -Body $lifetimeCreateBody
    Write-Host "🎉 成功建立商品！ID: $($res.data.id)" -ForegroundColor Green
} catch {
    Write-Host "❌ 捕獲到 Apple 伺服器狀態碼: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $detailJson = $reader.ReadToEnd()
        Write-Host "`n📋 Apple 伺服器原始診斷報告 (JSON)：" -ForegroundColor Cyan
        Write-Host $detailJson -ForegroundColor Magenta
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan