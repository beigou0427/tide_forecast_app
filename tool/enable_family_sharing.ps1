[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-Timestamp {
    return (Get-Date).ToString("HH:mm:ss")
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 Tide Pro - 正在向 Apple 伺服器開通「年度指揮官計畫」家人共享..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$groupId = "22005909"
$targetProductId = "com.beigou.tide_app.pro_yearly"

# -----------------------------------------------------------------------------
# 1. 簽發 ES256 JWT Token
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔑 正在簽發 Apple 官方 ES256 JWT 憑證..." -ForegroundColor Yellow
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
}
Write-Host "[$(Get-Timestamp)] ✅ 憑證簽發完成。" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. 檢索年度訂閱商品實體 ID
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 📡 正在向 Apple 檢索 $targetProductId 的訂閱實體 ID..." -ForegroundColor Yellow
$subListUrl = "https://api.appstoreconnect.apple.com/v1/subscriptionGroups/$groupId/subscriptions"

$yearlySubId = $null

$req = [System.Net.HttpWebRequest]::Create($subListUrl)
$req.Headers.Add("Authorization", "Bearer $jwt")
$req.Method = "GET"

try {
    $res = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($res.GetResponseStream(), [System.Text.Encoding]::UTF8)
    $rawJson = $reader.ReadToEnd()
    $reader.Close()
    $res.Close()
    
    $parsed = ConvertFrom-Json $rawJson
    if ($parsed.data) {
        foreach ($item in $parsed.data) {
            if ($item.attributes.productId -eq $targetProductId) {
                $yearlySubId = $item.id
                Write-Host "   -> 成功鎖定年度方案實體 ID: $yearlySubId" -ForegroundColor Green
                Write-Host "   -> 當前家人共享狀態: $($item.attributes.familySharable)" -ForegroundColor DarkGray
            }
        }
    }
} catch {
    Write-Host "❌ 檢索失敗: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($null -eq $yearlySubId) {
    Write-Host "❌ 未能在群組 $groupId 中找到 $targetProductId！" -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# 3. 調用 PATCH 開通 familySharable: true
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🚀 正在向 Apple 發送 PATCH 請求開通 familySharable: true..." -ForegroundColor Yellow

$patchPayload = @{
    data = @{
        type = "subscriptions"
        id = $yearlySubId
        attributes = @{
            familySharable = $true
        }
    }
}

$patchJson = ConvertTo-Json -InputObject $patchPayload -Depth 10
$patchBytes = [System.Text.Encoding]::UTF8.GetBytes($patchJson)

$patchUrl = "https://api.appstoreconnect.apple.com/v1/subscriptions/$yearlySubId"
$patchReq = [System.Net.HttpWebRequest]::Create($patchUrl)
$patchReq.Headers.Add("Authorization", "Bearer $jwt")
$patchReq.Method = "PATCH"
$patchReq.ContentType = "application/json; charset=utf-8"
$patchReq.ContentLength = $patchBytes.Length

try {
    $reqStream = $patchReq.GetRequestStream()
    $reqStream.Write($patchBytes, 0, $patchBytes.Length)
    $reqStream.Close()

    $patchRes = $patchReq.GetResponse()
    $patchRes.Close()
    Write-Host "[$(Get-Timestamp)] 🎉 成功在 Apple 官方伺服器開通家人共享！" -ForegroundColor Green
} catch [System.Net.WebException] {
    $errRes = $_.Exception.Response
    if ($errRes) {
        $errStream = $errRes.GetResponseStream()
        $errReader = New-Object System.IO.StreamReader($errStream, [System.Text.Encoding]::UTF8)
        $errDetail = $errReader.ReadToEnd()
        Write-Host "[$(Get-Timestamp)] ❌ Apple 伺服器報錯: $errDetail" -ForegroundColor Red
    } else {
        Write-Host "[$(Get-Timestamp)] ❌ 網路例外: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}

# -----------------------------------------------------------------------------
# 4. 回讀驗證：消除行內 if 語法，全版本相容
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔍 正在向 Apple 官方伺服器回讀最新家人共享狀態..." -ForegroundColor Yellow

$vReq = [System.Net.HttpWebRequest]::Create($patchUrl)
$vReq.Headers.Add("Authorization", "Bearer $jwt")
$vReq.Method = "GET"
try {
    $vRes = $vReq.GetResponse()
    $vReader = New-Object System.IO.StreamReader($vRes.GetResponseStream(), [System.Text.Encoding]::UTF8)
    $vRaw = $vReader.ReadToEnd()
    $vReader.Close()
    $vRes.Close()

    $vParsed = ConvertFrom-Json $vRaw
    $actualSharable = $vParsed.data.attributes.familySharable

    # 🌟 消除 PowerShell 5.1 行內 if 報錯，改用安全宣告
    $color = "Red"
    if ($actualSharable -eq $true) {
        $color = "Green"
    }

    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "📋 商品 ID         : $targetProductId" -ForegroundColor Cyan
    Write-Host "📋 Apple 家人共享   : $actualSharable" -ForegroundColor $color
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

    if ($actualSharable -eq $true) {
        Write-Host "🎉 完美驗證！Apple 後台已確認開通家人共享，商業承諾 100% 兌現！" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 家人共享尚未生效，請檢查權限。" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ 回讀驗證提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 操作完成！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan