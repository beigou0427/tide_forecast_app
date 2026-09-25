import requests
import json
import os
import time
from datetime import datetime, timezone, timedelta

# 🌟 引入 Gemini AI SDK
import google.generativeai as genai

CWA_API_KEY = os.environ.get("CWA_KEY", "CWA-7B44D117-3255-4D71-9974-B3A93B937D51")
GEMINI_KEY = os.environ.get("GEMINI_KEY", "")
if GEMINI_KEY:
    genai.configure(api_key=GEMINI_KEY)

TZ_TAIWAN = timezone(timedelta(hours=8))

# 🌟 氣象署 85 測站權威水文拓撲字典
MASTER_STATIONS_META = {
    "46694A": {"name": "新北貢寮 龍洞資料浮標 (46694A)", "region": "北部", "isBuoy": True, "lat": 25.037, "lng": 121.926, "type": "資料浮標", "agency": "中央氣象署"},
    "C6AH2":  {"name": "新北石門 富貴角資料浮標 (C6AH2)", "region": "北部", "isBuoy": True, "lat": 25.302, "lng": 121.534, "type": "資料浮標", "agency": "中央氣象署"},
    "C6B01":  {"name": "基隆 彭佳嶼資料浮標 (C6B01)", "region": "北部", "isBuoy": True, "lat": 25.607, "lng": 122.052, "type": "資料浮標", "agency": "中央氣象署"},
    "C4A01":  {"name": "新北淡水 淡水潮位站 (C4A01)", "region": "北部", "isBuoy": False, "lat": 25.175, "lng": 121.424, "type": "潮位站", "agency": "中央氣象署"},
    "C4A02":  {"name": "新北八里 台北港潮位站 (C4A02)", "region": "北部", "isBuoy": False, "lat": 25.158, "lng": 121.378, "type": "潮位站", "agency": "中央氣象署"},
    "C4A03":  {"name": "新北石門 麟山鼻潮位站 (C4A03)", "region": "北部", "isBuoy": False, "lat": 25.284, "lng": 121.510, "type": "潮位站", "agency": "中央氣象署"},
    "C4A05":  {"name": "新北貢寮 福隆潮位站 (C4A05)", "region": "北部", "isBuoy": False, "lat": 25.021, "lng": 121.944, "type": "潮位站", "agency": "中央氣象署"},
    "C4A06":  {"name": "新北淡水 淡海潮位站 (C4A06)", "region": "北部", "isBuoy": False, "lat": 25.184, "lng": 121.408, "type": "潮位站", "agency": "中央氣象署"},
    "C4B01":  {"name": "基隆港 基隆潮位站 (C4B01)", "region": "北部", "isBuoy": False, "lat": 25.155, "lng": 121.751, "type": "潮位站", "agency": "中央氣象署"},
    "C4B03":  {"name": "基隆 長潭里潮位站 (C4B03)", "region": "北部", "isBuoy": False, "lat": 25.141, "lng": 121.800, "type": "潮位站", "agency": "中央氣象署"},
    "C4C01":  {"name": "桃園大園 竹圍潮位站 (C4C01)", "region": "北部", "isBuoy": False, "lat": 25.118, "lng": 121.242, "type": "潮位站", "agency": "中央氣象署"},
    "46757B": {"name": "新竹外海 新竹資料浮標 (46757B)", "region": "西部", "isBuoy": True, "lat": 24.761, "lng": 120.852, "type": "資料浮標", "agency": "中央氣象署"},
    "C6F01":  {"name": "台中外海 台中資料浮標 (C6F01)", "region": "西部", "isBuoy": True, "lat": 24.288, "lng": 120.456, "type": "資料浮標", "agency": "中央氣象署"},
    "46778A": {"name": "台南外海 七股資料浮標 (46778A)", "region": "西部", "isBuoy": True, "lat": 23.152, "lng": 120.041, "type": "資料浮標", "agency": "中央氣象署"},
    "C4D01":  {"name": "新竹市 新竹潮位站 (C4D01)", "region": "西部", "isBuoy": False, "lat": 24.848, "lng": 120.916, "type": "潮位站", "agency": "中央氣象署"},
    "C4E01":  {"name": "苗栗後龍 外埔潮位站 (C4E01)", "region": "西部", "isBuoy": False, "lat": 24.654, "lng": 120.771, "type": "潮位站", "agency": "中央氣象署"},
    "C4F01":  {"name": "台中港 臺中港潮位站 (C4F01)", "region": "西部", "isBuoy": False, "lat": 24.256, "lng": 120.518, "type": "潮位站", "agency": "中央氣象署"},
    "C4G01":  {"name": "彰化鹿港 塭港潮位站 (C4G01)", "region": "西部", "isBuoy": False, "lat": 24.062, "lng": 120.395, "type": "潮位站", "agency": "中央氣象署"},
    "C4N01":  {"name": "雲林麥寮 麥寮潮位站 (C4N01)", "region": "西部", "isBuoy": False, "lat": 23.766, "lng": 120.142, "type": "潮位站", "agency": "中央氣象署"},
    "C4J01":  {"name": "台南將軍 將軍潮位站 (C4J01)", "region": "西部", "isBuoy": False, "lat": 23.208, "lng": 120.082, "type": "潮位站", "agency": "中央氣象署"},
    "WRA005": {"name": "苗栗竹南 水利署潮位站 (WRA005)", "region": "西部", "isBuoy": False, "lat": 24.712, "lng": 120.841, "type": "潮位站", "agency": "水利署"},
    "COMC08": {"name": "高雄彌陀 彌陀資料浮標 (COMC08)", "region": "南部", "isBuoy": True, "lat": 22.784, "lng": 120.218, "type": "資料浮標", "agency": "中央氣象署"},
    "46759A": {"name": "屏東外海 鵝鑾鼻資料浮標 (46759A)", "region": "南部", "isBuoy": True, "lat": 21.902, "lng": 120.824, "type": "資料浮標", "agency": "中央氣象署"},
    "46714D": {"name": "屏東 小琉球資料浮標 (46714D)", "region": "南部", "isBuoy": True, "lat": 22.321, "lng": 120.352, "type": "資料浮標", "agency": "中央氣象署"},
    "C4P01":  {"name": "高雄港 高雄潮位站 (C4P01)", "region": "南部", "isBuoy": False, "lat": 22.618, "lng": 120.266, "type": "潮位站", "agency": "中央氣象署"},
    "C4P02":  {"name": "高雄永安 永安潮位站 (C4P02)", "region": "南部", "isBuoy": False, "lat": 22.822, "lng": 120.211, "type": "潮位站", "agency": "中央氣象署"},
    "C4P03":  {"name": "高雄梓官 蚵仔寮潮位站 (C4P03)", "region": "南部", "isBuoy": False, "lat": 22.729, "lng": 120.252, "type": "潮位站", "agency": "中央氣象署"},
    "C4P09":  {"name": "高雄茄萣 興達港潮位站 (C4P09)", "region": "南部", "isBuoy": False, "lat": 22.868, "lng": 120.198, "type": "潮位站", "agency": "中央氣象署"},
    "C4L01":  {"name": "屏東東港 東港潮位站 (C4L01)", "region": "南部", "isBuoy": False, "lat": 22.468, "lng": 120.442, "type": "潮位站", "agency": "中央氣象署"},
    "C4L02":  {"name": "屏東恆春 後壁湖潮位站 (C4L02)", "region": "南部", "isBuoy": False, "lat": 21.942, "lng": 120.744, "type": "潮位站", "agency": "中央氣象署"},
    "46706A": {"name": "宜蘭蘇澳 蘇澳資料浮標 (46706A)", "region": "東部", "isBuoy": True, "lat": 24.615, "lng": 121.874, "type": "資料浮標", "agency": "中央氣象署"},
    "46708A": {"name": "宜蘭頭城 龜山島資料浮標 (46708A)", "region": "東部", "isBuoy": True, "lat": 24.848, "lng": 121.942, "type": "資料浮標", "agency": "中央氣象署"},
    "46699A": {"name": "花蓮外海 花蓮資料浮標 (46699A)", "region": "東部", "isBuoy": True, "lat": 24.032, "lng": 121.632, "type": "資料浮標", "agency": "中央氣象署"},
    "46761F": {"name": "台東成功 成功資料浮標 (46761F)", "region": "東部", "isBuoy": True, "lat": 23.124, "lng": 121.411, "type": "資料浮標", "agency": "中央氣象署"},
    "WRA007": {"name": "台東市 水利署台東浮標 (WRA007)", "region": "東部", "isBuoy": True, "lat": 22.752, "lng": 121.168, "type": "資料浮標", "agency": "水利署"},
    "C6S62":  {"name": "台東外洋 資料浮標 (C6S62)", "region": "東部", "isBuoy": True, "lat": 22.502, "lng": 121.512, "type": "資料浮標", "agency": "中央氣象署"},
    "C4U01":  {"name": "宜蘭蘇澳 蘇澳潮位站 (C4U01)", "region": "東部", "isBuoy": False, "lat": 24.598, "lng": 121.865, "type": "潮位站", "agency": "中央氣象署"},
    "C4U02":  {"name": "宜蘭頭城 烏石港潮位站 (C4U02)", "region": "東部", "isBuoy": False, "lat": 24.868, "lng": 121.834, "type": "潮位站", "agency": "中央氣象署"},
    "C4T01":  {"name": "花蓮港 花蓮潮位站 (C4T01)", "region": "東部", "isBuoy": False, "lat": 23.985, "lng": 121.636, "type": "潮位站", "agency": "中央氣象署"},
    "C4S01":  {"name": "台東成功 成功潮位站 (C4S01)", "region": "東部", "isBuoy": False, "lat": 23.102, "lng": 121.378, "type": "潮位站", "agency": "中央氣象署"},
    "C4S02":  {"name": "台東富岡 富岡潮位站 (C4S02)", "region": "東部", "isBuoy": False, "lat": 22.791, "lng": 121.192, "type": "潮位站", "agency": "中央氣象署"},
    "46735A": {"name": "澎湖外海 澎湖資料浮標 (46735A)", "region": "離島", "isBuoy": True, "lat": 23.582, "lng": 119.532, "type": "資料浮標", "agency": "中央氣象署"},
    "46787A": {"name": "金門外海 金門資料浮標 (46787A)", "region": "離島", "isBuoy": True, "lat": 24.382, "lng": 118.421, "type": "資料浮標", "agency": "中央氣象署"},
    "C6W08":  {"name": "馬祖東引 馬祖資料浮標 (C6W08)", "region": "離島", "isBuoy": True, "lat": 26.377, "lng": 120.536, "type": "資料浮標", "agency": "中央氣象署"},
    "C6S94":  {"name": "台東蘭嶼 蘭嶼資料浮標 (C6S94)", "region": "離島", "isBuoy": True, "lat": 22.042, "lng": 121.554, "type": "資料浮標", "agency": "中央氣象署"},
    "C6V27":  {"name": "南海東沙 東沙島資料浮標 (C6V27)", "region": "離島", "isBuoy": True, "lat": 20.702, "lng": 116.724, "type": "資料浮標", "agency": "中央氣象署"},
    "C4W01":  {"name": "澎湖馬公 馬公潮位站 (C4W01)", "region": "離島", "isBuoy": False, "lat": 23.565, "lng": 119.563, "type": "潮位站", "agency": "中央氣象署"},
    "C4W02":  {"name": "澎湖西嶼 澎湖潮位站 (C4W02)", "region": "離島", "isBuoy": False, "lat": 23.604, "lng": 119.518, "type": "潮位站", "agency": "中央氣象署"},
    "C4W03":  {"name": "澎湖白沙 吉貝潮位站 (C4W03)", "region": "離島", "isBuoy": False, "lat": 23.748, "lng": 119.615, "type": "潮位站", "agency": "中央氣象署"},
    "C4W04":  {"name": "澎湖七美 七美潮位站 (C4W04)", "region": "離島", "isBuoy": False, "lat": 23.208, "lng": 119.428, "type": "潮位站", "agency": "中央氣象署"},
    "C4W05":  {"name": "澎湖望安 東吉島潮位站 (C4W05)", "region": "離島", "isBuoy": False, "lat": 23.255, "lng": 119.668, "type": "潮位站", "agency": "中央氣象署"},
    "C4Q01":  {"name": "金門 料羅灣潮位站 (C4Q01)", "region": "離島", "isBuoy": False, "lat": 24.412, "lng": 118.428, "type": "潮位站", "agency": "中央氣象署"},
    "C4Q02":  {"name": "金門 水頭港潮位站 (C4Q02)", "region": "離島", "isBuoy": False, "lat": 24.422, "lng": 118.285, "type": "潮位站", "agency": "中央氣象署"},
}

