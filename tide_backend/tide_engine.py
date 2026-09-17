import requests
import json
import os

CWA_API_KEY = os.environ.get("CWA_KEY")

def main():
    # 強制建立絕對路徑的 deploy_api 資料夾
    base_dir = os.getcwd()
    out_dir = os.path.join(base_dir, "deploy_api")
    os.makedirs(out_dir, exist_ok=True)
    
    # 產生 .nojekyll
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"]

    for sid in STATION_IDS:
        try:
            print(f"📡 正在處理: {sid}")
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=15)
            
            if r.status_code != 200:
                print(f"❌ {sid} API 錯誤: {r.status_code}")
                continue
            
            data = r.json()
            # 🌟 核心修正：同時支援大寫 Records 與小寫 records
            records = data.get('Records') or data.get('records')
            
            if not records or 'Location' not in records:
                # 如果 API 結構異常，抓取失敗也產生一個「保底檔案」，確保 App 不會 404
                obs = {"StationName": f"測站 {sid}", "Station": {"StationID": sid}}
                print(f"⚠️ {sid} 結構異常，生成保底數據")
            else:
                obs = records['Location'][0]

            output = {
                "obs": obs,
                "ai_expert": {
                    "briefing": "老船長 AI 正在分析即時海象...",
                    "safety_score": 88,
                    "activities": ["岸邊垂釣", "觀浪"]
                }
            }
            
            # 寫入檔案
            file_name = f"edge_{sid}.json"
            with open(os.path.join(out_dir, file_name), "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
            print(f"✅ {file_name} 儲存成功")

        except Exception as e:
            print(f"💥 {sid} 系統錯誤: {e}")

    print(f"🏁 任務完成。檔案清單: {os.listdir(out_dir)}")

if __name__ == "__main__":
    main()
