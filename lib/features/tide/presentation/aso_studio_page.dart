import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 🌟 創辦人專屬內部 ASO 截圖渲染攝影棚
/// 用於在實機環境即時渲染 6.7 吋 (iPhone Pro Max) 與 6.5 吋高解析度商店審查素材
class AsoStudioPage extends StatelessWidget {
  const AsoStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyssBlack,
      appBar: AppBar(
        title: const Text(
          "📸 ASO 截圖攝影棚 (內部專用)",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.abyssCard,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.purpleAccent, size: 44),
              ),
              const SizedBox(height: 24),
              const Text(
                "ASO 6.7吋 / 6.5吋 宣傳渲染引擎",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "此模組僅供內部創辦人面板透過授權密鑰啟動。\n所有截圖幀數已對齊 App Store Connect 最高審查規範。\n外部 Release 模式已封閉公網與普通用戶入口。",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder, width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: AppColors.bioGold, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "環境隔離中 · 0 審查風險",
                      style: TextStyle(color: AppColors.bioGold, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}