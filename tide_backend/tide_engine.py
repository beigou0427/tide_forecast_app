import requests
import json
import os
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"]

def main():
    out_dir = "deploy_api"
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    print(f"DEBUG: 啟動抓取任務, 共 {len(STATION_IDS)} 站")

    for sid in STATION_IDS:
        try:
            # A. 抓取氣象署數據
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=15)
            if r.status_code != 200:
                print(f"⚠️ {sid} CWA API 錯誤: {r.status_code}")
                continue
            obs = r.json()['records']['location'][0]

            # B. 嘗試 AI 推理 (加上 Try-Except 避免金鑰錯誤導致全線崩潰)
            ai_data = {"briefing": "海象觀測中，AI 專家暫時離線", "safety_score": 85, "activities": ["海邊散步"]}
            try:
                if GEMINI_API_KEY and GEMINI_API_KEY.startswith("AIza"):
                    gemini.configure(api_key=GEMINI_API_KEY)
                    model = gemini.GenerativeModel('gemini-1.5-flash-lite-latest')
                    res = model.generate_content(f"分析並回傳單行JSON: {json.dumps(obs)}")
                    ai_data = json.loads(res.text.strip().replace('```json', '').replace('```', ''))
                    print(f"✅ {sid} AI 推理成功")
                else:
                    print(f"ℹ️ {sid} 跳過 AI (Key 格式可能不正確)")
            except Exception as ai_e:
                print(f"❌ {sid} AI 推理報錯: {ai_e}")

            # C. 無論 AI 是否成功，都儲存檔案
            output = {"obs": obs, "ai_expert": ai_data}
            with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
            print(f"💾 {sid} 檔案儲存完成")

        except Exception as e:
            print(f"💥 {sid} 嚴重系統錯誤: {e}")

    print("DEBUG: 任務結束，已生成檔案:", os.listdir(out_dir))

if __name__ == "__main__":
    main()