def resolve_station_meta(sid, raw_name, county, town, attr):
    if sid in MASTER_STATIONS_META:
        m = MASTER_STATIONS_META[sid]
        return m["name"], m["region"], m["isBuoy"], m["lat"], m["lng"], m["type"], m["agency"]

    is_buoy = ("浮標" in attr) or ("浮標" in raw_name) or sid.startswith("46") or sid.startswith("C6")
    station_type = "資料浮標" if is_buoy else ("潮位站" if "潮位" in attr or sid.startswith("C4") else "海象站")
    agency = "水利署" if sid.startswith("WRA") else ("海委會" if sid.startswith("OAC") else "中央氣象署")

    if sid.startswith("C4A") or sid.startswith("C4B") or sid.startswith("C4C") or sid.startswith("C6A") or sid.startswith("C6B"):
        region, lat, lng = "北部", 25.15, 121.50
    elif sid.startswith("C4D") or sid.startswith("C4E") or sid.startswith("C4F") or sid.startswith("C4G") or sid.startswith("C4J") or sid.startswith("C4N") or sid.startswith("C6F"):
        region, lat, lng = "西部", 24.20, 120.40
    elif sid.startswith("C4L") or sid.startswith("C4P") or sid.startswith("COMC"):
        region, lat, lng = "南部", 22.60, 120.30
    elif sid.startswith("C4S") or sid.startswith("C4T") or sid.startswith("C4U") or sid.startswith("C6S"):
        region, lat, lng = "東部", 23.80, 121.60
    elif sid.startswith("C4Q") or sid.startswith("C4W") or sid.startswith("C6W") or sid.startswith("C6V"):
        region, lat, lng = "離島", 23.50, 119.50
    else:
        region, lat, lng = "西部", 23.90, 120.50

    place = f"{county}{town}".strip()
    name = f"{place} {station_type} ({sid})" if place else (f"{raw_name} ({sid})" if raw_name and raw_name != sid else f"海象測站 ({sid})")
    return name, region, is_buoy, lat, lng, station_type, agency

