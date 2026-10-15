import UIKit
import Flutter

/// 🌟 支援 iOS 27+ 強制 UIScene 生命週期之代理
/// 繼承自 FlutterSceneDelegate，由 Flutter 引擎自動接管 Window 與生命週期橋接。
class SceneDelegate: FlutterSceneDelegate {
    
    override func scene(
        _ scene: UIScene, 
        willConnectTo session: UISceneSession, 
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
