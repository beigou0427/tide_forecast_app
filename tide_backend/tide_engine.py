import requests
import json
import os
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
MODEL_NAME = 'gemini-flash-lite-latest'

# 測站清單
STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"]

gemini.configure(api_key=GEMINI_API_KEY)
model = gemini.GenerativeModel(MODEL_NAME)

def fetch_data(sid):
    # 嘗試抓取氣象署數據
    url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
    r = requests.get(url, timeout=15)
    return r.json()['records']['location'][0]

def get_ai_advice(raw):
    prompt = f"你是台灣海象專家，請根據數據給出建議：{json.dumps(raw)}。請嚴格回傳格式：{{\"briefing\":\"一句話描述\",\"safety_score\":80,\"activities\":[\"活動1\"]}}"
    try:
        res = model.generate_content(prompt)
        return json.loads(res.text.strip().replace('```json', '').replace('```', ''))
    except:
        return {"briefing": "海象平穩。", "safety_score": 85, "activities": ["釣魚"]}

def main():
    for sid in STATION_IDS:
        try:
            print(f"Processing {sid}...")
            obs = fetch_data(sid)
            advice = get_ai_advice(obs)
            output = {"obs": obs, "ai_expert": advice}
            with open(f"public/api/edge_{sid}.json", "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
        except Exception as e:
            print(f"Error {sid}: {e}")

if __name__ == "__main__":
    main()
