import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/catch_log_provider.dart';
import '../data/catch_log_model.dart';
import '../../tide/providers/tide_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/review_service.dart';
import '../../premium/services/premium_service.dart';
// 🌟 編譯黑洞修復：補齊路由與常數依賴
import '../../premium/presentation/premium_page.dart';
import '../../../core/utils/constants.dart';

/// 🌟 Alex Hormozi ($100M Leads) 病毒裂變與新鄉重夫防呆日誌引擎
/// 100% 實機防禦版：
/// 1. 【增長駭客】全螢幕傳奇大物認證彈窗 (Trophy Unlocked Modal)，極大化病毒分享率！
/// 2. 【信任防衛與轉單】免費雲端容量滿載警報！阻止沉默資料遺失，轉化為 PRO 訂閱印鈔機！
class CatchLogPage extends ConsumerWidget {
  const CatchLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;
    final bool isDark = themeMode == AppThemeMode.darkAbyss;

    final logs = ref.watch(catchLogProvider);
    final tideView = ref.watch(tideViewDataProvider).value;
    final premium = ref.watch(premiumProvider);

    final Color bgColor = isEInk 
        ? Colors.white 
        : (isClassic ? AppColors.classicBg : AppColors.abyssBlack);
    final Color appBarBg = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.abyssBlack.withValues(alpha: 0.88));
    final Color fabBg = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color fabFg = isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssBlack);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "潮汐漁獲榮譽日誌", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white, letterSpacing: -0.4),
        ),
        backgroundColor: appBarBg,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: isClassic ? 1 : 0,
      ),
      body: logs.isEmpty 
          ? _buildEmptyState(context, ref, tideView, isClassic, isEInk) 
          : _buildLogList(context, ref, logs, isClassic, isEInk, isDark, premium),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddDialog(context, ref, tideView, isClassic, isEInk);
        },
        backgroundColor: fabBg,
        foregroundColor: fabFg,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
        label: const Text("登錄今日大物", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, TideViewData? tideView, bool isClassic, bool isEInk) {
    final Color primaryColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color titleColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color descColor = isEInk 
        ? Colors.black87 
        : (isClassic ? Colors.grey.shade600 : AppColors.textSecondary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isEInk ? Colors.black.withValues(alpha: 0.08) : primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEInk ? Colors.black : primaryColor.withValues(alpha: 0.25), 
                  width: isEInk ? 1.5 : 0.5,
                ),
              ),
              child: Icon(Icons.phishing_rounded, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              "尚未建立作釣標本日誌", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: titleColor),
            ),
            const SizedBox(height: 8),
            Text(
              "拍下戰利品，每筆紀錄將自動疊加當下即時水文\n並永久備份至本機與雲端金庫，留下不朽傳奇！",
              textAlign: TextAlign.center, 
              style: TextStyle(color: descColor, fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddDialog(context, ref, tideView, isClassic, isEInk);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, 
                foregroundColor: isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssBlack),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_a_photo_rounded, size: 16),
              label: const Text("新增第一筆大物紀錄", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(
    BuildContext context, 
    WidgetRef ref, 
    List<CatchLogItem> logs, 
    bool isClassic, 
    bool isEInk,
    bool isDark,
    PremiumState premium,
  ) {
    final Color stationColor = isEInk 
        ? Colors.black 
        : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color titleColor = isEInk 
        ? Colors.black 
        : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color noteColor = isEInk 
        ? Colors.black87 
        : (isClassic ? Colors.blueGrey.shade700 : AppColors.textSecondary);
    final Color timeColor = isEInk 
        ? Colors.black54 
        : (isClassic ? Colors.grey : AppColors.textTertiary);

    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final item = logs[index];
        final timeStr = DateFormat('yyyy/MM/dd HH:mm').format(item.dateTime);
        final bool isTrophy = item.rating >= 5;

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssCard),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isEInk ? Colors.black : AppColors.hazardCoral, width: isEInk ? 1.5 : 0.8),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: isEInk ? Colors.black : AppColors.hazardCoral, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "確認刪除戰報？",
                      style: TextStyle(
                        color: isEInk ? Colors.black : (isClassic ? AppColors.classicText : Colors.white), 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "確定要刪除【${item.species}】紀錄嗎？\n本機與雲端備份照片將同步被永久抹除，此動作無法復原！",
                  style: TextStyle(
                    color: isEInk ? Colors.black87 : (isClassic ? Colors.blueGrey.shade700 : AppColors.textSecondary),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text("保留", style: TextStyle(color: isEInk ? Colors.black54 : AppColors.textTertiary, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEInk ? Colors.black : AppColors.hazardCoral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("確認刪除", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: isEInk ? Colors.black : AppColors.hazardCoral.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
          ),
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            ref.read(catchLogProvider.notifier).deleteLog(item.id);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 13, color: stationColor),
                          const SizedBox(width: 4),
                          Text(
                            item.stationName, 
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: stationColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (isTrophy) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isEInk ? Colors.black : AppColors.bioGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isEInk ? Colors.black : AppColors.bioGold.withValues(alpha: 0.4), 
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                "👑 大物認證", 
                                style: TextStyle(
                                  color: isEInk ? Colors.white : AppColors.bioGold, 
                                  fontSize: 9, 
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (item.imageUrl != null) const Icon(Icons.cloud_done_rounded, size: 12, color: Color(0xFF30D158)),
                          const SizedBox(width: 4),
                          Text(timeStr, style: TextStyle(fontSize: 11, color: timeColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  if (item.imagePath != null || item.imageUrl != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEInk ? Colors.black : (isClassic ? Colors.grey.shade200 : AppColors.glassBorder), 
                          width: isEInk ? 1.5 : 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: item.imagePath != null && File(item.imagePath!).existsSync()
                            ? Image.file(
                                File(item.imagePath!),
                                height: 190,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildCloudImage(item.imageUrl, isClassic, isEInk),
                              )
                            : _buildCloudImage(item.imageUrl, isClassic, isEInk),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.species, 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: titleColor, letterSpacing: -0.3),
                        ),
                      ),
                      Row(
                        children: [
                          Builder(
                            builder: (shareBtnContext) {
                              return IconButton(
                                icon: Icon(Icons.ios_share_rounded, size: 18, color: isEInk ? Colors.black : AppColors.bioGold),
                                tooltip: "分享賺取老船長代幣",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _shareCatchRecord(item, shareBtnContext, ref),
                              );
                            }
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(
                              5,
                              (starIdx) => Icon(
                                starIdx < item.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 16,
                                color: starIdx < item.rating 
                                    ? (isEInk ? Colors.black : AppColors.bioGold) 
                                    : (isClassic ? Colors.grey.shade300 : AppColors.textTertiary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.notes, 
                      style: TextStyle(color: noteColor, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.tideHeight != null) _buildMetricBadge("潮位", "${item.tideHeight} m", isEInk ? Colors.black : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan), isEInk),
                      if (item.waveHeight != null) _buildMetricBadge("浪高", "${item.waveHeight} m", isEInk ? Colors.black : Colors.indigoAccent, isEInk),
                      if (item.seaTemperature != null) _buildMetricBadge("水溫", "${item.seaTemperature} ℃", isEInk ? Colors.black : const Color(0xFFFF9500), isEInk),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareCatchRecord(CatchLogItem item, BuildContext btnContext, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    Rect? shareOrigin;
    try {
      final box = btnContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final origin = box.localToGlobal(Offset.zero);
        shareOrigin = Rect.fromCenter(
          center: origin + Offset(box.size.width / 2, box.size.height / 2),
          width: 20,
          height: 20,
        );
      }
    } catch (_) {}

    final String timeStr = DateFormat('yyyy/MM/dd HH:mm').format(item.dateTime);
    final String metrics = [
      if (item.tideHeight != null) "潮位 ${item.tideHeight}m",
      if (item.waveHeight != null) "浪高 ${item.waveHeight}m",
      if (item.seaTemperature != null) "海溫 ${item.seaTemperature}℃",
    ].join(" · ");

    final premium = ref.read(premiumProvider);
    String identityHeader = "🎣【老船長大物捕獲戰報】";
    if (premium.isFounder) {
      identityHeader = "👑【老船長創始天尊 · 五星大物榮譽戰報】";
    } else if (premium.type == SubscriptionType.yearly) {
      identityHeader = "🔱【老船長年度首席領航員 · 五星大物戰報】";
    } else if (premium.isPremium) {
      identityHeader = "⭐【老船長 VIP 專業航海家 · 五星大物戰報】";
    }

    final match = RegExp(r'[\(（]([A-Za-z0-9]+)[\)）]').firstMatch(item.stationName);
    final String sid = match != null ? match.group(1)! : "C6AH2";
    final String deepLink = "https://beigou0427.github.io/tide_forecast_app/?sid=$sid";

    final String shareText = """$identityHeader
🐟 戰利品：${item.species}
📍 釣點標本：${item.stationName}
⏰ 捕獲時間：$timeStr
🌊 官方實測水文：${metrics.isNotEmpty ? metrics : '中央氣象署光纖直連'}

⚡ 官方認證：氣象署 85 測站光纖直連 · 滿退 2 分水大咬推算
📲 免費查看全台 85 站光纖實況雷達：
👉 $deepLink
""";

    try {
      ShareResult? result;
      if (item.imagePath != null && File(item.imagePath!).existsSync()) {
        result = await Share.shareXFiles(
          [XFile(item.imagePath!)], 
          text: shareText,
          sharePositionOrigin: shareOrigin,
        );
      } else {
        result = await Share.share(
          shareText,
          sharePositionOrigin: shareOrigin,
        );
      }

      if (result.status == ShareResultStatus.success || result.status == ShareResultStatus.unavailable) {
        final prefs = await SharedPreferences.getInstance();
        final lastShareEpoch = prefs.getInt('last_viral_share_epoch') ?? 0;
        final nowEpoch = DateTime.now().millisecondsSinceEpoch;
        
        if (nowEpoch - lastShareEpoch > const Duration(hours: 12).inMilliseconds) {
          await prefs.setInt('last_viral_share_epoch', nowEpoch);
          await ref.read(premiumProvider.notifier).addCoins(10);
          
          if (btnContext.mounted) {
            ScaffoldMessenger.of(btnContext).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: AppColors.bioGold, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "🎉 戰報分享成功！已發放 10 枚老船長代幣作為聯盟推廣獎勵！", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFF0C1624),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ 分享喚起異常: $e");
    }
  }

  Widget _buildCloudImage(String? url, bool isClassic, bool isEInk) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 120, 
        color: isEInk ? Colors.grey.shade100 : (isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.03)),
        child: Center(
          child: Icon(Icons.broken_image_rounded, color: isEInk ? Colors.black : (isClassic ? Colors.grey : AppColors.textTertiary), size: 36),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 190, 
        color: isEInk ? Colors.grey.shade100 : (isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.03)),
        child: Center(
          child: CircularProgressIndicator(color: isEInk ? Colors.black : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan), strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 120, 
        color: isEInk ? Colors.grey.shade100 : (isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.03)),
        child: Center(
          child: Icon(Icons.cloud_off_rounded, color: isEInk ? Colors.black : (isClassic ? Colors.grey : AppColors.textTertiary), size: 36),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(String label, String val, Color color, bool isEInk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isEInk ? Colors.black.withValues(alpha: 0.08) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isEInk ? Colors.black : color.withValues(alpha: 0.3), width: isEInk ? 1.0 : 0.5),
      ),
      child: Text(
        "$label $val", 
        style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  // 🌟 增長駭客核心：全螢幕傳奇大物認證彈窗
  void _showTrophyUnlockedDialog(BuildContext context, CatchLogItem item, WidgetRef ref) {
    final themeMode = ref.read(themeModeProvider);
    final bool isEInk = themeMode == AppThemeMode.eInkHighContrast;
    final bool isClassic = themeMode == AppThemeMode.classicLight;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssCard),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.bioGold, width: isEInk ? 2.0 : 1.5),
        ),
        title: const Column(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppColors.bioGold, size: 48),
            SizedBox(height: 12),
            Text("👑 傳奇大物認證！", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        content: Text(
          "恭喜您在【${item.stationName}】擒獲五星級【${item.species}】！\n\n系統已自動為本戰報疊加「氣象署光纖水文數據」與「榮譽鋼印」。這份完美的戰果不該被隱藏，立刻向釣魚群組展示您的航海家實力吧！",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5, 
            height: 1.5, 
            color: isEInk ? Colors.black87 : (isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06C755), 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text("一鍵發布至 LINE 群組", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _shareCatchRecord(item, context, ref);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("低調收藏", style: TextStyle(color: Colors.grey)),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, TideViewData? tideView, bool isClassic, bool isEInk) {
    final speciesCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    int selectedRating = 5;
    final ImagePicker picker = ImagePicker();
    XFile? selectedImage;

    final obs = (tideView != null && tideView.stationData.observations.isNotEmpty) 
        ? tideView.stationData.observations.last 
        : null;
    final stationName = tideView?.stationData.info.stationName ?? "當前測站";

    final Color sheetBg = isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssCard);
    final Color primaryColor = isEInk ? Colors.black : (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan);
    final Color textColor = isEInk ? Colors.black : (isClassic ? AppColors.classicText : AppColors.textPrimary);
    final Color inputBg = isEInk ? Colors.grey.shade100 : (isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.05));
    final Color borderColor = isEInk ? Colors.black : (isClassic ? Colors.grey.shade300 : AppColors.glassBorder);

    const quickSpecies = ['黑毛', '白毛', '軟絲', '煙仔虎', '紅甘', '石斑'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36, 
                        height: 4, 
                        decoration: BoxDecoration(
                          color: isEInk ? Colors.black26 : (isClassic ? Colors.grey.shade300 : Colors.white24), 
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "登錄作釣漁獲日誌", 
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.3),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isEInk ? Colors.black.withValues(alpha: 0.08) : primaryColor.withValues(alpha: 0.12), 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isEInk ? Colors.black : primaryColor.withValues(alpha: 0.25), width: 0.5),
                          ),
                          child: Text(
                            "鎖定: $stationName", 
                            style: TextStyle(fontSize: 10.5, color: primaryColor, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (selectedImage != null)
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: isEInk ? 1.5 : 0.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(selectedImage!.path), height: 160, width: double.infinity, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setModalState(() => selectedImage = null);
                              },
                              child: const CircleAvatar(
                                backgroundColor: Colors.black54, 
                                radius: 14, 
                                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: inputBg,
                                side: BorderSide(color: borderColor, width: isEInk ? 1.5 : 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                try {
                                  final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                  if (img != null) setModalState(() => selectedImage = img);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("請至手機「設定」允許相機權限以拍攝魚獲"), behavior: SnackBarBehavior.floating),
                                  );
                                }
                              },
                              icon: Icon(Icons.camera_alt_rounded, color: primaryColor, size: 18),
                              label: Text("現場拍攝", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: inputBg,
                                side: BorderSide(color: borderColor, width: isEInk ? 1.5 : 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                try {
                                  final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                  if (img != null) setModalState(() => selectedImage = img);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("請至手機「設定」允許照片存取權限以挑選照片"), behavior: SnackBarBehavior.floating),
                                  );
                                }
                              },
                              icon: Icon(Icons.photo_library_rounded, color: primaryColor, size: 18),
                              label: Text("相簿挑選", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickSpecies.map((s) => ActionChip(
                        label: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                        backgroundColor: isEInk ? Colors.black.withValues(alpha: 0.05) : primaryColor.withValues(alpha: 0.1),
                        side: BorderSide(color: isEInk ? Colors.black : primaryColor.withValues(alpha: 0.3), width: 0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          speciesCtrl.text = s;
                          speciesCtrl.selection = TextSelection.fromPosition(TextPosition(offset: speciesCtrl.text.length));
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: speciesCtrl,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: "對象魚種 / 體型 (必填)",
                        labelStyle: TextStyle(color: isEInk ? Colors.black54 : (isClassic ? Colors.grey : AppColors.textTertiary), fontSize: 12),
                        hintText: "例如: 黑毛 42cm / 軟絲 1.5kg",
                        hintStyle: TextStyle(color: isEInk ? Colors.black38 : (isClassic ? Colors.grey : AppColors.textTertiary), fontSize: 12),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: isEInk ? 1.5 : 0.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: isEInk ? 1.5 : 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: isEInk ? 2.0 : 1.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: "作釣心得 / 使用餌料 (選填)",
                        labelStyle: TextStyle(color: isEInk ? Colors.black54 : (isClassic ? Colors.grey : AppColors.textTertiary), fontSize: 12),
                        hintText: "例如: 滿潮返乾時大咬，青磺蝦掛阿波1.5號",
                        hintStyle: TextStyle(color: isEInk ? Colors.black38 : (isClassic ? Colors.grey : AppColors.textTertiary), fontSize: 12),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: isEInk ? 1.5 : 0.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: isEInk ? 1.5 : 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: isEInk ? 2.0 : 1.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          "咬度評價: ", 
                          style: TextStyle(
                            fontWeight: FontWeight.w700, 
                            fontSize: 13, 
                            color: isEInk ? Colors.black : (isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(5, (idx) {
                            return IconButton(
                              icon: Icon(
                                idx < selectedRating ? Icons.star_rounded : Icons.star_border_rounded, 
                                color: idx < selectedRating 
                                    ? (isEInk ? Colors.black : AppColors.bioGold) 
                                    : (isClassic ? Colors.grey.shade300 : AppColors.textTertiary),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setModalState(() => selectedRating = idx + 1);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isEInk ? Colors.white : (isClassic ? Colors.white : AppColors.abyssBlack),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final species = speciesCtrl.text.trim();
                          if (species.isEmpty) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請填寫對象魚種")));
                            return;
                          }

                          HapticFeedback.mediumImpact();

                          String? permanentPath;
                          if (selectedImage != null) {
                            try {
                              final appDir = await getApplicationDocumentsDirectory();
                              final fileName = "${DateTime.now().millisecondsSinceEpoch}_catch.jpg";
                              final savedFile = await File(selectedImage!.path).copy('${appDir.path}/$fileName');
                              permanentPath = savedFile.path;
                            } catch (e) {
                              permanentPath = selectedImage!.path;
                            }
                          }

                          final item = CatchLogItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            dateTime: DateTime.now(),
                            stationName: stationName,
                            species: species,
                            tideHeight: obs?.tideHeight,
                            waveHeight: obs?.waveHeight,
                            seaTemperature: obs?.seaTemperature,
                            notes: notesCtrl.text.trim(),
                            rating: selectedRating,
                            imagePath: permanentPath,
                          );

                          // 🌟 PM 核心防線：容量偵測器 (Quota Monitor) 與恐懼行銷轉單漏斗
                          final bool isPro = ref.read(premiumProvider).isPremium || ref.read(premiumProvider).isFounder;
                          final int currentCloudPhotos = ref.read(catchLogProvider).where((e) => e.imageUrl != null || e.imagePath != null).length;
                          final bool isStorageFull = !isPro && currentCloudPhotos >= AppConstants.maxFreeCloudCatchLogs;

                          ref.read(catchLogProvider.notifier).addLog(item);
                          if (ctx.mounted) Navigator.pop(ctx);

                          if (isStorageFull && selectedImage != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("⚠️ 免費雲端容量已滿 (5/5)！照片僅存於本機。落海將永久遺失，請升級 PRO 解鎖無限雲端金庫！"),
                                backgroundColor: AppColors.hazardCoral,
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: "解鎖金庫",
                                  textColor: Colors.white,
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage())),
                                ),
                              ),
                            );
                          } else if (selectedRating >= 5 && context.mounted) {
                            _showTrophyUnlockedDialog(context, item, ref);
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ 漁獲日誌已成功保存並疊加水文資料！"),
                                backgroundColor: Colors.blueGrey,
                                duration: Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }

                          ReviewService.onCatchLogSaved(selectedRating);
                        },
                        child: const Text("保存並疊加即時水文", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
