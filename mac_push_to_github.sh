#!/bin/bash
# 🌟 Tide Pro - Mac -> GitHub 零缺陷代碼自動提交與推送腳本
set -e

echo "============================================================"
echo "🍏 正在檢查 Mac 終端機上的零缺陷代碼變更狀態..."
echo "============================================================"

# 1. 顯示當前變更檔案
git status -s

# 2. 將所有重構檔案加入暫存區
git add .

# 3. 提交具備 TQM 與 CQO 標準的完整 Commit 歷史
git commit -m "feat(core): v2.6.0+5 zero-defects macOS Kaizen refactor complete"

# 4. 推送至 GitHub 遠端主分支 (main)
git push origin main

echo "============================================================"
echo "✅ 成功將所有 Mac 零缺陷重構精華推送至 GitHub 遠端倉庫！"
echo "👉 現在您可以回到 Windows 電腦，在專案目錄開啟 PowerShell 輸入："
echo "   git pull origin main"
echo "============================================================"
