# 🚀 Tide Pro 終極部署核對清單 (GitHub Secrets)

為了讓零觸碰 CI/CD 部署管線 (`ios_release.yml` 與 `android_release.yml`) 順利運作，請務必至 **GitHub 儲存庫 -> Settings -> Secrets and variables -> Actions -> Repository secrets** 新增以下機密變數：

## 🍏 iOS 專屬機密 (Apple App Store Connect)
- [ ] `BUILD_CERTIFICATE_BASE64` : 將 Apple Distribution Certificate (.p12) 轉為 Base64 格式的字串。
- [ ] `P12_PASSWORD` : 匯出上述 .p12 檔案時所設定的密碼。
- [ ] `BUILD_PROVISION_PROFILE_BASE64` : 將 Tide Pro 的 App Store Provisioning Profile (.mobileprovision) 轉為 Base64 格式。
- [ ] `KEYCHAIN_PASSWORD` : (隨意設定一組強密碼即可，供 macOS 雲端編譯機暫存鑰匙圈使用，例如 `CI_Temp_Pass_888`)。
- [ ] `APP_STORE_PRIVATE_KEY_BASE64` : 將 Apple Store Connect 申請的 API Key (`AuthKey_WC3YUQ44X5.p8`) 轉為 Base64。

## 🤖 Android 專屬機密 (Google Play Console)
- [ ] `ANDROID_KEYSTORE_BASE64` : 將 Android 簽名檔 (`upload-keystore.jks`) 轉為 Base64 格式。
- [ ] `ANDROID_KEY_PROPERTIES_BASE64` : 將包含 Keystore 密碼與別名的 `key.properties` 檔案轉為 Base64 格式。
- [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` : 從 Google Cloud Platform 申請，具備 Google Play Console 發布權限的 Service Account JSON 檔案內容 (直接貼上明文即可，無須 Base64)。

## 🔥 Firebase 崩潰符號表連動 (雙平台共用)
- [ ] `FIREBASE_CLI_TOKEN` : 透過終端機執行 `firebase login:ci` 取得的授權 Token，用於在編譯後上傳混淆後的 Debug Symbols (防瞎子模式)。

---
> 💡 **Base64 轉換指令提示 (Mac/Linux)**:
> `base64 -i 檔案名稱.p12 | pbcopy`
>
> 🚀 **發射指令**:
> 當上述 Secrets 全數填妥後，在終端機執行以下指令即可全自動發布：
> `git tag v2.6.0`
> `git push origin v2.6.0`