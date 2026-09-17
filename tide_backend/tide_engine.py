import requests
import json
import os
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
MODEL_NAME = 'gemini-flash-lite-latest'
STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"]

def main():
    out_dir = "deploy_api"
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    for sid in STATION_IDS:
        try:
            print(f"📡 深度抓取測站: {sid}")
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=15)
            data = r.json()
            
            # 1. 深度解析路徑：相容大寫 Records 與小寫 records
            recs = data.get('Records') or data.get('records', {})
            sea_obs = recs.get('SeaSurfaceObs', {})
            locations = sea_obs.get('Location', [])
            
            if not locations:
                print(f"⚠️ {sid} 找不到 Location 數據")
                continue
                
            loc_data = locations[0]
            # 這是 App 繪圖最需要的清單
            obs_times = loc_data.get('StationObsTimes', {}).get('StationObsTime', [])

            if not obs_times:
                print(f"⚠️ {sid} 觀測清單為空")
                continue

            # 2. 呼叫 AI 進行簡報 (使用最新的 Lite 模型)
            ai_data = {"briefing": "正在透過衛星解析海象...", "safety_score": 80, "activities": ["待定"]}
            try:
                gemini.configure(api_key=GEMINI_API_KEY)
                model = gemini.GenerativeModel(MODEL_NAME)
                # 只給最後三筆數據節省 Token 並提高準確度
                prompt = f"你是台灣海象專家。分析數據：{json.dumps(obs_times[-3:])}。回傳單行JSON: {{\"briefing\":\"一句話描述\",\"safety_score\":85,\"activities\":[\"活動1\",\"活動2\"]}}"
                res = model.generate_content(prompt)
                ai_text = res.text.strip().replace('```json', '').replace('```', '')
                ai_data = json.loads(ai_text)
                print(f"✅ {sid} AI 推理成功")
            except Exception as e:
                print(f"❌ {sid} AI 失敗: {e}")

            # 3. 封裝完整數據
            output = {
                "obs": loc_data, # 這裡現在包含了 StationObsTimes，圖表有救了！
                "ai_expert": ai_data
            }
            
            with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
            print(f"💾 {sid} 完整數據儲存完成 (共 {len(obs_times)} 筆觀測)")

        except Exception as e:
            print(f"💥 {sid} 系統錯誤: {e}")

if __name__ == "__main__":
    main()
