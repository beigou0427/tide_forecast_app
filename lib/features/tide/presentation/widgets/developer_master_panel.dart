import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../premium/services/premium_service.dart';
import '../../../diagnostic/presentation/diagnostic_page.dart';
import '../aso_studio_page.dart';

/// 🌟 獨立抽取的創辦人與開發者專屬後台面板 (支援內部身分切換與自檢控制)
class DeveloperMasterPanel {
  static const String masterSecretPass = "beigou";

  /// 彈出通關密鑰輸入視窗
  static void showAuthDialog(BuildContext context, WidgetRef ref) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.abyssCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: AppColors.pelagicCyan, size: 20),
            SizedBox(width: 8),
            Text(
              "創辦人專屬面板",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: textCtrl,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: "請輸入通關密鑰 (密碼: beigou)...",
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.pelagicCyan, width: 1.0)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pelagicCyan,
              foregroundColor: AppColors.abyssBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (textCtrl.text.trim() == masterSecretPass) {
                Navigator.pop(ctx);
                HapticFeedback.heavyImpact();
                showMasterPanel(context, ref);
              } else {
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ 密鑰錯誤，存取被拒！"), backgroundColor: AppColors.hazardCoral, duration: Duration(seconds: 2)),
                );
              }
            },
            child: const Text("解鎖", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// 彈出創辦人後台底部主選單
  static void showMasterPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.abyssCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        final current = ref.watch(premiumProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.bioGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "創辦人專屬後台 (全系統 41 項自檢)",
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "內部除錯測試工具已全數歸攏於此，一般用戶與 Apple 審查員完全不可見",
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // 1. 41 項實機穿透自檢入口
              ListTile(
                dense: true,
                leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF30D158)),
                title: const Text("開啟 41 項海事實機自檢與混沌中心", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("包含 10 大行銷巨擘 ASO 與 VVIP 零退費實機診斷", style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticPage()));
                },
              ),

              // 2. ASO 宣傳截圖攝影棚
              ListTile(
                dense: true,
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.purpleAccent),
                title: const Text("開啟 ASO 宣傳截圖攝影棚 (Studio)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("產生商店審查 6.7 吋與 6.5 吋宣傳照", style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AsoStudioPage()));
                },
              ),

              const Divider(color: AppColors.glassBorder),
              const SizedBox(height: 8),

              const Text("即時身分狀態切換：", style: TextStyle(color: AppColors.bioGold, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // 身分 1：一般免費用戶
              _buildRoleTile(
                title: "1. 一般免費用戶 (Regular User)",
                subtitle: "鎖定 77 席測站、體驗 3 小時延遲與付費閘門",
                icon: Icons.person_outline_rounded,
                color: Colors.blueGrey,
                isSelected: !current.isPremium && !current.isFounder,
                onSelect: () => applyRole(context, ref, isPro: false, isFounder: false, type: SubscriptionType.none),
              ),
              const SizedBox(height: 8),

              // 身分 2：PRO 專業用戶 (年度指揮官)
              _buildRoleTile(
                title: "2. PRO 專業用戶 (年度指揮官)",
                subtitle: "解鎖 85 站光纖直連、走水黃金期與 AI 簡報",
                icon: Icons.workspace_premium_rounded,
                color: AppColors.pelagicCyan,
                isSelected: current.isPremium && !current.isFounder,
                onSelect: () => applyRole(context, ref, isPro: true, isFounder: false, type: SubscriptionType.yearly),
              ),
              const SizedBox(height: 8),

              // 身分 3：超級 VIP (創始天尊指揮官)
              _buildRoleTile(
                title: "3. 超級 VIP (創始天尊指揮官)",
                subtitle: "終身黑金卡面、專屬語音問候、現場實證認證",
                icon: Icons.military_tech_rounded,
                color: AppColors.bioGold,
                isSelected: current.isFounder,
                onSelect: () => applyRole(context, ref, isPro: true, isFounder: true, type: SubscriptionType.lifetime),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildRoleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppColors.glassBorder, width: isSelected ? 1.5 : 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? color : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10.5)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  /// 沙盒無損切換身分權限
  static Future<void> applyRole(
    BuildContext context,
    WidgetRef ref, {
    required bool isPro,
    required bool isFounder,
    required SubscriptionType type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', isPro);
    await prefs.setBool('is_founder', isFounder);
    await prefs.setInt('sub_type', type.index);
    if (isPro) {
      if (isFounder) {
        await prefs.setString('expiry_date', DateTime(2099, 12, 31).toIso8601String());
      } else {
        await prefs.setString('expiry_date', DateTime.now().add(const Duration(days: 365)).toIso8601String());
      }
    } else {
      await prefs.remove('expiry_date');
    }

    ref.invalidate(premiumProvider);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚡ 模式切換成功：已切換為 ${isFounder ? '👑 超級VIP (創始指揮官)' : (isPro ? '⚡ PRO 專業用戶' : '👤 一般免費用戶')}！"),
          backgroundColor: isFounder ? const Color(0xFF2C1802) : (isPro ? const Color(0xFF0077B6) : Colors.blueGrey),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}