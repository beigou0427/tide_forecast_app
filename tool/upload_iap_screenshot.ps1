Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在透過指令將審查截圖推送至 Apple 官方儲存庫..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$lifetimeIapId = "6819013375"
$pngPath = ".\tool\iap_lifetime_review_screenshot.png"

if (!(Test-Path $pngPath)) {
    Write-Host "❌ 找不到截圖檔案: $pngPath" -ForegroundColor Red
    exit
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

# 2. 讀取截圖大小並向 Apple 申請預約上傳
$fileBytes = [System.IO.File]::ReadAllBytes($pngPath)
$fileSize = $fileBytes.Length
$fileName = "iap_lifetime_review_screenshot.png"

Write-Host "📡 [步驟 1/3] 正在向 Apple 申請審查截圖預約 (檔案大小: $fileSize bytes)..." -ForegroundColor Yellow

$reserveBody = @"
{
  "data": {
    "type": "inAppPurchaseAppStoreReviewScreenshots",
    "attributes": {
      "fileName": "$fileName",
      "fileSize": $fileSize
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

$reserveRes = $null
try {
    $reserveRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseAppStoreReviewScreenshots" -Headers $headers -Method Post -Body $reserveBody
    Write-Host "  ✅ 預約成功！Apple 資產識別碼: $($reserveRes.data.id)" -ForegroundColor Green
} catch {
    Write-Host "❌ 申請預約失敗: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host $reader.ReadToEnd() -ForegroundColor DarkGray
    }
    Write-Host "`n💡 提示：您也可以在 App Store Connect 網頁端 [終身創始席次] -> [審查資訊] 直接拖曳上傳 $pngPath。" -ForegroundColor Cyan
    exit
}

# 3. 執行二進位資料塊推送 (Upload Operations)
$assetId = $reserveRes.data.id
$uploadOps = $reserveRes.data.attributes.uploadOperations

Write-Host "`n⬆️ [步驟 2/3] 正在推送圖片二進位數據至 Apple 雲端 (分塊數: $($uploadOps.Count))..." -ForegroundColor Yellow

foreach ($op in $uploadOps) {
    $opUrl = $op.url
    $opOffset = $op.offset
    $opLength = $op.length
    $opMethod = $op.method

    $chunk = New-Object byte[] $opLength
    [System.Array]::Copy($fileBytes, $opOffset, $chunk, 0, $opLength)

    $opHeaders = @{}
    foreach ($h in $op.requestHeaders) {
        $opHeaders[$h.name] = $h.value
    }

    try {
        $uploadResult = Invoke-WebRequest -Uri $opUrl -Method $opMethod -Headers $opHeaders -Body $chunk -UseBasicParsing
        Write-Host "  ✅ 區塊上傳完成 (Offset: $opOffset, Length: $opLength)" -ForegroundColor Green
    } catch {
        Write-Host "❌ 區塊上傳失敗: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
}

# 4. 提交 Commit 標記已完成上傳
Write-Host "`n📝 [步驟 3/3] 正在向 Apple 提交完成確認 (Commit Asset)..." -ForegroundColor Yellow

$commitBody = @"
{
  "data": {
    "type": "inAppPurchaseAppStoreReviewScreenshots",
    "id": "$assetId",
    "attributes": {
      "uploaded": true
    }
  }
}
"@

try {
    $commitRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseAppStoreReviewScreenshots/$assetId" -Headers $headers -Method Patch -Body $commitBody
    Write-Host "🎉 恭喜！審查截圖已全自動上傳成功並經 Apple 認證生效！" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Commit 提示: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 全套 Apple Connect 設定指令流程已全部大功告成！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan