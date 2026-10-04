[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在建立 Apple 官方 640 x 920 (無 Alpha 通道) 審查截圖並上傳..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$lifetimeIapId = "6819013375"
$cleanPngPath = ".\tool\iap_review_640x920.png"

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

# 2. 清理先前失敗的舊資產 (DELETE)
Write-Host "🧹 [步驟 1/4] 檢查並清理失敗的舊資產..." -ForegroundColor Yellow
$shotUrl = "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId/appStoreReviewScreenshot"

try {
    $existing = Invoke-RestMethod -Uri $shotUrl -Headers $headers -Method Get
    if ($existing.data) {
        $oldId = $existing.data.id
        Write-Host "  正在刪除舊資產: $oldId" -ForegroundColor DarkGray
        Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseAppStoreReviewScreenshots/$oldId" -Headers $headers -Method Delete | Out-Null
        Write-Host "  ✅ 舊資產清理完成。" -ForegroundColor Green
    }
} catch {
    Write-Host "  ℹ️ 無需清理舊資產。" -ForegroundColor DarkGray
}

# 3. 繪製 640 x 920 純 24-bit RGB (Format24bppRgb, 零透明通道)
Write-Host "`n🎨 [步驟 2/4] 正在繪製 Apple 官方標準 640 x 920 (24bpp RGB, 零 Alpha 通道) 截圖..." -ForegroundColor Yellow

Add-Type -AssemblyName System.Drawing

$width = 640
$height = 920
$pixelFormat = [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
$bitmap = New-Object System.Drawing.Bitmap($width, $height, $pixelFormat)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# 背景 (純色填滿)
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(2, 27, 51))
$graphics.FillRectangle($bgBrush, 0, 0, $width, $height)

# 字體與筆刷
$titleFont = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Regular)
$priceFont = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Bold)
$btnFont = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)

$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(234, 179, 8))
$cyanBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 180, 216))
$grayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(148, 163, 184))

$centerFormat = New-Object System.Drawing.StringFormat
$centerFormat.Alignment = [System.Drawing.StringAlignment]::Center

# 繪製內容
$graphics.DrawString("TIDE PRO 潮汐表", $subFont, $cyanBrush, 320, 60, $centerFormat)
$graphics.DrawString("老船長 AI 專業旗艦版", $titleFont, $whiteBrush, 320, 100, $centerFormat)
$graphics.DrawString("全台 85 測站光纖直連 · 外礁防困礁警報", $subFont, $grayBrush, 320, 145, $centerFormat)

# 買斷方案卡
$cardRect = New-Object System.Drawing.Rectangle(50, 190, 540, 250)
$cardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 35, 60))
$cardPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(234, 179, 8), 3)
$graphics.FillRectangle($cardBrush, $cardRect)
$graphics.DrawRectangle($cardPen, $cardRect)

$graphics.DrawString("👑 終身創始席次 (Non-Consumable)", $titleFont, $goldBrush, 320, 215, $centerFormat)
$graphics.DrawString("限量席次 · 終身享有後續所有 AI 算力與全島水文更新", $subFont, $grayBrush, 320, 260, $centerFormat)
$graphics.DrawString("NT$ 2,990", $priceFont, $whiteBrush, 320, 310, $centerFormat)
$graphics.DrawString("一次性付費 · 永久擁有最高權限", $subFont, $cyanBrush, 320, 380, $centerFormat)

# 特色清單
$featureFont = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Regular)
$leftFormat = New-Object System.Drawing.StringFormat
$leftFormat.Alignment = [System.Drawing.StringAlignment]::Near

$y = 480
$features = @(
    "⚓ 中央氣象署 85 測站光纖直連專線 (0 延遲刷新)",
    "📦 全台 85 測站一鍵離線神盾預載包 (外海斷網無縫切換)",
    "🚨 滿潮前 30 分鐘主動突發長湧瘋狗浪防困礁警報",
    "🐟 四大標竿魚種海溫躍層 ΔT 與氣壓走水推演",
    "🌌 30 天時間序列水文金庫與歷史天文調和回測",
    "☁️ 無限張數雲端高畫質漁獲相簿永久備份"
)

foreach ($f in $features) {
    $graphics.DrawString($f, $featureFont, $whiteBrush, 70, $y, $leftFormat)
    $y += 45
}

# 購買按鈕
$btnRect = New-Object System.Drawing.Rectangle(50, 780, 540, 70)
$btnBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(234, 179, 8))
$graphics.FillRectangle($btnBrush, $btnRect)
$btnTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(2, 27, 51))
$graphics.DrawString("取得終身創始席次 (NT$ 2,990)", $btnFont, $btnTextBrush, 320, 800, $centerFormat)

$bitmap.Save($cleanPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

$fileBytes = [System.IO.File]::ReadAllBytes($cleanPngPath)
$fileSize = $fileBytes.Length
Write-Host "  ✅ 成功產出 640 x 920 零透明通道截圖 ($fileSize bytes)" -ForegroundColor Green

# 4. 申請上傳預約 (POST)
Write-Host "`n📡 [步驟 3/4] 正在向 Apple 申請新截圖預約..." -ForegroundColor Yellow
$fileName = "iap_review_640x920.png"
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

$reserveRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseAppStoreReviewScreenshots" -Headers $headers -Method Post -Body $reserveBody
$assetId = $reserveRes.data.id
$uploadOps = $reserveRes.data.attributes.uploadOperations
Write-Host "  ✅ 預約核准！新資產 ID: $assetId" -ForegroundColor Green

# 5. 二進位分塊推送與 Commit
Write-Host "`n⬆️ [步驟 4/4] 正在推送二進位資料並提交 Commit..." -ForegroundColor Yellow

foreach ($op in $uploadOps) {
    $chunk = New-Object byte[] $op.length
    [System.Array]::Copy($fileBytes, $op.offset, $chunk, 0, $op.length)

    $opHeaders = @{}
    foreach ($h in $op.requestHeaders) { $opHeaders[$h.name] = $h.value }
    Invoke-WebRequest -Uri $op.url -Method $op.method -Headers $opHeaders -Body $chunk -UseBasicParsing | Out-Null
    Write-Host "  ✅ 區塊傳輸完成" -ForegroundColor Green
}

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
Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchaseAppStoreReviewScreenshots/$assetId" -Headers $headers -Method Patch -Body $commitBody | Out-Null
Write-Host "🎉 恭喜！640 x 920 標準截圖已提交 Apple 官方伺服器生效！" -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 作業完成！請稍候 30 秒後執行 check_screenshot_status 檢視狀態！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan