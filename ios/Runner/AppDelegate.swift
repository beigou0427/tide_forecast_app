import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 🌟 1. 註冊本地推播通知 (確保背景執行緒能喚醒 UI 與處理 Deep Link)
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }

    // 🌟 2. 接管 iOS 10+ 的原生通知中心代理 (Apple APNs)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🌟 3. 核心防線：將 UIScene 生命週期請求導向 SceneDelegate
  // 徹底消滅 iOS 27 啟動時的 SIGTRAP (EXC_BREAKPOINT) 崩潰！
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // 這裡的名稱必須與 Info.plist 中的 UISceneConfigurationName 完全一致
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}
