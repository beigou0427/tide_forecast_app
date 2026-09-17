import requests
import json
import os
import google.generativeai as gemini

CWA_API_KEY = os.environ.get("CWA_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_KEY")

def main():
    out_dir = "deploy_api"
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f: f.write("")

    # 診斷：先確認 Key 沒被截斷
    print(f"DEBUG: CWA_KEY Starts with: {CWA_API_KEY[:10] if CWA_API_KEY else 'None'}")

    # 測站清單
    STATION_IDS = ["46694A", "C6B01", "C4A01", "C4B01", "C4D01", "C4F01", "C4P01", "C4T01", "C4W02"]

    for sid in STATION_IDS:
        try:
            url = f"https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization={CWA_API_KEY}&StationID={sid}"
            r = requests.get(url, timeout=15)
            
            # 關鍵診斷：如果不是 200，印出回應內容
            if r.status_code != 200:
                print(f"❌ {sid} 請求失敗! Code: {r.status_code}, Body: {r.text}")
                continue
            
            resp_json = r.json()
            if 'records' not in resp_json:
                print(f"⚠️ {sid} 回應缺少 records 欄位: {resp_json}")
                continue

            obs = resp_json['records']['location'][0]
            
            # 預設數據，防止 AI 崩潰
            ai_data = {"briefing": "數據同步中", "safety_score": 90, "activities": ["海邊活動"]}
            
            output = {"obs": obs, "ai_expert": ai_data}
            with open(os.path.join(out_dir, f"edge_{sid}.json"), "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False)
            print(f"✅ {sid} 檔案已生成")

        except Exception as e:
            print(f"💥 {sid} 系統崩潰: {e}")

    print("DEBUG: 目前生成的檔案:", os.listdir(out_dir))

if __name__ == "__main__":
    main()
