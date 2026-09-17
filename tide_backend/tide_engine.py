import requests
import json
import os
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
MODEL_NAME = 'gemini-flash-lite-latest'
STATION_IDS = ["46694A", "C6B01", "C4A01"]

def main():
    out_dir = "deploy_api"
    os.makedirs(out_dir, exist_ok=True)
    
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    print(f"DEBUG: CWA_KEY 長度 = {len(CWA_API_KEY) if CWA_API_KEY else 0}")
    print(f"DEBUG: GEMINI_KEY 長度 = {len(GEMINI_API_KEY) if GEMINI_API_KEY else 0}")

    for sid in STATION_IDS:
        try:
            print(f"📡 嘗試抓取測站: {sid}")
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=15)
            
            if r.status_code != 200:
                print(f"❌ CWA API 錯誤代碼: {r.status_code}")
                continue
                
            obs = r.json()['records']['location'][0]
            
            # 嘗試呼叫 AI
            ai_data = {"briefing": "AI 推理跳過或失敗", "safety_score": 80, "activities": ["待定"]}
            try:
                gemini.configure(api_key=GEMINI_API_KEY)
                model = gemini.GenerativeModel(MODEL_NAME)
                prompt = f"分析數據並回傳單行 JSON: {json.dumps(obs)}"
                res = model.generate_content(prompt)
                ai_data = json.loads(res.text.strip().replace('```json', '').replace('```', ''))
                print(f"✅ AI 推理成功: {sid}")
            except Exception as ai_e:
                print(f"⚠️ AI 失敗 (使用預設值): {ai_e}")

            output = {"obs": obs, "ai_expert": ai_data}
            with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
            print(f"💾 檔案已儲存: edge_{sid}.json")

        except Exception as e:
            print(f"💥 嚴重錯誤 {sid}: {e}")

    print("DEBUG: 工作目錄內容 ->", os.listdir(out_dir))

if __name__ == "__main__":
    main()
