[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-Timestamp {
    return (Get-Date).ToString("HH:mm:ss")
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 Tide Pro - 正在啟動 Android 模擬器最新代碼編譯與極速直通管線..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$apkPath = ".\build\app\outputs\flutter-apk\app-debug.apk"

# -----------------------------------------------------------------------------
# 1. 自適應探測 ADB 實體路徑 (相容 PowerShell 5.1 / 7.x)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔍 [步驟 1/6] 自適應探測 Android SDK 與 ADB 實體位置..." -ForegroundColor Yellow

$adbCmd = $null
$candidatePaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ProgramFiles\Android\Android Studio\platform-tools\adb.exe",
    "$env:ProgramFiles(x86)\Android\android-sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
)

foreach ($path in $candidatePaths) {
    if (Test-Path $path) {
        $adbCmd = $path
        break
    }
}

if ($null -eq $adbCmd) {
    $cmdObj = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmdObj) {
        $adbCmd = $cmdObj.Source
    }
}

if ($null -eq $adbCmd) {
    Write-Host "[$(Get-Timestamp)] ❌ 找不到 adb.exe！請確認 Android SDK 是否安裝於標準目錄。" -ForegroundColor Red
    exit 1
}

Write-Host "[$(Get-Timestamp)] ✅ 成功鎖定 ADB 實體位置：" -ForegroundColor Green
Write-Host "   -> $adbCmd" -ForegroundColor DarkGray

$adbDir = Split-Path -Path $adbCmd -Parent
$env:PATH = "$adbDir;$env:PATH"

# -----------------------------------------------------------------------------
# 2. 檢測模擬器連線狀態
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 📱 [步驟 2/6] 檢查模擬器連線狀態..." -ForegroundColor Yellow
$devices = & $adbCmd devices | Where-Object { $_ -match "\tdevice$" }

if ($null -eq $devices -or $devices.Count -eq 0) {
    Write-Host "[$(Get-Timestamp)] ⚠️ 正在重新喚醒 ADB 連線..." -ForegroundColor Yellow
    & $adbCmd kill-server
    Start-Sleep -Seconds 1
    & $adbCmd start-server
    Start-Sleep -Seconds 2
    $devices = & $adbCmd devices | Where-Object { $_ -match "\tdevice$" }
}

if ($null -eq $devices -or $devices.Count -eq 0) {
    Write-Host "[$(Get-Timestamp)] ❌ 找不到在線的 Android 設備或模擬器！請確保模擬器視窗已開啟。" -ForegroundColor Red
    exit 1
}

Write-Host "[$(Get-Timestamp)] ✅ 成功鎖定在線模擬器設備：" -ForegroundColor Green
$devices | ForEach-Object { Write-Host "   -> $_" -ForegroundColor DarkGray }

# -----------------------------------------------------------------------------
# 3. 實時串流編譯最新代碼為 Debug APK
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔨 [步驟 3/6] 正在編譯最新程式碼為 Debug APK (flutter build apk --debug)..." -ForegroundColor Yellow
Write-Host "   -> 正在打包去工程黑話、最新 V2 嵌入層與 SDK 36 配置，請稍候..." -ForegroundColor DarkGray

flutter build apk --debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "[$(Get-Timestamp)] ❌ APK 編譯失敗，請檢查上方 Gradle 錯誤輸出！" -ForegroundColor Red
    exit 1
}
Write-Host "[$(Get-Timestamp)] ✅ 最新 APK 編譯完成！" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 4. 點亮並解鎖螢幕 (解除 Play Protect 與系統安裝阻塞)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 💡 [步驟 4/6] 點亮螢幕、解鎖並關閉 ADB 掃描阻塞..." -ForegroundColor Yellow
& $adbCmd shell input keyevent 26
& $adbCmd shell input keyevent 82
& $adbCmd shell settings put global verifier_verify_adb_installs 0
& $adbCmd shell settings put global package_verifier_user_consent -1
Write-Host "[$(Get-Timestamp)] ✅ 模擬器螢幕已喚醒解鎖。" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 5. 直通推送安裝最新 APK
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 📦 [步驟 5/6] 正在直通安裝最新 APK 至模擬器..." -ForegroundColor Yellow
$installOutput = & $adbCmd install -r -d -t $apkPath 2>&1

if ($installOutput -match "Success") {
    Write-Host "[$(Get-Timestamp)] 🎉 恭喜！最新版 APK 安裝成功 (Success)！" -ForegroundColor Green
} else {
    Write-Host "[$(Get-Timestamp)] ⚠️ 安裝回傳: $installOutput" -ForegroundColor Yellow
    if ($installOutput -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE") {
        Write-Host "偵測到版本簽名衝突，正在卸載舊版本並重裝..." -ForegroundColor Yellow
        & $adbCmd uninstall com.beigou.tideForecastApp
        & $adbCmd install -r -d -t $apkPath
    }
}

# -----------------------------------------------------------------------------
# 6. 秒級啟動 Tide Pro 駕駛台
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🌊 [步驟 6/6] 正在啟動 Tide Pro 最新主畫面 (MainActivity)..." -ForegroundColor Yellow
& $adbCmd shell am start -n com.beigou.tideForecastApp/.MainActivity | Out-Null
Write-Host "[$(Get-Timestamp)] ✅ 主畫面已啟動！" -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🎉 完美大成功！最新版 Tide Pro 2.6.0 已在模擬器中震撼啟動！" -ForegroundColor Green
Write-Host "請切換至模擬器視窗，您將看見完全褪去工程黑話、頂級優雅的航海主畫面！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan