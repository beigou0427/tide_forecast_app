Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 正在查詢 Apple 伺服器上的 4 大海事內購商品狀態..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"

if (Test-Path ".\tool\target_app_id.txt") {
    $cachedId = (Get-Content ".\tool\target_app_id.txt").Trim()
    if ($cachedId) { $appId = $cachedId }
}

# 1. 載入金鑰與生成 JWT Token
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

# 2. 查詢該 App 的非消耗型內購 (In-App Purchases)
Write-Host "📡 [1/2] 正在向 Apple 查詢非消耗型內購商品..." -ForegroundColor Yellow
$foundIaps = @{}

try {
    $iapRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/apps/$appId/inAppPurchasesV2" -Headers $headers -Method Get
    if ($null -ne $iapRes.data) {
        foreach ($item in $iapRes.data) {
            $foundIaps[$item.attributes.productId] = $item
        }
    }
} catch {
    Write-Host "⚠️ 非消耗型查詢提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 3. 查詢該 App 的訂閱群組與自動續訂商品 (Subscriptions)
Write-Host "📡 [2/2] 正在向 Apple 查詢自動續訂群組與訂閱項目..." -ForegroundColor Yellow
$foundSubs = @{}
$subGroups = @()

try {
    $groupRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/apps/$appId/subscriptionGroups" -Headers $headers -Method Get
    if ($null -ne $groupRes.data) {
        $subGroups = $groupRes.data
        foreach ($group in $subGroups) {
            $groupId = $group.id
            $subRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/subscriptionGroups/$groupId/subscriptions" -Headers $headers -Method Get
            if ($null -ne $subRes.data) {
                foreach ($sub in $subRes.data) {
                    $foundSubs[$sub.attributes.productId] = $sub
                }
            }
        }
    }
} catch {
    Write-Host "⚠️ 訂閱群組查詢提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 4. 對齊檢驗 4 大海事內購商品清單
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "📋 Apple 官方後台 4 大商品狀態對齊報告：" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$requiredProducts = @(
    @{ ID = "com.beigou.tide_app.pro_weekly";   Name = "週費體驗版";   Type = "SUB" },
    @{ ID = "com.beigou.tide_app.pro_monthly";  Name = "月度專業版";   Type = "SUB" },
    @{ ID = "com.beigou.tide_app.pro_yearly";   Name = "年度指揮官計畫"; Type = "SUB" },
    @{ ID = "com.beigou.tide_app.pro_lifetime"; Name = "終身創始席次"; Type = "IAP" }
)

$missingCount = 0

foreach ($p in $requiredProducts) {
    $pid = $p.ID
    $isFound = $false
    $stateInfo = ""
    
    if ($p.Type -eq "SUB") {
        if ($foundSubs.ContainsKey($pid)) {
            $isFound = $true
            $subObj = $foundSubs[$pid]
            $stateInfo = "已存在 [狀態: $($subObj.attributes.state)]"
        }
    } else {
        if ($foundIaps.ContainsKey($pid)) {
            $isFound = $true
            $iapObj = $foundIaps[$pid]
            $stateInfo = "已存在 [狀態: $($iapObj.attributes.state)]"
        }
    }
    
    if ($isFound) {
        Write-Host "  ✅ $($p.Name) ($pid) -> $stateInfo" -ForegroundColor Green
    } else {
        $missingCount++
        Write-Host "  ❌ $($p.Name) ($pid) -> 尚未在 Apple 後台建立" -ForegroundColor Red
    }
}

Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

if ($missingCount -eq 0) {
    Write-Host "🎉 4 大商品皆已在 Apple 伺服器建立完備！" -ForegroundColor Green
} else {
    Write-Host "⚠️ 尚有 $missingCount 個商品待建立。我們已準備好下一步建立腳本！" -ForegroundColor Yellow
}