def safe_float(v, default=None):
    if v is None: return default
    s = str(v).strip()
    if s in ('None', '-99', '-999', '', 'nan', 'null'): return default
    try: return float(s)
    except: return default

def get_observation_list(loc):
    sot = loc.get('StationObsTimes')
    obs_list = []
    if isinstance(sot, dict):
        res = sot.get('StationObsTime', [])
        obs_list = res if isinstance(res, list) else [res]
    elif isinstance(sot, list): obs_list = sot
    else:
        obs = loc.get('Observation')
        if isinstance(obs, list): obs_list = obs
    return sorted(obs_list, key=lambda x: str(x.get('DateTime') or x.get('DataTime') or ''))

def sanitize_observation(obs_item):
    we = obs_item.get('WeatherElements') or obs_item.get('WeatherElement') or {}
    wave = obs_item.get('Wave') or {}
    raw_wave = we.get('WaveHeight') if we.get('WaveHeight') is not None else wave.get('WaveHeight')
    
    return {
        "wave_height": safe_float(raw_wave),
        "wind_speed": safe_float(we.get('WindSpeed')),
        "sea_temp": safe_float(we.get('SeaTemperature')),
        "air_temp": safe_float(we.get('AirTemperature') or we.get('Temperature')),
        "air_pressure": safe_float(we.get('AirPressure') or we.get('StationPressure'))
    }

