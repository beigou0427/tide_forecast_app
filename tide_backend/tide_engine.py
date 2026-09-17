import requests
import json
import os

CWA_API_KEY = os.environ.get("CWA_KEY")

def _n(v):
    if v is None or str(v).lower() in ["none", "-99", "-99.0", "", "nan"]: return None
    try: return float(v)
    except: return None

def main():
    out_dir = "deploy_api"
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    # 測站清單
    STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"]

    for sid in STATION_IDS:
        try:
            print(f"📡 正在精準抓取: {sid}")
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=15)
            data = r.json()
            
            # 1. 精準定位數據路徑
            records = data.get('Records') or data.get('records', {})
            sea_obs = records.get('SeaSurfaceObs', {})
            locations = sea_obs.get('Location', [])
            
            if not locations:
                print(f"⚠️ {sid} 無即時觀測，跳過")
                continue
                
            loc_data = locations[0]
            obs_list = loc_data.get('StationObsTimes', {}).get('StationObsTime', [])
            
            if not obs_list:
                print(f"⚠️ {sid} 觀測清單為空")
                continue

            # 2. 提取最新的一筆觀測 (Last One)
            latest_raw = obs_list[-1]
            elements = latest_raw.get('WeatherElements', {})
            anemometer = elements.get('PrimaryAnemometer', {})
            
            tide_h = _n(elements.get('TideHeight'))
            wave_h = _n(elements.get('WaveHeight'))
            wind_s = _n(anemometer.get('WindSpeed'))
            tide_l = elements.get('TideLevel', '-')

            # 3. 簡易 AI 邏輯 (此處可未來串接 Gemini)
            safety = 95
            brief = "海象平穩，非常適合戶外活動。"
            if wave_h and wave_h > 1.5:
                safety = 40
                brief = "風浪較大，岸邊活動請務必注意安全！"
            elif wind_s and wind_s > 8:
                safety = 60
                brief = "陣風較強，建議從事背風側活動。"

            # 4. 封裝成 App 期待的格式
            output = {
                "obs": loc_data, # 保留原始結構供 Chart 繪圖
                "ai_expert": {
                    "briefing": f"老船長報告：{brief}",
                    "safety_score": safety,
                    "activities": ["岸釣" if safety > 70 else "室內待命", "觀浪"]
                }
            }
            
            with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
            print(f"✅ {sid} 真實數據同步成功！")

        except Exception as e:
            print(f"❌ {sid} 處理出錯: {e}")

if __name__ == "__main__":
    main()
