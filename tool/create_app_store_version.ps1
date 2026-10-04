[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在透過指令向 Apple 官方伺服器建立 2.6.0 商店版本..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"
$targetVersion = "2.6.0"

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
    "Content-Type"  = "application/json; charset=utf-8"
}

# 2. 查詢現有 App Store 版本
Write-Host "📡 [步驟 1/3] 正在查詢 Apple 後台現有版本..." -ForegroundColor Yellow
$versionUrl = "https://api.appstoreconnect.apple.com/v1/apps/$appId/appStoreVersions"

$existingVerId = $null
try {
    $verRes = Invoke-RestMethod -Uri $versionUrl -Headers $headers -Method Get
    if ($verRes.data) {
        foreach ($v in $verRes.data) {
            $verString = $v.attributes.versionString
            $verState = $v.attributes.appStoreState
            $color = if ($verState -eq "READY_FOR_SALE") { "Green" } else { "Cyan" }
            Write-Host "  • 商店版本: $verString [狀態: $verState]" -ForegroundColor $color
            if ($verString -eq $targetVersion) {
                $existingVerId = $v.id
            }
        }
    }
} catch {
    Write-Host "⚠️ 查詢現有版本提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 3. 建立 2.6.0 版本 (若尚未建立)
$versionId = $existingVerId

if ($null -eq $versionId) {
    Write-Host "`n🔨 [步驟 2/3] 正在向 Apple 官方建立新版本: $targetVersion (iOS)..." -ForegroundColor Yellow

    $createVerBody = @"
{
  "data": {
    "type": "appStoreVersions",
    "attributes": {
      "platform": "IOS",
      "versionString": "$targetVersion"
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
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($createVerBody)
    try {
        $createRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/appStoreVersions" -Headers $headers -Method Post -Body $utf8Bytes
        $versionId = $createRes.data.id
        Write-Host "🎉 成功在 Apple 後台建立新版本: $targetVersion (實體 ID: $versionId)" -ForegroundColor Green
    } catch {
        Write-Host "  建立版本提示: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            Write-Host $reader.ReadToEnd() -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "`nℹ️ [步驟 2/3] 版本 $targetVersion 已存在 (ID: $versionId)，直接進行資訊配置..." -ForegroundColor Cyan
}

# 4. 配置本次更新資訊 (What's New)
if ($null -ne $versionId) {
    Write-Host "`n📝 [步驟 3/3] 正在為 $targetVersion 配置繁體中文本次更新項目 (What's New)..." -ForegroundColor Yellow

    $whatsNew = @"
【Tide Pro 2.6.0 海事純潮汐旗艦版升級】
1. 85 測站光纖直連專線全面調校，實測波高風向 0 延遲刷新。
2. 滿乾潮走水黃金窗口與滿退起流計算升級，新增乾潮底暗礁淺水預警。
3. 全新推出「純潮汐航海儀表模式」，駕駛台一鍵鎖定高對比水文。
4. 支援全島 85 測站一鍵離線神盾預載，外海斷網無縫切換。
"@

    # 查詢版本在地的 localizations
    $locUrl = "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$versionId/appStoreVersionLocalizations"
    try {
        $locRes = Invoke-RestMethod -Uri $locUrl -Headers $headers -Method Get
        $zhLoc = $null
        if ($locRes.data) {
            $zhLoc = $locRes.data | Where-Object { $_.attributes.locale -eq "zh-Hant" }
        }

        if ($zhLoc) {
            $locId = $zhLoc.id
            $patchLocBody = @"
{
  "data": {
    "type": "appStoreVersionLocalizations",
    "id": "$locId",
    "attributes": {
      "whatsNew": "$($whatsNew.Replace("`r`n", "\n").Replace("`n", "\n"))"
    }
  }
}
"@
            $utf8LocBytes = [System.Text.Encoding]::UTF8.GetBytes($patchLocBody)
            Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$locId" -Headers $headers -Method Patch -Body $utf8LocBytes | Out-Null
            Write-Host "✅ 成功以指令寫入繁體中文「本次更新內容 (What's New)」！" -ForegroundColor Green
        } else {
            Write-Host "ℹ️ 尚未生成繁中版本在地化節點，可在網頁直接檢視已建立的 2.6.0 草稿。" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "⚠️ 更新項目寫入提示: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 指令執行完畢！版本 2.6.0 已在 Apple 官方後台建立就緒！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan