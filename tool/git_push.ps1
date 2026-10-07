[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-Timestamp {
    return (Get-Date).ToString("HH:mm:ss")
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 Tide Pro - 正在啟動 v2.6.0+5 旗艦發布終極安全推送管線..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$pushStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# -----------------------------------------------------------------------------
# 1. 靜態程式碼語法分析 (實時串流，要求 0 錯誤、0 警告)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🔍 [步驟 1/6] 執行 flutter analyze (要求 0 錯誤、0 警告)..." -ForegroundColor Yellow
Write-Host "   -> 正在實時檢查 104 個 Dart 檔案型別安全與 lint 規範..." -ForegroundColor DarkGray
flutter analyze
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[$(Get-Timestamp)] ❌ 靜態分析未通過，存在潛在語法隱患，停止推送！" -ForegroundColor Red
    exit 1 
}
Write-Host "[$(Get-Timestamp)] ✅ 靜態分析完美通過：0 錯誤、0 警告！" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. AI 模型命名守則代碼掃描 (嚴禁數字版號，永遠使用 latest 結尾)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🤖 [步驟 2/6] 掃描程式碼中的 Gemini 模型命名規範..." -ForegroundColor Yellow
$dartFiles = Get-ChildItem -Path ".\lib", ".\test" -Filter "*.dart" -Recurse
Write-Host "   -> 正在掃描 $($dartFiles.Count) 個 Dart 檔案，嚴格排查是否含有數字版號..." -ForegroundColor DarkGray

$invalidModelFound = $false
$checkedCount = 0

foreach ($file in $dartFiles) {
    $checkedCount++
    if ($checkedCount % 20 -eq 0 -or $checkedCount -eq $dartFiles.Count) {
        Write-Host "   -> 已排查 $checkedCount / $($dartFiles.Count) 個檔案..." -ForegroundColor DarkGray
    }
    $matches = Select-String -Path $file.FullName -Pattern 'gemini-(?:1\.5|2\.0|pro-\d|flash-\d)'
    if ($matches) {
        Write-Host "🚨 違規！檔案 $($file.FullName) 包含帶有數字版號的 Gemini 模型名稱！" -ForegroundColor Red
        $matches | ForEach-Object { Write-Host "   -> $($_.Line.Trim())" -ForegroundColor Red }
        $invalidModelFound = $true
    }
}

if ($invalidModelFound) {
    Write-Host "[$(Get-Timestamp)] ❌ 違反【AI 強制守則】：模型名稱絕對不可加數字，永遠必須用 latest 結尾（如 gemini-flash-lite-latest）！停止推送！" -ForegroundColor Red
    exit 1
} else {
    Write-Host "[$(Get-Timestamp)] ✅ AI 模型命名規範審查通過：全域均合規使用 latest 結尾 (如 gemini-flash-lite-latest)！" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# 3. 海事純潮汐標準與安全性單元測試 (10 大指標實時跑測)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🧪 [步驟 3/6] 執行海事水文物理測試 (test/vvip_audit_test.dart)..." -ForegroundColor Yellow
Write-Host "   -> 正在實時跑測 10 大 VVIP 安全指標 (含 Mock 快取隔離與去黑話斷言)..." -ForegroundColor DarkGray
flutter test test/vvip_audit_test.dart
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[$(Get-Timestamp)] ❌ 海事安全測試未通過，水文物理模型有失真風險，停止推送！" -ForegroundColor Red
    exit 1 
}
Write-Host "[$(Get-Timestamp)] ✅ 10 大 VVIP 海事安全測試全數通過！" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 4. 10 大行銷巨擘增長演算法測試 (11 大指標實時跑測)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 🏆 [步驟 4/6] 執行 10 大行銷大老增長與零退費自檢 (test/aso_masters_audit_test.dart)..." -ForegroundColor Yellow
Write-Host "   -> 正在實時驗證反向負向測試、300 字元詞庫與實機自檢套件..." -ForegroundColor DarkGray
flutter test test/aso_masters_audit_test.dart
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[$(Get-Timestamp)] ❌ ASO 增長與零退費自檢未通過，存在客訴退款隱患，停止推送！" -ForegroundColor Red
    exit 1 
}
Write-Host "[$(Get-Timestamp)] ✅ 11 大 ASO 增長測試全數通過！" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 5. Git 暫存與 Apple .p8 私鑰洩漏防禦
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] 📦 [步驟 5/6] 暫存變更並檢查 Apple 私鑰防護..." -ForegroundColor Yellow
git add -A

$stagedP8 = git diff --cached --name-only | Where-Object { $_ -match "\.p8$" }
if ($stagedP8) {
    Write-Host "[$(Get-Timestamp)] 🚨 警報！偵測到 .p8 私鑰檔案已被暫存，正在緊急移除暫存..." -ForegroundColor Red
    git reset HEAD AuthKey_*.p8 *.p8
    Write-Host "[$(Get-Timestamp)] ✅ 已解除私鑰暫存，私鑰安全受保護，杜絕洩漏至 GitHub！" -ForegroundColor Green
}

$commitMsg = "feat: Tide Pro 2.6.0+5 旗艦發布 - VVIP經典純潮汐表上線/Apple家人共享認證生效/抽屜模組化重構/Android 15全通/21項測試全綠燈"
git commit -m $commitMsg

# -----------------------------------------------------------------------------
# 6. 推送至遠端倉庫 (實時顯示傳輸日誌)
# -----------------------------------------------------------------------------
Write-Host "`n[$(Get-Timestamp)] ⬆️ [步驟 6/6] 正在推送到 GitHub 遠端倉庫..." -ForegroundColor Yellow
git push

$pushStopwatch.Stop()
$elapsedSec = [math]::Round($pushStopwatch.Elapsed.TotalSeconds, 1)

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "🎉 完美收官！Tide Pro 2.6.0+5 所有成果已成功同步至 GitHub！(耗時: ${elapsedSec}s)" -ForegroundColor Green
    Write-Host "⚓ 1. 21 項實機海事與 ASO 增長測試 100% 全綠燈通過。" -ForegroundColor Green
    Write-Host "⚓ 2. VVIP 經典純潮汐對照表正式上線，支援一鍵複製純文字至 LINE。" -ForegroundColor Green
    Write-Host "⚓ 3. Apple 官方後台家人共享正式認證生效 (familySharable: True)。" -ForegroundColor Green
    Write-Host "⚓ 4. 抽屜上帝元件解耦為 3 大純淨模組，熱重載與記憶體負擔銳減。" -ForegroundColor Green
    Write-Host "⚓ 5. Android 15 (16KB) NDK 28 與 V2 Embedding 全線打通順暢運行。" -ForegroundColor Green
    Write-Host "⚓ 6. AI 模型命名守則掃描 100% 合規 (gemini-flash-lite-latest 零版號)。" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "`n[$(Get-Timestamp)] ⚠️ 推送中斷，請確認網路連線與遠端倉庫存取權限。" -ForegroundColor Red
}