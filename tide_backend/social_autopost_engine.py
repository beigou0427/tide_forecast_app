import json
import os
import glob
from datetime import datetime, timezone, timedelta

TZ_TAIWAN = timezone(timedelta(hours=8))

def calculate_daily_solunar(dt):
    # 對齊 SolunarUtil 29.53 天朔望月演算法
    epoch_ref = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    epoch_days = (dt.astimezone(timezone.utc) - epoch_ref).total_seconds() / 86400.0
    synodic_month = 29.53058867
    phase_ratio = (epoch_days % synodic_month) / synodic_month
    lunar_day = round(phase_ratio * synodic_month) % 30 + 1

    if (1 <= lunar_day <= 3) or (15 <= lunar_day <= 17):
        return 95, "大潮 (流水急湍，活水帶動魚群爆咬)"
    elif (4 <= lunar_day <= 6) or (18 <= lunar_day <= 20):
        return 85, "中潮 (流水平穩，全天咬口平均)"
    elif (7 <= lunar_day <= 8) or (22 <= lunar_day <= 23):
        return 70, "小潮 (走水較緩，活性平穩)"
    elif (9 <= lunar_day <= 10) or (24 <= lunar_day <= 25):
        return 65, "長潮 (潮差最小，流速近滯)"
    else:
        return 80, "中潮/轉潮 (潮水回升，走水漸暢)"

def calculate_fishing_score(wave, wind, solunar_score, safety_score):
    # 複合黃金釣況演算法 (浪平、風柔、咬度高、安全係數大)
    wave_penalty = min(50.0, wave * 22.0) if wave else 20.0
    wind_penalty = min(40.0, wind * 4.5) if wind else 18.0
    base_score = 55.0
    score = base_score + (safety_score * 0.3) + (solunar_score * 0.35) - wave_penalty - wind_penalty
    return round(max(10.0, min(99.0, score)), 1)

def run_social_engine():
    deploy_dir = "deploy_api"
    config_path = os.path.join(deploy_dir, "stations_config.json")
    
    if not os.path.exists(config_path):
        print("🚨 找不到 stations_config.json，請先執行 tide_engine.py")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        stations = json.load(f)

    now = datetime.now(TZ_TAIWAN)
    solunar_score, tide_desc = calculate_daily_solunar(now)

    ranked_stations = []

    for s in stations:
        sid = s.get("id")
        edge_file = os.path.join(deploy_dir, f"edge_{sid}.json")
        if not os.path.exists(edge_file): continue

        try:
            with open(edge_file, "r", encoding="utf-8") as ef:
                data = json.load(ef)
                
            obs = data.get("obs", {})
            we = obs.get("WeatherElements") or obs.get("WeatherElement") or {}
            wave = obs.get("Wave") or {}
            
            raw_wave = we.get("WaveHeight") if we.get("WaveHeight") is not None else wave.get("WaveHeight")
            raw_wind = we.get("WindSpeed")
            
            # 生命安全防衛：感測器斷線的測站嚴禁登上出海推薦榜單
            if raw_wave is None or str(raw_wave).strip() in ('None', '-99', '-999', 'nan', ''):
                continue
            if raw_wind is None or str(raw_wind).strip() in ('None', '-99', '-999', 'nan', ''):
                continue
                
            wave_val = float(raw_wave)
            wind_val = float(raw_wind)
            
            ai = data.get("ai_expert", {})
            safety_score = ai.get("safety_score", 70)
            
            # 致命海況（長湧或大浪）直接剔除
            if wave_val >= 2.2 or wind_val >= 10.0 or safety_score < 45:
                continue
            
            fishing_score = calculate_fishing_score(wave_val, wind_val, solunar_score, safety_score)
            
            forecasts = data.get("forecasts", [])
            high_tide_str = "晨昏前後"
            for f in forecasts:
                if "滿" in f.get("Tide", ""):
                    dt_str = f.get("DateTime", "")
                    if "T" in dt_str:
                        high_tide_str = dt_str.split("T")[1][:5]
                        break

            ranked_stations.append({
                "id": sid,
                "name": s.get("name"),
                "region": s.get("region"),
                "wave": wave_val,
                "wind": wind_val,
                "score": fishing_score,
                "high_tide": high_tide_str,
                "briefing": ai.get("briefing", "海象平穩，作業條件佳")
            })
        except:
            continue

    if not ranked_stations:
        print("⚠️ 全台各測站風浪偏大或感測器離線，今日不生成衝擊性出海推薦榜單")
        return

    # 依照黃金釣況綜合評分倒序排列
    ranked_stations.sort(key=lambda x: x["score"], reverse=True)
    top_3 = ranked_stations[:min(3, len(ranked_stations))]

    now_str = now.strftime("%Y年%m月%d日")
    
    post_lines = [
        f"🌊【老船長每日水文快報】{now_str} 全台黃金釣況排行榜出爐！\n",
        f"今日天體水文狀態：✨ {tide_desc}",
        "老船長 AI 從全台 85 測站中，精選出今日實測作業條件最優、魚群活性最高的安全釣點：\n"
    ]

    medals = ["🥇 【No.1 爆咬榜首】", "🥈 【No.2 平穩推薦】", "🥉 【No.3 潛力黑馬】"]
    for i, st in enumerate(top_3):
        post_lines.append(f"{medals[i]} {st['name']}")
        post_lines.append(f"• 水文評分：🔥 {st['score']} 分")
        post_lines.append(f"• 實測海象：浪高 {st['wave']}m • 風速 {st['wind']}m/s")
        post_lines.append(f"• 滿潮黃金水：約 {st['high_tide']} (滿潮返退2分水咬度最佳)")
        post_lines.append(f"• 老船長筆記：{st['briefing']}\n")

    post_lines.append("⚠️ 【安全提醒】：出海作釣請穿著合格防滑釘鞋與救生衣，嚴防外礁瘋狗浪！")
    post_lines.append("📲 欲查全台 85 測站實時 0 延遲湧浪、30 天潮位回測與 Waze 實況雷達：")
    post_lines.append("👉 請在 App Store 搜尋：「潮汐表」或「潮汐表 Pro」\n")
    post_lines.append("#潮汐表 #釣魚 #磯釣 #海釣 #潮汐 #浪高 #路亞 #老船長 #潮汐表Pro #出海決策")

    post_content = "\n".join(post_lines)

    output_txt = os.path.join(deploy_dir, "daily_social_blast.txt")
    with open(output_txt, "w", encoding="utf-8") as f:
        f.write(post_content)

    print("=" * 65)
    print("🚀 【全自動社群流量發射台：今日爆款文案生成完畢】")
    print("=" * 65)
    print(post_content)
    print("=" * 65)
    print(f"✅ 已同步保存至：{output_txt}")

if __name__ == "__main__":
    run_social_engine()
