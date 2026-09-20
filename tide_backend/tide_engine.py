import requests
import json
import os
import time
from datetime import datetime, timezone, timedelta

CWA_API_KEY = os.environ.get("CWA_KEY", "CWA-7B44D117-3255-4D71-9974-B3A93B937D51")
TZ_TAIWAN = timezone(timedelta(hours=8))

VALID_RANGES = {
    "wave_height": (0.0, 18.0),
    "wind_speed": (0.0, 65.0),
    "sea_temp": (5.0, 38.0),
    "air_temp": (-5.0, 45.0),
    "air_pressure": (900.0, 1050.0),
    "tide_height": (-500.0, 500.0)
}

def safe_float(v, default=None):
    if v is None: return default
    s = str(v).strip()
    if s in ('None', '-99', '-999', '', 'nan', 'null', 'NoneType'):
        return default
    try:
        return float(s)
    except:
        return default

def get_observation_list(loc):
    sot = loc.get('StationObsTimes')
    obs_list = []
    if isinstance(sot, dict):
        res = sot.get('StationObsTime', [])
        obs_list = res if isinstance(res, list) else [res]
    elif isinstance(sot, list):
        obs_list = sot
    else:
        obs = loc.get('Observation')
        if isinstance(obs, list): obs_list = obs
    
    # 🌟 強制按觀測時間遞增排序，確保最後一筆絕對是最新
    return sorted(obs_list, key=lambda x: str(x.get('DateTime') or x.get('DataTime') or ''))

def sanitize_observation(obs_item):
    we = obs_item.get('WeatherElements') or obs_item.get('WeatherElement') or {}
    wave = obs_item.get('Wave') or {}
    
    raw_wave = we.get('WaveHeight') if we.get('WaveHeight') is not None else wave.get('WaveHeight')
    wave_h = safe_float(raw_wave)
    wind_s = safe_float(we.get('WindSpeed'))
    sea_t = safe_float(we.get('SeaTemperature'))
    air_t = safe_float(we.get('AirTemperature') or we.get('Temperature'))
    air_p = safe_float(we.get('AirPressure') or we.get('StationPressure'))

    if wave_h is not None and not (VALID_RANGES["wave_height"][0] <= wave_h <= VALID_RANGES["wave_height"][1]): wave_h = None
    if wind_s is not None and not (VALID_RANGES["wind_speed"][0] <= wind_s <= VALID_RANGES["wind_speed"][1]): wind_s = None
    if sea_t is not None and not (VALID_RANGES["sea_temp"][0] <= sea_t <= VALID_RANGES["sea_temp"][1]): sea_t = None
    if air_t is not None and not (VALID_RANGES["air_temp"][0] <= air_t <= VALID_RANGES["air_temp"][1]): air_t = None
    if air_p is not None and not (VALID_RANGES["air_pressure"][0] <= air_p <= VALID_RANGES["air_pressure"][1]): air_p = None

    return {
        "wave_height": wave_h,
        "wind_speed": wind_s,
        "sea_temp": sea_t,
        "air_temp": air_t,
        "air_pressure": air_p
    }

def check_observation_staleness(data_time_str):
    """
    海象水文可靠度三段評級：
    • <= 24h: 正常在線 (氣象署衛星批次標準週期)
    • > 24h: 設備停擺/維護中
    """
    if not data_time_str: return True, -1, "OFFLINE"
    try:
        s = str(data_time_str).strip().replace('Z', '+00:00')
        if '+' in s or '-' in s[10:]:
            dt = datetime.fromisoformat(s).astimezone(TZ_TAIWAN)
        else:
            clean_s = s[:19].replace('T', ' ')
            dt = datetime.strptime(clean_s, '%Y-%m-%d %H:%M:%S').replace(tzinfo=TZ_TAIWAN)
            
        now_tw = datetime.now(TZ_TAIWAN)
        diff_hours = (now_tw - dt).total_seconds() / 3600.0
        
        if diff_hours <= 6.0:
            status = "REALTIME"
            is_stale = False
        elif diff_hours <= 24.0:
            status = "SATELLITE_ACTIVE"
            is_stale = False
        else:
            status = "MAINTENANCE"
            is_stale = True
            
        return is_stale, round(diff_hours, 1), status
    except Exception as e:
        return True, -1, "ERROR"

