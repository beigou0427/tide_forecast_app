Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 正在向 Apple 官方伺服器設定終身創始席次 (NT$ 2,990) 定價..." -ForegroundColor Cyan
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

# 2. 全檔位 (limit=8000) 查詢台灣 (TWN) 價格點
Write-Host "📡 [步驟 1/2] 正在向 Apple 查詢台灣 (TWN) 價格檔位 (limit=8000)..." -ForegroundColor Yellow

$pointUrl = "https://api.appstoreconnect.apple.com/v2/inAppPurchases/$lifetimeIapId/pricePoints?filter[territory]=TWN&limit=8000"
$targetPricePointId = $null

try {
    $pointRes = Invoke-RestMethod -Uri $pointUrl -Headers $headers -Method Get
    $count = if ($pointRes.data) { $pointRes.data.Count } else { 0 }
    Write-Host "  取得 $count 個台灣價格檔位，正在精確比對 NT$ 2,990..." -ForegroundColor DarkGray
    
    foreach ($point in $pointRes.data) {
        $cPriceStr = "$($point.attributes.customerPrice)".Trim()
        $cPriceNum = 0.0
        [double]::TryParse($cPriceStr, [ref]$cPriceNum) | Out-Null
        
        if ($cPriceStr -eq "2990" -or $cPriceNum -eq 2990.0) {
            $targetPricePointId = $point.id
            Write-Host "  ✅ 成功鎖定 Apple 台灣官方定價點: NT$ $cPriceStr [ID: $targetPricePointId]" -ForegroundColor Green
            break
        }
    }
} catch {
    Write-Host "❌ 查詢價格點異常: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. 提交 inAppPurchasePriceSchedules 設定排程
if ($null -ne $targetPricePointId) {
    Write-Host "`n💰 [步驟 2/2] 正在向 Apple 提交定價排程 (Base Territory: TWN, NT$ 2,990)..." -ForegroundColor Yellow

    $tempId = '${price1}'
    $bodyObj = @{
        data = @{
            type = "inAppPurchasePriceSchedules"
            relationships = @{
                inAppPurchase = @{
                    data = @{
                        type = "inAppPurchases"
                        id = $lifetimeIapId
                    }
                }
                baseTerritory = @{
                    data = @{
                        type = "territories"
                        id = "TWN"
                    }
                }
                manualPrices = @{
                    data = @(
                        @{
                            type = "inAppPurchasePrices"
                            id = $tempId
                        }
                    )
                }
            }
        }
        included = @(
            @{
                type = "inAppPurchasePrices"
                id = $tempId
                attributes = @{
                    startDate = $null
                }
                relationships = @{
                    inAppPurchasePricePoint = @{
                        data = @{
                            type = "inAppPurchasePricePoints"
                            id = $targetPricePointId
                        }
                    }
                }
            }
        )
    }

    $priceScheduleBody = ConvertTo-Json -InputObject $bodyObj -Depth 10

    try {
        $schedRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/inAppPurchasePriceSchedules" -Headers $headers -Method Post -Body $priceScheduleBody
        Write-Host "🎉 恭喜！成功為終身創始席次設定 Apple 官方定價: NT$ 2,990！" -ForegroundColor Green
    } catch {
        Write-Host "  Apple 伺服器回傳狀態: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            Write-Host $reader.ReadToEnd() -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  ⚠️ 未能在列表中比對到 NT$ 2,990。您可在 App Store Connect 網頁端該商品詳情直接點選【新增定價】選擇 NT$ 2,990。" -ForegroundColor Cyan
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 定價排程指令執行完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan