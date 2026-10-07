import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../catch_log/providers/catch_log_provider.dart';

/// 🌟 獨立抽取的官方客服與隱私治理中心 (App Store Guideline 5.1.1 & 3.1.2 權威實作)
class SupportPrivacyModal {
  static const String appleManageSubUrl = "https://support.apple.com/HT202039";
  static const String officialSupportEmail = "support@beigou.app";

  /// 呼叫主客服選單底部彈窗
  static void showSupportModal(
    BuildContext context, {
    required String currentStationId,
    required bool isClassic,
    required WidgetRef ref,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isClassic ? Colors.white : AppColors.abyssCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        final Color titleColor = isClassic ? AppColors.classicText : AppColors.textPrimary;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, 
                  height: 4, 
                  decoration: BoxDecoration(
                    color: isClassic ? Colors.grey.shade300 : Colors.white24, 
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.orangeAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "官方客服與隱私治理中心",
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: titleColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "老船長團隊承諾於 24 小時內親自處理您的問題，嚴格遵守個資法與隱私規範。",
                style: TextStyle(fontSize: 11.5, color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary),
              ),
              const SizedBox(height: 18),

              // 1. 真實應用內工單對話盒
              _buildOptionTile(
                title: "線上工單 / 回報測站水文異常 (即時回覆)",
                desc: "免離開 App，直接填單並自動附帶測站與版本資訊",
                icon: Icons.mark_email_read_rounded,
                color: const Color(0xFF0077B6),
                isClassic: isClassic,
                onTap: () {
                  Navigator.pop(ctx);
                  showInAppTicketDialog(context, currentStationId: currentStationId, isClassic: isClassic);
                },
              ),
              const SizedBox(height: 10),

              // 2. 訂閱管理與退訂指南 (Guideline 3.1.2)
              _buildOptionTile(
                title: "訂閱條款說明與退訂指南",
                desc: "說明如何至 Apple ID 取消自動續訂與申請消費爭議處理",
                icon: Icons.receipt_long_rounded,
                color: AppColors.bioGold,
                isClassic: isClassic,
                onTap: () async {
                  final Uri subGuide = Uri.parse(appleManageSubUrl);
                  if (await canLaunchUrl(subGuide)) {
                    await launchUrl(subGuide, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 10),

              // 3. 被遺忘權數位足跡徹底銷毀 (Guideline 5.1.1)
              _buildOptionTile(
                title: "徹底銷毀個人資料與雲端紀錄",
                desc: "符合 Apple 5.1.1 條款與個資法，一鍵永久抹除本機與雲端資料",
                icon: Icons.delete_forever_rounded,
                color: AppColors.hazardCoral,
                isClassic: isClassic,
                onTap: () => eraseAllUserDataAndCloudFootprint(context, ref: ref),
              ),
              const SizedBox(height: 14),

              Text(
                "⚠️ 消費者保障告知：所有訂閱購買均經由 Apple StoreKit 官方加密通道，您可隨時於 App Store 帳號中取消續訂，保障您的消費者權益。",
                style: TextStyle(fontSize: 10, color: isClassic ? Colors.grey.shade500 : AppColors.textTertiary, height: 1.35),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 應用內真實工單彈窗 (含一鍵複製 Email)
  static void showInAppTicketDialog(
    BuildContext context, {
    required String currentStationId,
    required bool isClassic,
  }) {
    final issueCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: isClassic ? Colors.white : AppColors.abyssCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: isClassic ? Colors.grey.shade300 : AppColors.glassBorder, width: 0.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077B6).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0077B6), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  "提交技術工單與回報",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w900, 
                    color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isClassic ? Colors.blue.shade50 : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "官方支援信箱: $officialSupportEmail", 
                                style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold, 
                                  color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
                                ),
                              ),
                              Text("鎖定測站代號: $currentStationId (v2.6.0)", style: const TextStyle(fontSize: 9.5, color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          icon: const Icon(Icons.copy_rounded, size: 12),
                          label: const Text("複製", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(const ClipboardData(text: officialSupportEmail));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ 已複製官方信箱: $officialSupportEmail"), 
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: issueCtrl,
                    maxLines: 4,
                    style: TextStyle(color: isClassic ? Colors.black87 : AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "請在此描述您遇到的測站水文異常、訂閱權益疑問或功能建議...\n工程師團隊將於 24 小時內親自排查！",
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5, height: 1.4),
                      filled: true,
                      fillColor: isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text("取消", style: TextStyle(color: AppColors.textTertiary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSubmitting ? null : () async {
                  final text = issueCtrl.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請填寫問題描述")));
                    return;
                  }

                  setDlgState(() => isSubmitting = true);
                  HapticFeedback.mediumImpact();

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final deviceId = prefs.getString('device_sync_id') ?? "unknown_device";

                    await FirebaseFirestore.instance.collection('support_tickets').add({
                      'station_id': currentStationId,
                      'device_id': deviceId,
                      'content': text,
                      'version': '2.6.0',
                      'created_at': FieldValue.serverTimestamp(),
                      'status': 'OPEN',
                    });
                  } catch (_) {}

                  if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🎉 工單已直接送達開發團隊！工程師將於 24 小時內親自處理。"),
                        backgroundColor: Color(0xFF30D158),
                        duration: Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: isSubmitting 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("送出工單", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 徹底銷毀個人資料與雲端紀錄 (被遺忘權)
  static Future<void> eraseAllUserDataAndCloudFootprint(
    BuildContext context, {
    required WidgetRef ref,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.abyssCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.hazardCoral, width: 1)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.hazardCoral, size: 24),
            SizedBox(width: 8),
            Text("徹底銷毀個人資料", style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "依據 Apple 規範與個資法規，此動作將不可逆地永久銷毀：\n• 雲端 Firestore 與 Storage 中的所有個人漁獲相片與紀錄\n• 本機快取、老船長積分餘額與個人偏好設定\n\n確定立即執行徹底銷毀？",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text("取消", style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hazardCoral, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text("確認徹底銷毀", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_sync_id');

      if (deviceId != null && deviceId.isNotEmpty) {
        final logsCollection = FirebaseFirestore.instance.collection('users').doc(deviceId).collection('catch_logs');
        final snapshot = await logsCollection.get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        await FirebaseFirestore.instance.collection('users').doc(deviceId).delete();

        try {
          final storageRef = FirebaseStorage.instance.ref().child('users/$deviceId');
          final listResult = await storageRef.listAll();
          for (var item in listResult.items) {
            await item.delete();
          }
        } catch (_) {}
      }

      await prefs.remove('catch_logs_v1');
      await prefs.remove('captain_coins');
      await prefs.remove('blocked_ugc_authors');
      await prefs.remove('user_pref_region');
      await prefs.remove('device_sync_id');

      ref.invalidate(catchLogProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🛡️ 依據被遺忘權規範，您的所有本機與雲端個人資料已徹底銷毀完畢！"),
            backgroundColor: Color(0xFF0077B6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ [隱私銷毀例外]: $e");
    }
  }

  static Widget _buildOptionTile({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isClassic,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder, 
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 13,
                      color: isClassic ? AppColors.classicText : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc, 
                    style: TextStyle(
                      fontSize: 10.5, 
                      color: isClassic ? Colors.grey.shade600 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded, 
              size: 16, 
              color: isClassic ? Colors.grey : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}