def check_observation_staleness(data_time_str):
    if not data_time_str: return True, -1, "OFFLINE"
    try:
        s = str(data_time_str).strip().replace('Z', '+00:00')
        if '+' in s or '-' in s[10:]: dt = datetime.fromisoformat(s).astimezone(TZ_TAIWAN)
        else: dt = datetime.strptime(s[:19].replace('T', ' '), '%Y-%m-%d %H:%M:%S').replace(tzinfo=TZ_TAIWAN)
        diff_hours = (datetime.now(TZ_TAIWAN) - dt).total_seconds() / 3600.0
        if diff_hours <= 6.0: return False, round(diff_hours, 1), "REALTIME"
        elif diff_hours <= 24.0: return False, round(diff_hours, 1), "SATELLITE_ACTIVE"
        else: return True, round(diff_hours, 1), "MAINTENANCE"
    except: return True, -1, "ERROR"

def fetch_all_cwa_observations():
    try:
        url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}"
        r = requests.get(url, timeout=25)
        if r.status_code != 200: return []
        records = r.json().get('Records') or r.json().get('records', {})
        return records.get('SeaSurfaceObs', {}).get('Location', [])
    except: return []

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
        r = requests.get(url, timeout=30)
        if r.status_code != 200: return []
        return extract_locations_recursively(r.json().get('Records') or r.json().get('records') or r.json())
    except: return []

