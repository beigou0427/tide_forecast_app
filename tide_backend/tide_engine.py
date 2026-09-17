import requests
import json
import os
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
MODEL_NAME = 'gemini-flash-lite-latest'
STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"]

def main():
    # 建立一個存放資料的乾淨資料夾
    out_dir = "deploy_api"
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    
    # 產生 .nojekyll 防止 GitHub Pages 擋掉檔案
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f:
        f.write("")

    for sid in STATION_IDS:
        try:
            print(f"📡 抓取 {sid}...")
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=15)
            if r.status_code != 200: continue
            
            obs = r.json()['records']['location'][0]
            output = {
                "obs": obs,
                "ai_expert": {"briefing": "雲端 AI 數據載入成功", "safety_score": 90, "activities": ["海邊散步"]}
            }
            
            with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
            print(f"✅ 成功寫入: edge_{sid}.json")
        except Exception as e: print(f"❌ 錯誤 {sid}: {e}")

    print(f"DEBUG: 最終清單 -> {os.listdir(out_dir)}")

if __name__ == "__main__":
    main()
