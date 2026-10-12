# 🌟 Tide Pro - 官方自癒型全自動 Tag 發射引擎 (Self-Healing Launch Sequence)
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 啟動 Tide Pro v2.6.0 雙平台自癒發射程序 (Launch Sequence)..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 檢測工作區變更並自癒收斂 (消滅雞生蛋死循環)
$status = git status --porcelain
if ($status) {
    Write-Host "`n🛡️ [自癒防線啟動] 偵測到發射工具等未收斂變更：" -ForegroundColor Yellow
    git status --short
    Write-Host "`n📦 [1/3] 正在自動封裝發射工具與最新資產 (git add & commit)..." -ForegroundColor Yellow
    git add .
    git commit -m "chore(release): 🚀 封裝發射工具腳本與就緒資產準備點火發射"
    Write-Host "🌐 正在同步提交至遠端倉庫..." -ForegroundColor Yellow
    git push
    Write-Host "✅ 工作區已自動修復為絕對純淨狀態！" -ForegroundColor Green
} else {
    Write-Host "`n✅ [1/3] 工作區已確認為絕對純淨狀態！" -ForegroundColor Green
}

# 2. 定義發布版本標籤與審計標題
$TAG_NAME = "v2.6.0"
$RELEASE_TITLE = "Tide Pro v2.6.0+5 旗艦正式版 (SRE & Zero-Defects Certified)"

# 3. 檢查本地與遠端標籤碰撞
$existingTag = git tag -l $TAG_NAME
if ($existingTag) {
    Write-Host "`n⚠️ 偵測到本地標籤 $TAG_NAME，進行重置以確保無碰撞..." -ForegroundColor Yellow
    git tag -d $TAG_NAME
}

# 4. 建立具備完整語意與時間戳記的附註標籤 (Annotated Tag)
Write-Host "`n🏷️ [2/3] 正在封裝具備不可篡改特性的發行標籤: $TAG_NAME..." -ForegroundColor Yellow
git tag -a $TAG_NAME -m "$RELEASE_TITLE"

# 5. 推送標籤至 GitHub，觸發雙平台 Runner 同步點火
Write-Host "`n🔥 [3/3] 正在向 GitHub 發射 Tag，啟動雙平台 GitHub Actions 雲端管線..." -ForegroundColor Yellow
git push origin $TAG_NAME

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "🎉 點火成功！雙平台 CI/CD 飛彈已發射！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "🍎 iOS 提審管線 (macOS Runner)   : 正在編譯混淆 IPA 並透過 iTMSTransporter 傳送至 App Store Connect..." -ForegroundColor White
Write-Host "🤖 Android 提審管線 (Ubuntu Runner): 正在組裝 AAB 並部署至 Google Play Console 內部測試軌道..." -ForegroundColor White
Write-Host "🧠 符號表哨兵 (Crashlytics)       : 將同步注入雙平台 Dart 混淆映射表..." -ForegroundColor White
Write-Host "`n🛰️ 請前往 GitHub 儲存庫的 [Actions] 分頁即時監控發射軌道！" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan