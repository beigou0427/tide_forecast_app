[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 正在透過指令向 Apple 伺服器建立送審清單 (Review Submission)..." -ForegroundColor Cyan
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

# 2. 檢查或建立提審容器 (Review Submission)
Write-Host "📦 [步驟 1/2] 正在向 Apple 申請建立提審容器 (Review Submission)..." -ForegroundColor Yellow

$submissionId = $null
$listSubUrl = "https://api.appstoreconnect.apple.com/v1/apps/$appId/reviewSubmissions?filter[platform]=IOS&filter[state]=READY_FOR_REVIEW"

try {
    $existingSub = Invoke-RestMethod -Uri $listSubUrl -Headers $headers -Method Get
    if ($existingSub.data -and $existingSub.data.Count -gt 0) {
        $submissionId = $existingSub.data[0].id
        Write-Host "  ✅ 找到既有送審容器: $submissionId" -ForegroundColor Green
    }
} catch {}

if ($null -eq $submissionId) {
    $createSubBody = @"
{
  "data": {
    "type": "reviewSubmissions",
    "attributes": {
      "platform": "IOS"
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
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($createSubBody)
    try {
        $createRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/reviewSubmissions" -Headers $headers -Method Post -Body $utf8Bytes
        $submissionId = $createRes.data.id
        Write-Host "  🎉 成功建立全新送審容器！ID: $submissionId" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ 建立提審容器提示: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            Write-Host $reader.ReadToEnd() -ForegroundColor DarkGray
        }
    }
}

# 3. 將 2.6.0 版本掛載至送審容器 (Review Submission Item)
if ($null -ne $submissionId) {
    Write-Host "`n🔗 [步驟 2/2] 正在將版本 2.6.0 掛載至送審項目清單..." -ForegroundColor Yellow

    $addItemBody = @"
{
  "data": {
    "type": "reviewSubmissionItems",
    "relationships": {
      "reviewSubmission": {
        "data": {
          "type": "reviewSubmissions",
          "id": "$submissionId"
        }
      },
      "appStoreVersion": {
        "data": {
          "type": "appStoreVersions",
          "id": "$versionId"
        }
      }
    }
  }
}
"@
    $utf8ItemBytes = [System.Text.Encoding]::UTF8.GetBytes($addItemBody)
    try {
        $itemRes = Invoke-RestMethod -Uri "https://api.appstoreconnect.apple.com/v1/reviewSubmissionItems" -Headers $headers -Method Post -Body $utf8ItemBytes
        Write-Host "  🎉 成功透過指令將版本 2.6.0 掛載至送審清單！(項目 ID: $($itemRes.data.id))" -ForegroundColor Green
    } catch {
        Write-Host "  掛載狀態: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $respText = $reader.ReadToEnd()
            Write-Host $respText -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🏁 指令執行完畢！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan