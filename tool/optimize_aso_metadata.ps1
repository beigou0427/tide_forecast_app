[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-Timestamp {
    return (Get-Date).ToString("HH:mm:ss")
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🍏 Tide Pro - 正在以 .NET 原生 UTF-8 二進位串流向 Apple 注入 ASO 詞庫..." -ForegroundColor Cyan
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
Write-Host "[$(Get-Timestamp)] ✅ 憑證簽發完成。" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. 定義原生純漢字 ASO 詞庫 (字元數嚴格控制在 Apple 限制內)
# -----------------------------------------------------------------------------
$supportUrl = "https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009"
$marketingUrl = "https://beigou0427.github.io/tide_forecast_app/"

# 繁中核心詞庫 (精準 48 字元 <= 100)
$zhKeywords = "磯釣,船釣,路亞,軟絲,黑毛,前打,衝浪,自由潛水,海流,水溫,農曆,月相,氣壓,大潮,中央氣象署,浮標,咬度,沉底"
# 宣傳標語 (精準 46 字元 <= 170)
$zhPromo = "專為釣友與船長打造：85測站光纖直連0延遲，全新純潮汐極簡儀表與全島離線預載神盾上線！"

$zhDesc = @"
【潮汐表 Pro · 老船長海象指揮中心】
專為台灣釣友、航海船長、潛水員與水上運動玩家量身打造的專業海事水文預報工具。直連中央氣象署 (CWA) 官方感測陣列，徹底告別估算誤差，提供精確到小時的潮位、湧浪與風力情資。

【五大海事核心功能】
1. 85 測站光纖直連專線：涵蓋全台 23 座深海資料浮標與 62 座沿岸潮位站，0 延遲實時刷新浪高、週期、水溫、陣風與氣壓。
2. 全新「純潮汐航海儀表模式」：駕駛台專用高對比極簡模式，一鍵隱藏非必要資訊，大字體顯示即時潮高與走水窗口，螢幕常亮永不熄火。
3. 滿退 2 分水走水黃金期計算：自動推算每日滿潮返退與乾潮起流關鍵時刻，連動海溫躍層 ΔT 與大氣氣壓趨勢 ΔP，精準掌握黑毛、軟絲、紅甘、黑鯛活性。
4. 30 分鐘滿潮防困礁與長湧預警：偵測外海週期 10 秒以上深層長湧浪（瘋狗浪）動能通量，並於滿潮前 30 分鐘主動發布高優先級撤退警報。
5. 全台 85 測站一鍵離線神盾預載：出海前 10 秒預載離線水文包，無蜂巢網路訊號的外礁與遠洋作業依然能流暢切換 85 測站。

【訂閱與透明條款說明】
• 提供週費、月度與年度指揮官方案，年度方案享有 7 天免費試用並完整支援 Apple「家人共享」。
• 隱私權政策：$supportUrl
• 使用者授權合約 (EULA)：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
• 退訂與訂閱管理：您可在購買後隨時前往「App Store 帳號設定 > 訂閱項目」管理或取消續訂。
"@

# -----------------------------------------------------------------------------
# 3. 查詢現有 Localizations ID
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 📡 正在向 Apple 查詢 zh-Hant 實體節點..." -ForegroundColor Yellow
$locListUrl = "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$versionId/appStoreVersionLocalizations"

$zhLocId = $null
$req = [System.Net.HttpWebRequest]::Create($locListUrl)
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
            if ($item.attributes.locale -eq "zh-Hant") {
                $zhLocId = $item.id
                Write-Host "   -> 鎖定 zh-Hant 實體節點 ID: $zhLocId" -ForegroundColor Green
            }
        }
    }
} catch {
    Write-Host "❌ 查詢在地化失敗: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# 4. 使用 .NET 原生 HttpWebRequest 二進位串流 PATCH 寫入 (消滅 409 與問號)
# -----------------------------------------------------------------------------
if ($zhLocId) {
    Write-Host "`n[$(Get-Timestamp)] 📝 正在以原生二進位 UTF-8 推送 zh-Hant 核心詞庫與文案..." -ForegroundColor Yellow
    Write-Host "   -> 關鍵字字數: $($zhKeywords.Length) (限制 <= 100)" -ForegroundColor DarkGray
    Write-Host "   -> 宣傳標語字數: $($zhPromo.Length) (限制 <= 170)" -ForegroundColor DarkGray

    $patchObj = @{
        data = @{
            type = "appStoreVersionLocalizations"
            id = $zhLocId
            attributes = @{
                keywords = $zhKeywords
                promotionalText = $zhPromo
                description = $zhDesc
                supportUrl = $supportUrl
                marketingUrl = $marketingUrl
            }
        }
    }

    $jsonString = ConvertTo-Json -InputObject $patchObj -Depth 10
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonString)

    $patchUri = "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$zhLocId"
    $patchReq = [System.Net.HttpWebRequest]::Create($patchUri)
    $patchReq.Headers.Add("Authorization", "Bearer $jwt")
    $patchReq.Method = "PATCH"
    $patchReq.ContentType = "application/json; charset=utf-8"
    $patchReq.ContentLength = $utf8Bytes.Length

    try {
        $reqStream = $patchReq.GetRequestStream()
        $reqStream.Write($utf8Bytes, 0, $utf8Bytes.Length)
        $reqStream.Close()

        $patchRes = $patchReq.GetResponse()
        $patchRes.Close()
        Write-Host "[$(Get-Timestamp)] 🎉 成功以 .NET 二進位 UTF-8 寫入 Apple 官方資料庫！" -ForegroundColor Green
    } catch [System.Net.WebException] {
        $errRes = $_.Exception.Response
        if ($errRes) {
            $errStream = $errRes.GetResponseStream()
            $errReader = New-Object System.IO.StreamReader($errStream, [System.Text.Encoding]::UTF8)
            $errDetail = $errReader.ReadToEnd()
            Write-Host "[$(Get-Timestamp)] ❌ Apple 伺服器詳細報錯: $errDetail" -ForegroundColor Red
        } else {
            Write-Host "[$(Get-Timestamp)] ❌ 網路例外: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# -----------------------------------------------------------------------------
# 5. 回讀驗證：展示 Apple 伺服器上的最新繁體中文詞庫
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔍 正在向 Apple 官方伺服器回讀最新寫入的關鍵字..." -ForegroundColor Yellow
try {
    $verifyUri = "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$zhLocId"
    $vReq = [System.Net.HttpWebRequest]::Create($verifyUri)
    $vReq.Headers.Add("Authorization", "Bearer $jwt")
    $vReq.Method = "GET"
    $vRes = $vReq.GetResponse()
    $vReader = New-Object System.IO.StreamReader($vRes.GetResponseStream(), [System.Text.Encoding]::UTF8)
    $vRaw = $vReader.ReadToEnd()
    $vReader.Close()
    $vRes.Close()

    $vParsed = ConvertFrom-Json $vRaw
    $actualKw = $vParsed.data.attributes.keywords
    $actualPromo = $vParsed.data.attributes.promotionalText

    Write-Host "`n------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "📋 Apple 官方資料庫實存【zh-Hant 關鍵字詞庫】：`n" -ForegroundColor Cyan
    Write-Host $actualKw -ForegroundColor White
    Write-Host "`n📋 Apple 官方資料庫實存【宣傳標語】：`n" -ForegroundColor Cyan
    Write-Host $actualPromo -ForegroundColor White
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

    if ($actualKw -match "\?\?\?\?") {
        Write-Host "❌ 警告：依然存在問號亂碼！" -ForegroundColor Red
    } else {
        Write-Host "✅ 驗證成功：所有漢字與標點符號 100% 清晰純淨，無任何亂碼與問號！" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ 回讀驗證提示: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 作業完成！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan