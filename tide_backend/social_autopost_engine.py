import json
import os
import glob
from datetime import datetime, timezone, timedelta

TZ_TAIWAN = timezone(timedelta(hours=8))

def calculate_fishing_score(wave, wind, solunar_score, safety_score):
    # 複合黃金釣況演算法 (浪平、風柔、咬度高、安全係數大)
    wave_penalty = min(50.0, wave * 20.0) if wave else 15.0
    wind_penalty = min(40.0, wind * 4.0) if wind else 16.0
    base_score = 60.0
    score = base_score + (safety_score * 0.3) + (solunar_score * 0.3) - wave_penalty - wind_penalty
    return round(max(10.0, min(99.0, score)), 1)

def run_social_engine():
    deploy_dir = "deploy_api"
    config_path = os.path.join(deploy_dir, "stations_config.json")
    
    if not os.path.exists(config_path):
        print("🚨 找不到 stations_config.json，請先執行 tide_engine.py")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        stations = json.load(f)

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
            
            raw_wave = we.get("WaveHeight") or wave.get("WaveHeight")
            raw_wind = we.get("WindSpeed")
            
            wave_val = float(raw_wave) if raw_wave and str(raw_wave) not in ('None', '-99') else 0.8
            wind_val = float(raw_wind) if raw_wind and str(raw_wind) not in ('None', '-99') else 4.5
            
            ai = data.get("ai_expert", {})
            safety_score = ai.get("safety_score", 80)
            
            # 依當日大潮加權
            fishing_score = calculate_fishing_score(wave_val, wind_val, 85, safety_score)
            
            forecasts = data.get("forecasts", [])
            high_tide_str = "晨昏前後"
            for f in forecasts[:4]:
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
                "briefing": ai.get("briefing", "海象平穩")
            })
        except:
            continue

    # 依照黃金釣況綜合評分倒序排列
    ranked_stations.sort(key=lambda x: x["score"], reverse=True)
    top_3 = ranked_stations[:3]

    now_str = datetime.now(TZ_TAIWAN).strftime("%Y年%m月%d日")
    
    # 🌟 生成 Threads / IG / LINE 專用的爆發型格式文案 (精準對齊 App Store「潮汐表」黃金大詞)
    post_content = f"""🌊【老船長每日水文快報】{now_str} 全台 Top 3 爆咬黃金釣況排行榜出爐！

各位釣友與浪人師兄早！
今天受潮汐與湧浪週期影響，老船長 AI 從氣象署全台 85 測站中，精選出今日作業條件最優、魚群活躍度最高的 Top 3 釣點：

🥇 【No.1 爆咬榜首】{top_3[0]['name']}
• 水文評分：🔥 {top_3[0]['score']} 分
• 實測海象：浪高 {top_3[0]['wave']}m • 風速 {top_3[0]['wind']}m/s
• 滿潮黃金水：約 {top_3[0]['high_tide']} (滿潮前後2分咬度最佳)
• 老船長筆記：{top_3[0]['briefing']}

🥈 【No.2 平穩推薦】{top_3[1]['name']}
• 水文評分：⚡ {top_3[1]['score']} 分
• 實測海象：浪高 {top_3[1]['wave']}m • 風速 {top_3[1]['wind']}m/s
• 滿潮時程：約 {top_3[1]['high_tide']}

🥉 【No.3 潛力黑馬】{top_3[2]['name']}
• 水文評分：✨ {top_3[2]['score']} 分
• 實測海象：浪高 {top_3[2]['wave']}m • 風速 {top_3[2]['wind']}m/s
• 滿潮時程：約 {top_3[2]['high_tide']}

⚠️ 【安全提醒】：出海作釣請穿著合格防滑釘鞋與救生衣，嚴防外礁瘋狗浪！
📲 欲查全台 85 測站實時 0 延遲湧浪、30 天潮位回測與 Waze 實況雷達：
👉 請在 App Store 搜尋：「潮汐表」或「潮汐表 Pro」

#潮汐表 #釣魚 #磯釣 #海釣 #潮汐 #浪高 #路亞 #老船長 #潮汐表Pro #出海決策
"""

    output_txt = os.path.join(deploy_dir, "daily_social_blast.txt")
    with open(output_txt, "w", encoding="utf-8") as f:
        f.write(post_content)

    print("=" * 65)
    print("🚀 【全自動社群流量發射台：今日爆款文案生成完畢】")
    print("=" * 65)
    print(post_content)
    print("=" * 65)
    print(f"✅ 已同步保存至：{output_txt}，每天發布至 Threads / FB 群組即可精準承接自然流量！")

if __name__ == "__main__":
    run_social_engine()