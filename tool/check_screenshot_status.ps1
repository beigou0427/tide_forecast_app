[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🔍 正在向 Apple 官方伺服器調取審查截圖處理進度與缺少項目..." -ForegroundColor Cyan
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
    "Content-Type"  = "application/json"
}

# 2. 查詢審查截圖資產處理狀態
Write-Host "📡 [1/2] 正在向 Apple 查詢審查截圖資產處理狀態..." -ForegroundColor Yellow

$shotUrl = "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId/appStoreReviewScreenshot"

try {
    $shotRes = Invoke-RestMethod -Uri $shotUrl -Headers $headers -Method Get
    if ($shotRes.data) {
        $asset = $shotRes.data
        $deliveryState = $asset.attributes.assetDeliveryState.state
        $color = if ($deliveryState -eq "COMPLETE") { "Green" } else { "Yellow" }
        Write-Host "  ✅ 找到審查截圖資產 (ID: $($asset.id))" -ForegroundColor Green
        Write-Host "     檔名規格      : $($asset.attributes.fileName) ($($asset.attributes.fileSize) bytes)" -ForegroundColor White
        Write-Host "     Apple 處理狀態: $deliveryState" -ForegroundColor $color
        if ($asset.attributes.assetDeliveryState.errors) {
            Write-Host "     ⚠️ 處理錯誤: $($asset.attributes.assetDeliveryState.errors | ConvertTo-Json)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠️ 尚未綁定截圖資產。" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️ 截圖查詢提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 3. 補齊審查備忘錄 (Review Notes)
Write-Host "`n📝 [2/2] 正在向 Apple 補齊審查備忘錄 (Review Note)..." -ForegroundColor Yellow

$patchBody = @"
{
  "data": {
    "type": "inAppPurchases",
    "id": "$lifetimeIapId",
    "attributes": {
      "reviewNote": "提供老船長 VIP 終身買斷功能，可於 App 首頁右上角或設定頁面中點擊付費牆按鈕進行購買。"
    }
  }
}
"@

try {
    $patchRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId" -Headers $headers -Method Patch -Body $patchBody
    Write-Host "  ✅ 成功寫入 Apple 官方審查備忘錄 (Review Note)！" -ForegroundColor Green
    Write-Host "     最新審查狀態: $($patchRes.data.attributes.state)" -ForegroundColor Cyan
} catch {
    Write-Host "  ⚠️ 備忘錄設定提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 診斷完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan