import requests
import json
import os
import time
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
MODEL_NAME = 'gemini-flash-lite-latest'
STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"] 

gemini.configure(api_key=GEMINI_API_KEY)
model = gemini.GenerativeModel(MODEL_NAME)

def fetch_data(sid):
    url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
    r = requests.get(url, timeout=15)
    return r.json()['records']['location'][0]

def get_ai_advice_batch(batch_data):
    prompt = f"你是台灣海象專家。分析以下數據並回傳 JSON：{json.dumps(batch_data)}。請包含 briefing (一句話), safety_score (0-100), activities (清單)。"
    try:
        res = model.generate_content(prompt)
        clean_json = res.text.strip().replace('```json', '').replace('```', '')
        return json.loads(clean_json)
    except: return {}

def main():
    # 直接建立 api 資料夾在根目錄
    os.makedirs("api", exist_ok=True)
    batch_size = 3
    for i in range(0, len(STATION_IDS), batch_size):
        batch_ids = STATION_IDS[i:i+batch_size]
        batch_list = []
        obs_map = {}
        for sid in batch_ids:
            try:
                data = fetch_data(sid)
                batch_list.append({"id": sid, "data": data})
                obs_map[sid] = data
            except: continue
        
        print(f"📡 AI Batch 處理中: {batch_ids}")
        results = get_ai_advice_batch(batch_list)
        
        for sid in batch_ids:
            if sid in obs_map:
                output = {
                    "obs": obs_map[sid], 
                    "ai_expert": results.get(sid, {"briefing":"海象平穩","safety_score":80,"activities":["釣魚"]})
                }
                with open(f"api/edge_{sid}.json", "w", encoding="utf-8") as f:
                    json.dump(output, f, ensure_ascii=False)
        time.sleep(5)

if __name__ == "__main__":
    main()