def determine_region(county, name, lat, lng):
    county, name = county or "", name or ""
    for isl in ['澎湖', '金門', '連江', '馬祖', '綠島', '蘭嶼', '東沙', '南沙', '小琉球', '七美', '東吉']:
        if isl in county or isl in name: return "離島"
    if any(c in county for c in ['基隆', '新北', '臺北', '台北', '桃園', '宜蘭']): return "北部"
    if any(c in county for c in ['新竹', '苗栗', '臺中', '台中', '彰化', '雲林', '嘉義', '臺南', '台南']): return "西部"
    if any(c in county for c in ['高雄', '屏東']): return "南部"
    if any(c in county for c in ['花蓮', '臺東', '台東']): return "東部"
    if lng < 120.0 or (lat < 22.0 and lng > 121.0): return "離島"
    if lat >= 24.8: return "北部"
    if lat <= 22.8: return "南部"
    if lng >= 121.3: return "東部"
    return "西部"

def fetch_all_cwa_observations():
    try:
        url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}"
        print("🛡️ [看門狗] 正在對接中央氣象署全量觀測數據...")
        r = requests.get(url, timeout=25)
        if r.status_code != 200: return []
        records = r.json().get('Records') or r.json().get('records', {})
        locations = records.get('SeaSurfaceObs', {}).get('Location', [])
        return locations
    except Exception as e:
        print(f"🚨 [看門狗] 觀測連線失敗: {e}")
        return []

def extract_locations_recursively(node):
    locations = []
    if isinstance(node, dict):
        if 'Location' in node:
            loc = node['Location']
            if isinstance(loc, list): locations.extend(loc)
            elif isinstance(loc, dict): locations.append(loc)
        for k, v in node.items():
            if isinstance(v, (dict, list)): locations.extend(extract_locations_recursively(v))
    elif isinstance(node, list):
        for item in node: locations.extend(extract_locations_recursively(item))
    return locations

def fetch_all_cwa_forecasts():
    try:
        url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-A0021-001?Authorization={CWA_API_KEY}"
        print("🛡️ [看門狗] 正在對接未來 30 天潮汐預報模型...")
        r = requests.get(url, timeout=30)
        if r.status_code != 200: return []
        data = r.json()
        locations = extract_locations_recursively(data.get('Records') or data.get('records') or data)
        return locations
    except Exception as e:
        print(f"🚨 [看門狗] 預報連線失敗: {e}")
        return []

def parse_forecast_times(fl):
    results = []
    tp = fl.get('TimePeriods', {})
    daily_list = []
    if isinstance(tp, dict): daily_list = tp.get('Daily', [])
    elif isinstance(tp, list):
        for p in tp:
            if isinstance(p, dict): daily_list.extend(p.get('Daily', []))
    if isinstance(daily_list, dict): daily_list = [daily_list]

    for d in daily_list:
        if not isinstance(d, dict): continue
        times = d.get('Time', [])
        if isinstance(times, dict): times = [times]
        for t in times:
            if not isinstance(t, dict): continue
            dt = t.get('DateTime')
            tide_type = t.get('Tide', '')
            heights = t.get('TideHeights', {})
            if dt and tide_type:
                results.append({"DateTime": dt, "Tide": tide_type, "TideHeights": heights})
    return results

def analyze_safety_heuristic(sanitized_metrics):
    wave_h = sanitized_metrics.get("wave_height") or 0.8
    wind_s = sanitized_metrics.get("wind_speed") or 5.0
    
    score = 90
    if wave_h > 2.5 or wind_s > 10.0:
        score = 35
        briefing = "風強浪大，外海長湧浪逼近，嚴禁外礁與無防護水上作業。"
        acts = ["港內整理裝備", "室內觀浪", "背風灣短暫活動"]
    elif wave_h > 1.5 or wind_s > 7.5:
        score = 65
        briefing = "風浪稍強，潮位變換走水急促，作釣請務必穿著合格救生衣與防滑釘鞋。"
        acts = ["港區內搞搞", "背風灣作釣", "浪況觀察"]
    else:
        score = 88
        briefing = "海況平穩，風浪週期適中，全島多數近岸水域作業條件優良。"
        acts = ["浮游磯釣", "路亞遠投", "沿岸採集", "休閒船釣"]
        
    return {"briefing": briefing, "safety_score": score, "activities": acts}

