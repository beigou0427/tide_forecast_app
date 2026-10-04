Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🎨 正在生成符合 Apple 官方審查規格之付費牆截圖 (1242 x 2688)..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Add-Type -AssemblyName System.Drawing

$width = 1242
$height = 2688
$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# 1. 深淵海事背景繪製
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(2, 27, 51))
$graphics.FillRectangle($bgBrush, 0, 0, $width, $height)

# 2. 標題與品牌
$titleFont = New-Object System.Drawing.Font("Arial", 42, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Arial", 26, [System.Drawing.FontStyle]::Regular)
$priceFont = New-Object System.Drawing.Font("Arial", 56, [System.Drawing.FontStyle]::Bold)
$btnFont = New-Object System.Drawing.Font("Arial", 32, [System.Drawing.FontStyle]::Bold)

$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(234, 179, 8))
$cyanBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 180, 216))
$grayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(148, 163, 184))

# 頂部裝飾圓圈與錨點標記
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 180, 216), 4)
$graphics.DrawEllipse($pen, 521, 260, 200, 200)

# 文字排版
$centerFormat = New-Object System.Drawing.StringFormat
$centerFormat.Alignment = [System.Drawing.StringAlignment]::Center

$graphics.DrawString("TIDE PRO", $subFont, $cyanBrush, 621, 200, $centerFormat)
$graphics.DrawString("解鎖老船長 AI 專業旗艦版", $titleFont, $whiteBrush, 621, 520, $centerFormat)
$graphics.DrawString("掌握全台 85 測站光纖直連、全站離線預載與外礁防困礁警報", $subFont, $grayBrush, 621, 600, $centerFormat)

# 買斷方案卡面 (終身創始席次)
$cardRect = New-Object System.Drawing.Rectangle(120, 720, 1002, 600)
$cardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 35, 60))
$cardPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(234, 179, 8), 6)
$graphics.FillRectangle($cardBrush, $cardRect)
$graphics.DrawRectangle($cardPen, $cardRect)

$graphics.DrawString("👑 終身創始席次 (Non-Consumable)", $titleFont, $goldBrush, 621, 780, $centerFormat)
$graphics.DrawString("限量席次 · 終身享有後續所有 AI 算力與全島水文更新", $subFont, $grayBrush, 621, 860, $centerFormat)
$graphics.DrawString("NT$ 2,990", $priceFont, $whiteBrush, 621, 960, $centerFormat)
$graphics.DrawString("一次性付費 · 永久擁有最高權限", $subFont, $cyanBrush, 621, 1080, $centerFormat)

# 功能特色清單
$featureFont = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Regular)
$leftFormat = New-Object System.Drawing.StringFormat
$leftFormat.Alignment = [System.Drawing.StringAlignment]::Near

$y = 1420
$features = @(
    "⚓ 中央氣象署 85 測站光纖直連專線 (0 延遲刷新)",
    "📦 全台 85 測站一鍵離線神盾預載包 (外海斷網無縫切換)",
    "🚨 滿潮前 30 分鐘主動突發長湧瘋狗浪防困礁警報",
    "🐟 四大標竿魚種海溫躍層 ΔT 與氣壓走水推演",
    "🌌 30 天時間序列水文金庫與歷史天文調和回測",
    "☁️ 無限張數雲端高畫質漁獲相簿永久備份"
)

foreach ($f in $features) {
    $graphics.DrawString($f, $featureFont, $whiteBrush, 140, $y, $leftFormat)
    $y += 100
}

# 底部購買按鈕
$btnRect = New-Object System.Drawing.Rectangle(120, 2150, 1002, 140)
$btnBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(234, 179, 8))
$graphics.FillRectangle($btnBrush, $btnRect)
$btnTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(2, 27, 51))
$graphics.DrawString("取得終身創始席次 (NT$ 2,990)", $btnFont, $btnTextBrush, 621, 2190, $centerFormat)

# 儲存圖片
$pngPath = ".\tool\iap_lifetime_review_screenshot.png"
$bitmap.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()

Write-Host "✅ 成功生成符合 Apple 審查規格之截圖: $pngPath" -ForegroundColor Green
Write-Host "  解析度   : 1242 x 2688 (iPhone 標準比例)" -ForegroundColor White
Write-Host "  對應商品 : 終身創始席次 (com.beigou.tide_app.pro_lifetime)" -ForegroundColor Cyan
Write-Host "`n💡 提示：前往 App Store Connect -> [App 內購買項目] -> [終身創始席次]，在最下方的「審查資訊」中上傳這張截圖，狀態便會立即由 MISSING_METADATA 轉為 READY_TO_SUBMIT！" -ForegroundColor Yellow