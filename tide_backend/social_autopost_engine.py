import json
import os
import glob
import re
from datetime import datetime, timezone, timedelta

TZ_TAIWAN = timezone(timedelta(hours=8))

def calculate_daily_solunar(dt):
    # 對齊 SolunarUtil 29.53 天朔望月演算法
    epoch_ref = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    epoch_days = (dt.astimezone(timezone.utc) - epoch_ref).total_seconds() / 86400.0
    synodic_month = 29.53058867
    
    # 消除負數與浮點誤差
    remainder = epoch_days % synodic_month
    if remainder < 0:
        remainder += synodic_month
        
    phase_ratio = remainder / synodic_month
    lunar_day = round(phase_ratio * synodic_month) % 30 + 1

    if (1 <= lunar_day <= 3) or (15 <= lunar_day <= 17):
        return 95, "大潮 (活水急湍，海底魚群大開殺戒，滿潮返退2分水咬度炸裂)"
    elif (4 <= lunar_day <= 6) or (18 <= lunar_day <= 20):
        return 85, "中潮 (走水流速平穩，全天索餌意願平均，浮游磯釣黃金期)"
    elif (7 <= lunar_day <= 8) or (22 <= lunar_day <= 23):
        return 70, "小潮 (走水轉緩，活性平穩，宜攻岬角流尾與浪腳白沫)"
    elif (9 <= lunar_day <= 10) or (24 <= lunar_day <= 25):
        return 65, "長潮 (潮差最小近停潮，建議換用超輕仕掛細線微鐵)"
    else:
        return 80, "中潮/轉潮 (潮水回升，走水漸暢，各標點皆有潛力)"

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
            raw_flux = we.get("wave_energy_flux") or obs.get("wave_energy_flux")
            
            # 安全防衛：離線或數據短缺之測站直接排除
            if raw_wave is None or str(raw_wave).strip() in ('None', '-99', '-999', 'nan', ''):
                continue
            if raw_wind is None or str(raw_wind).strip() in ('None', '-99', '-999', 'nan', ''):
                continue
                
            wave_val = float(raw_wave)
            wind_val = float(raw_wind)
            flux_val = float(raw_flux) if raw_flux else round(0.49 * (wave_val ** 2) * 5.0, 1)
            
            ai = data.get("ai_expert", {})
            safety_score = ai.get("safety_score", 70)
            
            # 極端危險海況不列入出海推薦
            if wave_val >= 2.2 or wind_val >= 10.0 or safety_score < 45:
                continue
            
            fishing_score = calculate_fishing_score(wave_val, wind_val, solunar_score, safety_score)
            
            forecasts = data.get("forecasts", [])
            high_tide_str = "晨昏前後"
            for f in forecasts:
                if "滿" in f.get("Tide", ""):
                    dt_str = f.get("DateTime") or f.get("dateTime") or ""
                    if "T" in dt_str:
                        high_tide_str = dt_str.split("T")[1][:5]
                        break

            # 🌟 正統 Python 正規表達式清洗：相容半形與全形括號代碼 (消滅 Dart RegExp 殘留)
            raw_st_name = s.get("name", "")
            clean_name = re.sub(r'[\(（].*?[\)）]', '', raw_st_name).strip()

            ranked_stations.append({
                "id": sid,
                "name": clean_name if clean_name else raw_st_name,
                "region": s.get("region"),
                "wave": wave_val,
                "wind": wind_val,
                "flux": flux_val,
                "score": fishing_score,
                "high_tide": high_tide_str,
                "briefing": ai.get("briefing", "海象平穩，走水順暢")
            })
        except Exception as err:
            continue

    if not ranked_stations:
        print("⚠️ 今日全島風浪偏大或感測器離線，不發布出海推薦文案")
        return

    # 依照黃金釣況綜合評分倒序排列
    ranked_stations.sort(key=lambda x: x["score"], reverse=True)
    top_3 = ranked_stations[:min(3, len(ranked_stations))]

    now_str = now.strftime("%Y年%m月%d日")
    
    post_lines = [
        f"🔥【老船長每日水文戰報】{now_str} 全台 3 大爆咬黃金戰場揭曉！\n",
        f"各位浪人師兄、磯釣瘋子們早！",
        f"今天海神開門，天體引力正處於：✨ {tide_desc}！",
        "老船長透過全台 85 測站光纖直連數據與流體動力學推算，今天作業條件最頂、魚群開口最狂的 Top 3 戰點出爐：\n"
    ]

    medals = ["🥇 【No.1 爆咬榜首】", "🥈 【No.2 平穩首選】", "🥉 【No.3 潛力黑馬】"]
    for i, st in enumerate(top_3):
        sid = st['id']
        web_link = f"https://beigou0427.github.io/tide_forecast_app/?sid={sid}"
        post_lines.append(f"{medals[i]} {st['name']} ({st['region']}海域)")
        post_lines.append(f"• 水文作戰評分：🔥 {st['score']} 分")
        post_lines.append(f"• 實測海象：浪高 {st['wave']}m • 風速 {st['wind']}m/s • 波能動能 {st['flux']} kW/m")
        post_lines.append(f"• 滿潮黃金水：約 {st['high_tide']} (滿水返退2分水水流最順)")
        post_lines.append(f"• 老船長筆記：{st['briefing']}")
        post_lines.append(f"👉 點擊查看該站實況雷達：{web_link}\n")

    post_lines.append("⚠️ 【老船長保命鐵律】：外礁長湧無情，防滑釘鞋、合格救生衣請穿牢扣緊！退路隨時看在眼裡！")
    post_lines.append("📲 欲查全台 85 測站 0 延遲湧浪、10x 魚種開口預警與 30 天歷史回測：")
    post_lines.append("👉 請在 App Store 搜尋：「潮汐表 Pro」\n")
    post_lines.append("#潮汐表Pro #老船長 #釣魚 #磯釣 #海釣 #黑毛 #軟絲 #路亞 #海象 #浪高 #出海決策")

    post_content = "\n".join(post_lines)

    output_txt = os.path.join(deploy_dir, "daily_social_blast.txt")
    with open(output_txt, "w", encoding="utf-8") as f:
        f.write(post_content)

    print("=" * 65)
    print("🚀 【Bozoma Saint John 社群文案發射台：今日爆款文案生成完畢】")
    print("=" * 65)
    print(post_content)
    print("=" * 65)
    print(f"✅ 已同步保存至：{output_txt}")

if __name__ == "__main__":
    run_social_engine()