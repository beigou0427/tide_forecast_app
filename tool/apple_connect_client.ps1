Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 Tide Pro - 正在連線 Apple 官方 App Store Connect API..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$bundleId = "com.beigou.tideForecastApp"

if (!(Test-Path $p8Path)) {
    Write-Host "❌ 找不到私鑰檔案: $p8Path" -ForegroundColor Red
    exit
}

# 1. 讀取並以 Windows CNG 載入 PKCS#8 私鑰
$rawKey = (Get-Content $p8Path | Where-Object { $_ -notmatch '^-' }) -join ''
$keyBytes = [System.Convert]::FromBase64String($rawKey)

try {
    $cngKey = [System.Security.Cryptography.CngKey]::Import($keyBytes, [System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
    $dsa = New-Object System.Security.Cryptography.ECDsaCng($cngKey)
} catch {
    Write-Host "❌ 載入私鑰失敗: $_" -ForegroundColor Red
    exit
}

# 2. 構造 ES256 JWT Token (有效期限 20 分鐘)
function Base64UrlEncode([byte[]]$bytes) {
    [System.Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

$headerJson = "{`"alg`":`"ES256`",`"kid`":`"$keyId`",`"typ`":`"JWT`"}"
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$exp = $now + 1200
$payloadJson = "{`"iss`":`"$issuerId`",`"iat`":$now,`"exp`":$exp,`"aud`":`"appstoreconnect-v1`"}"

$headerB64 = Base64UrlEncode([System.Text.Encoding]::UTF8.GetBytes($headerJson))
$payloadB64 = Base64UrlEncode([System.Text.Encoding]::UTF8.GetBytes($payloadJson))
$unsignedToken = "$headerB64.$payloadB64"

$sigBytes = $dsa.SignData([System.Text.Encoding]::UTF8.GetBytes($unsignedToken))
$sigB64 = Base64UrlEncode($sigBytes)
$jwt = "$unsignedToken.$sigB64"

Write-Host "🔑 成功生成 Apple 官方認證 ES256 JWT Token！" -ForegroundColor Green

# 3. 測試連線查詢 App Store Connect 中的 App 清單
$headers = @{
    "Authorization" = "Bearer $jwt"
    "Content-Type"  = "application/json"
}

Write-Host "`n📡 正在向 https://api.appstoreconnect.apple.com/v1/apps 查詢 App 資料..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/apps" -Headers $headers -Method Get
    $apps = $response.data
    
    if ($null -eq $apps -or $apps.Count -eq 0) {
        Write-Host "⚠️ 您的 Apple 帳號下尚未建立任何 App！" -ForegroundColor Yellow
        Write-Host "請先前往 App Store Connect 點擊「+」新增 App，Bundle ID 選擇：$bundleId" -ForegroundColor White
    } else {
        Write-Host "🎉 成功直連 Apple App Store Connect API！找到 $($apps.Count) 個 App：" -ForegroundColor Green
        
        $targetApp = $null
        foreach ($app in $apps) {
            $isTarget = $app.attributes.bundleId -eq $bundleId
            if ($isTarget) {
                $targetApp = $app
                $tag = "⭐ [當前專案匹配]"
                $color = "Cyan"
            } else {
                $tag = "  "
                $color = "Gray"
            }
            Write-Host "$tag 名稱: $($app.attributes.name) | Bundle ID: $($app.attributes.bundleId) | App ID: $($app.id)" -ForegroundColor $color
        }

        if ($null -ne $targetApp) {
            Write-Host "`n🎯 成功鎖定目標 App: $($targetApp.attributes.name) (Apple App ID: $($targetApp.id))" -ForegroundColor Green
            Set-Content -Path ".\tool\target_app_id.txt" -Value $targetApp.id -Encoding UTF8
            Write-Host "已將目標 App ID 緩存至 .\tool\target_app_id.txt" -ForegroundColor DarkGray
        } else {
            Write-Host "`n⚠️ 12 個 App 中未找到 Bundle ID 為 '$bundleId' 的 App。" -ForegroundColor Yellow
            Write-Host "請確認 App Store Connect 上的 App Bundle ID 是否與專案中的 $bundleId 完全一致！" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ Apple API 連線異常: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Apple 回傳詳情: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}