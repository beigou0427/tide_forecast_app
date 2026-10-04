[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 正在向 Apple 官方伺服器提交供貨區域許可 (Cleared for Sale)..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$lifetimeIapId = "6819013375"

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

# 2. 提交 inAppPurchaseAvailabilities (開通台灣 TWN 供貨許可)
Write-Host "📡 正在提交台灣 (TWN) 供貨許可 (inAppPurchaseAvailabilities)..." -ForegroundColor Yellow

$availBody = @"
{
  "data": {
    "type": "inAppPurchaseAvailabilities",
    "attributes": {
      "availableInNewTerritories": true
    },
    "relationships": {
      "inAppPurchase": {
        "data": {
          "type": "inAppPurchases",
          "id": "$lifetimeIapId"
        }
      },
      "availableTerritories": {
        "data": [
          {
            "type": "territories",
            "id": "TWN"
          }
        ]
      }
    }
  }
}
"@

$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($availBody)

try {
    $res = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseAvailabilities" -Headers $headers -Method Post -Body $utf8Bytes
    Write-Host "🎉 成功開通供貨許可！(Availability ID: $($res.data.id))" -ForegroundColor Green
} catch {
    Write-Host "  Apple 伺服器狀態: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host $reader.ReadToEnd() -ForegroundColor DarkGray
    }
}

# 3. 重新查詢買斷商品最新狀態
Write-Host "`n🔍 正在向 Apple 重新檢索買斷商品最新狀態..." -ForegroundColor Yellow
try {
    $latestRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId" -Headers $headers -Method Get
    $finalState = $latestRes.data.attributes.state
    $color = if ($finalState -eq "READY_TO_SUBMIT" -or $finalState -eq "APPROVED") { "Green" } else { "Yellow" }
    Write-Host "  🎉 Apple 官方最新審查狀態: $finalState" -ForegroundColor $color
} catch {}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 供貨許可指令執行完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan