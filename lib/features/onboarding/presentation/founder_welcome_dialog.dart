import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class FounderWelcomeDialog {
  static Future<void> checkAndShowIfNeeded(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFounder = prefs.getBool('is_founder') ?? false;
      final hasShown = prefs.getBool('has_shown_founder_welcome_v2') ?? false;

      if (isFounder && !hasShown) {
        if (!context.mounted) return;
        await prefs.setBool('has_shown_founder_welcome_v2', true);
        HapticFeedback.heavyImpact();
        
        // 🌟 核心修復：在非同步間隙 (await) 之後再度檢查 mounted，消除分析器提示
        if (!context.mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.abyssCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.bioGold, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: AppColors.bioGold, size: 24),
                SizedBox(width: 8),
                Text(
                  "👑 歡迎歸隊，創始天尊",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              "系統偵測到您是 Tide Pro 的早期尊榮支持者！\n\n為了感謝您一路以來的相挺，我們已為您永久解鎖「終身最高權限」。無需再次付費，所有全新 AI 海象引擎與離線神盾皆為您敞開！",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bioGold,
                  foregroundColor: AppColors.abyssBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("接受最高權限", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }
}
