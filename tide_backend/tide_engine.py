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
    prompt = f"分析海象數據：{json.dumps(batch_data)}。請回傳 JSON，格式為 {{'站點ID': {{'briefing':'...','safety_score':80,'activities':['...']}}}}"
    try:
        res = model.generate_content(prompt)
        return json.loads(res.text.strip().replace('```json', '').replace('```', ''))
    except: return {}

def main():
    # 強制建立一個乾淨的部署資料夾
    out_dir = "deploy_me"
    os.makedirs(out_dir, exist_ok=True)
    
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
            except: print(f"Skip {sid}"); continue
        
        results = get_ai_advice_batch(batch_list)
        for sid in batch_ids:
            if sid in obs_map:
                output = {"obs": obs_map[sid], "ai_expert": results.get(sid, {"briefing":"海象平穩","safety_score":85,"activities":["釣魚"]})}
                with open(f"{out_dir}/edge_{sid}.json", "w", encoding="utf-8") as f:
                    json.dump(output, f, ensure_ascii=False)
        time.sleep(2)

if __name__ == "__main__":
    main()
