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

def fetch_all_cwa_observations():
    try:
        url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}"
        print("📡 正在抓取全台 85 測站實時海象觀測 (O-B0075-001)...")
        r = requests.get(url, timeout=25)
        if r.status_code != 200: return []
        records = r.json().get('Records') or r.json().get('records', {})
        locations = records.get('SeaSurfaceObs', {}).get('Location', [])
        print(f"✅ 實時觀測抓取完成: {len(locations)} 站")
        return locations
    except Exception as e:
        print(f"🚨 實時觀測抓取失敗: {e}")
        return []

def extract_locations_recursively(node):
    """自適應穿透 List / Dict 嵌套，尋找所有 Location 預報點"""
    locations = []
    if isinstance(node, dict):
        if 'Location' in node:
            loc = node['Location']
            if isinstance(loc, list): locations.extend(loc)
            elif isinstance(loc, dict): locations.append(loc)
        for k, v in node.items():
            if isinstance(v, (dict, list)):
                locations.extend(extract_locations_recursively(v))
    elif isinstance(node, list):
        for item in node:
            locations.extend(extract_locations_recursively(item))
    return locations

def fetch_all_cwa_forecasts():
    try:
        url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-A0021-001?Authorization={CWA_API_KEY}"
        print("📡 正在抓取全台未來一個月 30 天潮汐預報 (F-A0021-001)...")
        r = requests.get(url, timeout=30)
        if r.status_code != 200: return []
        data = r.json()
        locations = extract_locations_recursively(data.get('Records') or data.get('records') or data)
        print(f"✅ 30天潮汐預報解析成功: 共找到 {len(locations)} 個沿海鄉鎮預報點")
        return locations
    except Exception as e:
        print(f"🚨 30天潮汐預報抓取失敗: {e}")
        return []

def parse_forecast_times(fl):
    results = []
    tp = fl.get('TimePeriods', {})
    daily_list = []
    if isinstance(tp, dict):
        daily_list = tp.get('Daily', [])
    elif isinstance(tp, list):
        for p in tp:
            if isinstance(p, dict):
                daily_list.extend(p.get('Daily', []))
                
    if isinstance(daily_list, dict):
        daily_list = [daily_list]

    for d in daily_list:
        if not isinstance(d, dict): continue
        times = d.get('Time', [])
        if isinstance(times, dict):
            times = [times]
        for t in times:
            if not isinstance(t, dict): continue
            dt = t.get('DateTime')
            tide_type = t.get('Tide', '')
            heights = t.get('TideHeights', {})
            if dt and tide_type:
                results.append({
                    "DateTime": dt,
                    "Tide": tide_type,
                    "TideHeights": heights
                })
    return results

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

    obs_locations = fetch_all_cwa_observations()
    forecast_locations = fetch_all_cwa_forecasts()

    parsed_forecasts = []
    for fl in forecast_locations:
        try:
            f_lat = safe_float(fl.get('Latitude'))
            f_lng = safe_float(fl.get('Longitude'))
            f_name = fl.get('LocationName', '')
            times = parse_forecast_times(fl)
            if times and f_lat != 0 and f_lng != 0:
                parsed_forecasts.append({"lat": f_lat, "lng": f_lng, "name": f_name, "times": times})
        except:
            continue

    print(f"📊 已成功建立 {len(parsed_forecasts)} 個 30 天潮汐空間坐標索引！")

    stations_config = []
    
    for loc in obs_locations:
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
        
        # 🌟 空間拓撲匹配：為此測站綁定最近的 30 天潮汐預報
        station_forecasts = []
        if parsed_forecasts and lat != 0 and lng != 0:
            best_match = min(parsed_forecasts, key=lambda f: (f['lat'] - lat)**2 + (f['lng'] - lng)**2)
            station_forecasts = best_match['times']
        
        obs_times = loc.get('StationObsTimes', {}).get('StationObsTime', [])
        latest_obs = obs_times[-1] if obs_times else {}
        ai_advice = analyze_safety_heuristic(latest_obs)
        
        station_snapshot = {
            "obs": loc,
            "forecasts": station_forecasts,
            "ai_expert": ai_advice
        }
        
        with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
            json.dump(station_snapshot, f, ensure_ascii=False)

    with open(os.path.join(out_dir, "stations_config.json"), "w", encoding="utf-8") as f:
        json.dump(stations_config, f, ensure_ascii=False)

    print(f"🎉 大功告成！全台 {len(stations_config)} 個測站皆已完成【實時海象 + 30天滿乾潮預報】雙軌融合！")

if __name__ == "__main__":
    main()
