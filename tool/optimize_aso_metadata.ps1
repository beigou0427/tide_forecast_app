[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 正在向 Apple 官方伺服器注入 2.6.0 頂級 ASO 詞庫與海事文案..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$issuerId = "7c8a4cba-398c-4e88-88bb-9252f72ecdc9"
$keyId = "WC3YUQ44X5"
$p8Path = ".\AuthKey_WC3YUQ44X5.p8"
$appId = "6761328495"
$versionId = "59f74dcd-74b2-427a-a231-c41661755067"

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

# 2. 獲取版本之 zh-Hant 在地化 ID
Write-Host "📡 正在檢索版本 2.6.0 的繁體中文 (zh-Hant) 節點..." -ForegroundColor Yellow
$locUrl = "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$versionId/appStoreVersionLocalizations"
$locId = $null

try {
    $locRes = Invoke-RestMethod -Uri $locUrl -Headers $headers -Method Get
    if ($locRes.data) {
        $zh = $locRes.data | Where-Object { $_.attributes.locale -eq "zh-Hant" }
        if ($zh) { $locId = $zh.id }
    }
} catch {
    Write-Host "❌ 查詢版本在地化失敗: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

if ($null -eq $locId) {
    Write-Host "❌ 未找到 zh-Hant 節點。" -ForegroundColor Red
    exit
}

# 3. 定義頂級 ASO 關鍵字、宣傳語與完整描述
$keywords = "磯釣,船釣,路亞,軟絲,黑毛,前打,衝浪,自由潛水,海流,水溫,農曆,月相,氣壓,大潮,中央氣象署,浮標,咬度,沉底"
$promoText = "🌊 專為釣友與船長打造：85 測站光纖直連 0 延遲，全新「純潮汐極簡儀表」與全島離線預載神盾上線！"
$supportUrl = "https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009"
$marketingUrl = "https://beigou0427.github.io/tide_forecast_app/"

$description = @"
🌊【潮汐表 Pro · 老船長海象指揮中心】
專為台灣釣友、航海船長、潛水員與水上運動玩家量身打造的專業海事水文預報工具。直連中央氣象署 (CWA) 官方感測陣列，徹底告別估算誤差，提供精確到小時的潮位、湧浪與風力情資。

⚓【五大海事核心功能】
1. 85 測站光纖直連專線
涵蓋全台 23 座深海資料浮標與 62 座沿岸潮位站，0 延遲實時刷新浪高、週期、水溫、陣風與氣壓。

2. 全新「純潮汐航海儀表模式」
駕駛台專用高對比極簡模式，一鍵隱藏非必要資訊，大字體顯示即時潮高、走水黃金窗口與暗礁淺水預警，在搖晃甲板上單指盲操零遮擋。

3. 滿退 2 分水走水黃金期計算
自動推算每日滿潮返退與乾潮起流關鍵時刻，連動海溫躍層 ΔT 與大氣氣壓趨勢 ΔP，精準掌握黑毛、軟絲、紅甘、黑鯛活性。

4. 30 分鐘滿潮防困礁與長湧預警
偵測外海週期 10 秒以上深層長湧浪（瘋狗浪）動能通量，並於滿潮前 30 分鐘主動發布高優先級撤退警報。

5. 全台 85 測站一鍵離線神盾預載
出海前 10 秒預載離線水文包，無蜂巢網路訊號的外礁與遠洋作業依然能流暢切換 85 測站。

📜【訂閱與條款說明】
• 提供週費、月度與年度指揮官方案，年度方案享有 7 天免費試用並完整支援 Apple「家人共享」。
• 隱私權政策：$supportUrl
• 使用者授權合約 (EULA)：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
"@

Write-Host "`n📝 正在向 Apple 官方伺服器提交 ASO 關鍵字與轉換文案..." -ForegroundColor Yellow

$patchPayload = @{
    data = @{
        type = "appStoreVersionLocalizations"
        id = $locId
        attributes = @{
            keywords = $keywords
            promotionalText = $promoText
            description = $description
            supportUrl = $supportUrl
            marketingUrl = $marketingUrl
        }
    }
}

$patchJson = ConvertTo-Json -InputObject $patchPayload -Depth 10
$patchBytes = [System.Text.Encoding]::UTF8.GetBytes($patchJson)

try {
    $patchRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$locId" -Headers $headers -Method Patch -Body $patchBytes
    Write-Host "🎉 恭喜！頂級 ASO 關鍵字詞庫與宣傳文案已 100% 寫入 Apple 官方伺服器！" -ForegroundColor Green
    Write-Host "`n📊 注入 ASO 成果檢視：" -ForegroundColor Cyan
    Write-Host "• 關鍵字庫 (Keywords) : $keywords" -ForegroundColor White
    Write-Host "• 宣傳標語 (PromoText): $promoText" -ForegroundColor White
    Write-Host "• 技術支援 (Support)  : $supportUrl" -ForegroundColor White
    Write-Host "• 行銷網站 (Marketing): $marketingUrl" -ForegroundColor White
} catch {
    Write-Host "❌ 提交 ASO 失敗: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host $reader.ReadToEnd() -ForegroundColor DarkGray
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 ASO 注入指令執行完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan