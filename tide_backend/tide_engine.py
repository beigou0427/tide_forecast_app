import requests
import json
import os
import time

try:
    import google.generativeai as gemini
except ImportError:
    gemini = None

CWA_API_KEY = os.environ.get("CWA_KEY", "CWA-7B44D117-3255-4D71-9974-B3A93B937D51")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
MODEL_NAME = 'gemini-flash-lite-latest'

def safe_float(v, default=0.0):
    if v is None: return default
    s = str(v).strip()
    if s in ('None', '-99', '', 'nan', 'null'):
        return default
    try:
        return float(s)
    except:
        return default

def determine_region(county, name, lat, lng):
    county = county or ""
    name = name or ""
    for isl in ['澎湖', '金門', '連江', '馬祖', '綠島', '蘭嶼', '東沙', '南沙', '小琉球', '七美', '東吉']:
        if isl in county or isl in name:
            return "離島"
    if any(c in county for c in ['基隆', '新北', '臺北', '台北', '桃園', '宜蘭']):
        return "北部"
    if any(c in county for c in ['新竹', '苗栗', '臺中', '台中', '彰化', '雲林', '嘉義', '臺南', '台南']):
        return "西部"
    if any(c in county for c in ['高雄', '屏東']):
        return "南部"
    if any(c in county for c in ['花蓮', '臺東', '台東']):
        return "東部"
    if lng < 120.0 or (lat < 22.0 and lng > 121.0): return "離島"
    if lat >= 24.8: return "北部"
    if lat <= 22.8: return "南部"
    if lng >= 121.3: return "東部"
    return "西部"

def fetch_all_cwa_stations():
    try:
        url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}"
        print("📡 正在向中央氣象署請求全台海象感測陣列全量數據...")
        r = requests.get(url, timeout=25)
        if r.status_code != 200:
            print(f"🚨 CWA API 回應異常: HTTP {r.status_code}")
            return []
        data = r.json()
        records = data.get('Records') or data.get('records', {})
        sea_obs = records.get('SeaSurfaceObs', {})
        locations = sea_obs.get('Location', [])
        print(f"✅ 成功獲取 {len(locations)} 個測站即時回傳！")
        return locations
    except Exception as e:
        print(f"🚨 連線 CWA 發生錯誤: {e}")
        return []

def analyze_safety_heuristic(obs_item):
    we = obs_item.get('WeatherElements') or obs_item.get('WeatherElement') or {}
    wave = obs_item.get('Wave') or {}
    
    raw_wave = we.get('WaveHeight') if we.get('WaveHeight') is not None else wave.get('WaveHeight')
    wave_h = safe_float(raw_wave, 0.8)
    wind_s = safe_float(we.get('WindSpeed'), 5.0)
    
    score = 90
    if wave_h > 2.5 or wind_s > 10.0:
        score = 35
        briefing = "風強浪大，外海有長湧浪逼近，嚴禁進行外礁與無防護水上活動。"
        acts = ["防波堤內灣", "整理裝備", "室內觀浪"]
    elif wave_h > 1.5 or wind_s > 7.5:
        score = 65
        briefing = "風浪稍強，潮位變換時走水急促，礁石作釣務必著救生衣與防滑釘鞋。"
        acts = ["港區內搞搞", "背風灣作釣", "衝浪初階"]
    else:
        score = 88
        briefing = "海象平穩，風浪週期適中，全水域作業與作釣條件優良。"
        acts = ["浮游磯釣", "路亞遠投", "岸邊趕海", "休閒船釣"]
        
    return {"briefing": briefing, "safety_score": score, "activities": acts}

def main():
    out_dir = "deploy_api"
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    raw_locations = fetch_all_cwa_stations()
    stations_config = []
    
    for loc in raw_locations:
        st = loc.get('Station', {})
        sid = st.get('StationID') or loc.get('StationID') or ""
        if not sid: continue
        
        name = loc.get('StationName') or f"測站 {sid}"
        county = loc.get('CountyName') or ""
        attr = loc.get('StationAttribute') or loc.get('attr') or ""
        
        geo = loc.get('GeoLocation', {})
        lat = safe_float(geo.get('Latitude'), 0.0)
        lng = safe_float(geo.get('Longitude'), 0.0)
            
        is_buoy = ("浮標" in attr) or ("浮標" in name) or sid.startswith("46")
        region = determine_region(county, name, lat, lng)
        
        stations_config.append({
            "id": sid,
            "name": name,
            "region": region,
            "isBuoy": is_buoy,
            "lat": lat,
            "lng": lng,
            "attr": attr
        })
        
        obs_times = loc.get('StationObsTimes', {}).get('StationObsTime', [])
        latest_obs = obs_times[-1] if obs_times else {}
        ai_advice = analyze_safety_heuristic(latest_obs)
        
        station_snapshot = {
            "obs": loc,
            "ai_expert": ai_advice
        }
        
        with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
            json.dump(station_snapshot, f, ensure_ascii=False)

    with open(os.path.join(out_dir, "stations_config.json"), "w", encoding="utf-8") as f:
        json.dump(stations_config, f, ensure_ascii=False)

    print(f"🎉 處理完成！已成功同步並生成 {len(stations_config)} 個全台灣測站之邊緣 API 節點！")

if __name__ == "__main__":
    main()
