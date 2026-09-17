import requests
import json
import os
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")
MODEL_NAME = 'gemini-flash-lite-latest'
STATION_IDS = ["46694A", "C6B01"] # Debug 模式先跑兩站就好

def main():
    # 使用絕對路徑確保位置正確
    base_dir = os.getcwd()
    output_dir = os.path.join(base_dir, "deploy_me")
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"DEBUG: 目前工作目錄 -> {base_dir}")
    print(f"DEBUG: 目標輸出目錄 -> {output_dir}")

    for sid in STATION_IDS:
        try:
            print(f"📡 正在抓取: {sid}")
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=10)
            obs = r.json()['records']['location'][0]
            
            output_data = {
                "obs": obs,
                "ai_expert": {"briefing": "Debug Mode: 雲端測試中", "safety_score": 99, "activities": ["測試"]}
            }
            
            file_path = os.path.join(output_dir, f"edge_{sid}.json")
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(output_data, f, ensure_ascii=False)
            
            print(f"✅ 檔案已寫入: {file_path}")
            print(f"📏 檔案大小: {os.path.getsize(file_path)} bytes")
        except Exception as e:
            print(f"❌ {sid} 失敗: {e}")

    print("DEBUG: 目錄內容確認 ->", os.listdir(output_dir))

if __name__ == "__main__":
    main()