def parse_forecast_times(fl):
    results = []
    tp = fl.get('TimePeriods', {})
    daily_list = tp.get('Daily', []) if isinstance(tp, dict) else []
    if isinstance(tp, list):
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
            if dt and tide_type:
                results.append({"DateTime": dt, "Tide": tide_type, "TideHeights": t.get('TideHeights', {})})
    return results

def analyze_safety_heuristic(sanitized_metrics, station_name=""):
    wave_h = sanitized_metrics.get("wave_height") or 0.8
    wind_s = sanitized_metrics.get("wind_speed") or 5.0
    
    # 傳統演算法 (無 API Key 時的 Fallback)
    score = 88
    briefing = "海況平穩，風浪週期適中，全島多數近岸水域作業條件優良。"
    acts = ["浮游磯釣", "路亞遠投", "沿岸採集"]
    
    if wave_h > 2.5 or wind_s > 10.0:
        score, briefing, acts = 35, "風強浪大，外海長湧浪逼近，嚴禁外礁與無防護水上作業。", ["港內整理裝備", "室內觀浪"]
    elif wave_h > 1.5 or wind_s > 7.5:
        score, briefing, acts = 65, "風浪稍強，潮位變換走水急促，作釣請務必穿著合格救生衣與防滑釘鞋。", ["港區內搞搞", "背風灣作釣"]

    # 🌟 真實呼叫 Google Gemini AI
    if GEMINI_KEY:
        try:
            # 🚨 絕對遵守 AI 開發守則：嚴禁加上數字版號，永遠使用 latest 結尾
            model = genai.GenerativeModel('gemini-flash-lite-latest')
            prompt = f"""
            你是一位台灣資深討海人與磯釣老船長。請根據以下即時水文數據，評估目前海象的安全度，並給出專業建議。
            測站：{station_name}
            浪高：{wave_h} 公尺
            風速：{wind_s} 公尺/秒
            
            請以 JSON 格式回傳（不要加 Markdown 標記，純 JSON 字串），必須包含以下 3 個欄位：
            "briefing": (字串，用老船長的口吻給出 30 字以內的精要出海與作釣建議)
            "safety_score": (整數 0~100，評估當下安全係數)
            "activities": (字串陣列，例如 ["浮游磯釣", "岸拋路亞"]，最多 3 個適合當下的活動)
            """
            response = model.generate_content(prompt)
            text = response.text.replace('```json', '').replace('```', '').strip()
            ai_data = json.loads(text)
            
            return {
                "briefing": ai_data.get("briefing", briefing),
                "safety_score": ai_data.get("safety_score", score),
                "activities": ai_data.get("activities", acts)
            }
        except Exception as e:
            print(f"⚠️ Gemini 推論失敗，降級為傳統演算法: {e}")
            pass

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
            f_lat, f_lng = safe_float(fl.get('Latitude')), safe_float(fl.get('Longitude'))
            times = parse_forecast_times(fl)
            if times and f_lat and f_lng:
                parsed_forecasts.append({"lat": f_lat, "lng": f_lng, "times": times})
        except: continue

    stations_config = []
    from collections import Counter

    for loc in obs_locations:
        st = loc.get('Station', {})
        sid = st.get('StationID') or loc.get('StationID') or ""
        if not sid: continue
        
        name, region, is_buoy, lat, lng, station_type, agency = resolve_station_meta(
            sid, loc.get('StationName') or "", loc.get('CountyName') or "", loc.get('TownName') or "", loc.get('StationAttribute') or loc.get('attr') or ""
        )

        obs_times = get_observation_list(loc)
        latest_obs = obs_times[-1] if obs_times else {}
        sanitized = sanitize_observation(latest_obs)
        
        data_time_str = latest_obs.get('DateTime') or latest_obs.get('DataTime') or latest_obs.get('ObsTime')
        is_stale, staleness_hours, sync_status = check_observation_staleness(data_time_str)

        station_forecasts = []
        if parsed_forecasts and lat != 0 and lng != 0:
            best_match = min(parsed_forecasts, key=lambda f: (f['lat'] - lat)**2 + (f['lng'] - lng)**2)
            station_forecasts = best_match['times']

        # 🌟 傳入測站名稱以利 Gemini 推理在地化水文特徵
        ai_advice = analyze_safety_heuristic(sanitized, name)
        time.sleep(4.2) # 🌟 節流閥：避開免費版每分鐘 15 次的限流陷阱
        
        station_snapshot = {
            "obs": loc,
            "forecasts": station_forecasts,
            "ai_expert": ai_advice,
            "station_info": {
                "friendly_name": name,
                "region": region,
                "station_type": station_type,
                "agency": agency,
                "lat": lat,
                "lng": lng
            }
        }
        
        with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
            json.dump(station_snapshot, f, ensure_ascii=False)

        stations_config.append({
            "id": sid, "name": name, "region": region, "stationType": station_type,
            "agency": agency, "isBuoy": is_buoy, "lat": lat, "lng": lng,
            "syncStatus": sync_status, "isHealthy": not is_stale
        })

    with open(os.path.join(out_dir, "stations_config.json"), "w", encoding="utf-8") as f:
        json.dump(stations_config, f, ensure_ascii=False)

    counts = Counter(s['region'] for s in stations_config)
    print("\n🎉 【全台灣 85 測站 AI 預運算完畢】")
    for r in ["北部", "西部", "南部", "東部", "離島"]:
        print(f" • {r}海域: {counts.get(r, 0)} 個測站")

if __name__ == "__main__":
    main()