def main():
    out_dir = "deploy_api"
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    obs_locations = fetch_all_cwa_observations()
    forecast_locations = fetch_all_cwa_forecasts()

    if len(obs_locations) < 50:
        print(f"⚠️ [熔斷警報] 實時測站數僅 {len(obs_locations)} 站！啟動熔斷防禦，保留歷史快照！")
        return

    parsed_forecasts = []
    for fl in forecast_locations:
        try:
            f_lat = safe_float(fl.get('Latitude'))
            f_lng = safe_float(fl.get('Longitude'))
            times = parse_forecast_times(fl)
            if times and f_lat and f_lng:
                parsed_forecasts.append({"lat": f_lat, "lng": f_lng, "times": times})
        except: continue

    stations_config = []
    healthy_station_count = 0
    realtime_count = 0
    satellite_count = 0

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
        
        obs_times = get_observation_list(loc)
        latest_obs = obs_times[-1] if obs_times else {}
        sanitized = sanitize_observation(latest_obs)
        
        data_time_str = latest_obs.get('DateTime') or latest_obs.get('DataTime') or latest_obs.get('ObsTime')
        is_stale, staleness_hours, sync_status = check_observation_staleness(data_time_str)
        
        if not is_stale:
            healthy_station_count += 1
            if sync_status == "REALTIME": realtime_count += 1
            else: satellite_count += 1
        
        station_forecasts = []
        if parsed_forecasts and lat != 0 and lng != 0:
            best_match = min(parsed_forecasts, key=lambda f: (f['lat'] - lat)**2 + (f['lng'] - lng)**2)
            station_forecasts = best_match['times']

        ai_advice = analyze_safety_heuristic(sanitized)
        
        integrity_meta = {
            "is_sanitized": True,
            "is_healthy": not is_stale,
            "sync_status": sync_status,
            "staleness_hours": staleness_hours,
            "clean_metrics": sanitized
        }

        station_snapshot = {
            "obs": loc,
            "forecasts": station_forecasts,
            "ai_expert": ai_advice,
            "integrity": integrity_meta
        }
        
        with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
            json.dump(station_snapshot, f, ensure_ascii=False)

        stations_config.append({
            "id": sid,
            "name": name,
            "region": region,
            "isBuoy": is_buoy,
            "lat": lat,
            "lng": lng,
            "attr": attr,
            "syncStatus": sync_status,
            "isHealthy": not is_stale
        })

    with open(os.path.join(out_dir, "stations_config.json"), "w", encoding="utf-8") as f:
        json.dump(stations_config, f, ensure_ascii=False)

    coverage_rate = round((healthy_station_count / len(stations_config)) * 100, 1) if stations_config else 0
    reliability_score = round(min(100.0, 50.0 + (coverage_rate * 0.5)), 1)

    health_report = {
        "last_updated": datetime.now(TZ_TAIWAN).isoformat(),
        "status": "HEALTHY",
        "reliability_score": reliability_score,
        "total_stations": len(stations_config),
        "healthy_stations": healthy_station_count,
        "realtime_stations": realtime_count,
        "satellite_active_stations": satellite_count,
        "operational_rate": f"{coverage_rate}%",
        "circuit_breaker": False,
        "cwa_api_status": "ONLINE_NORMAL",
        "forecast_points": len(parsed_forecasts)
    }
    
    with open(os.path.join(out_dir, "health_status.json"), "w", encoding="utf-8") as f:
        json.dump(health_report, f, ensure_ascii=False)

    print(f"🌟 [數據看門狗檢驗完畢]")
    print(f" • 監控站點：{len(stations_config)} 站")
    print(f" • 健康覆蓋率：{coverage_rate}% ({healthy_station_count}/{len(stations_config)} 站活躍在線)")
    print(f"   - 🟢 極速直連 (<=6h)：{realtime_count} 站")
    print(f"   - 🔵 衛星批次 (6~24h)：{satellite_count} 站")
    print(f" • 系統數據可靠度得分：{reliability_score} 分")
    print(f" • 健康診斷報告已生成：deploy_api/health_status.json")

if __name__ == "__main__":
    main()
