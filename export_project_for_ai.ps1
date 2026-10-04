# 🌟 自動將專案原始碼整合並強制置頂【AI 絕對指令守則】的終極導出腳本
$targetTxt = "project_source_for_ai.txt"

# 1. 強制寫入置頂憲法：【🚨 給 AI 助手的絕對指令守則 (STRICT RULES FOR AI) 🚨】
$rulesLines = @(
    '--- START OF FILE Project Source Code ---',
    '',
    '============================================================',
    '🚨 給 AI 助手的絕對指令守則 (STRICT RULES FOR AI) 🚨',
    '身為接手本專案的 AI 顧問，你必須 100% 嚴格遵守以下規則，否則使用者會拒絕使用：',
    '1. 【一次一段 code】：每次回覆只能提供「單一個檔案的修改」或「單一段程式碼」，並且必須包裝成 PowerShell 寫入指令格式。必須等使用者回覆「下」之後，才能提供下一段，嚴禁一次吐出多個檔案的程式碼。',
    '2. 【Gemini 模型命名】：程式碼中若需指定 Gemini 模型名稱，【絕對不加數字】，永遠用 latest 結尾（例如：必須使用 gemini-flash-lite-latest 或 gemini-pro-latest，嚴禁出現 1.5 或其他數字版號）。',
    '3. 【驗證確認尾綴】：每次提供的 PowerShell 寫入代碼區塊結尾，必須包含提示字串：',
    '   Write-Host "✅ 帶有【AI 強制守則】的終極專案精華已萃取至：$outFile！" -ForegroundColor Green',
    '============================================================',
    '',
    '【Tide Pro 潮汐表 專案完整架構與原始碼】'
)
$rulesHeader = $rulesLines -join "`r`n"

Set-Content -Path $targetTxt -Value $rulesHeader -Encoding utf8

# 2. 寫入 pubspec.yaml
if (Test-Path "pubspec.yaml") {
    Add-Content -Path $targetTxt -Value "`r`n`r`n=== pubspec.yaml ===`r`n" -Encoding utf8
    Get-Content "pubspec.yaml" | Add-Content -Path $targetTxt -Encoding utf8
}

# 3. 遍歷 lib 目錄下所有 .dart 與 .arb，自動排除 .g.dart 與 .freezed.dart 產生檔
$files = Get-ChildItem -Path "lib" -Recurse -File | Where-Object {
    ($_.Extension -eq ".dart" -or $_.Extension -eq ".arb") -and
    $_.Name -notlike "*.g.dart" -and
    $_.Name -notlike "*.freezed.dart"
}

foreach ($f in $files) {
    $relPath = Resolve-Path -Path $f.FullName -Relative
    Add-Content -Path $targetTxt -Value "`r`n`r`n=== $relPath ===`r`n" -Encoding utf8
    Get-Content $f.FullName | Add-Content -Path $targetTxt -Encoding utf8
}

Write-Host "`r`n🎉 成功！已將全專案核心代碼連同【AI 絕對指令守則】封裝至：$targetTxt" -ForegroundColor Cyan
Write-Host "👉 您現在可以直接將 $targetTxt 拖曳餵給新的 AI！" -ForegroundColor Green
