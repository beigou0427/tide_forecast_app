import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/catch_log_provider.dart';
import '../data/catch_log_model.dart';
import '../../tide/providers/tide_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/review_service.dart';

/// Kevin Systrom 視覺展覽館重塑：黑金/白藍雙軌標本展覽館 + 一鍵大物戰報分享
class CatchLogPage extends ConsumerWidget {
  const CatchLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClassic = ref.watch(isClassicThemeProvider);
    final logs = ref.watch(catchLogProvider);
    final tideView = ref.watch(tideViewDataProvider).value;

    final Color bgColor = isClassic ? AppColors.classicBg : AppColors.abyssBlack;
    final Color appBarBg = isClassic ? const Color(0xFF0077B6) : AppColors.abyssBlack.withValues(alpha: 0.88);
    final Color fabBg = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;
    final Color fabFg = isClassic ? Colors.white : AppColors.abyssBlack;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "潮汐漁獲榮譽日誌", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white, letterSpacing: -0.4),
        ),
        backgroundColor: appBarBg,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: isClassic ? 1 : 0,
      ),
      body: logs.isEmpty 
          ? _buildEmptyState(context, ref, tideView, isClassic) 
          : _buildLogList(context, ref, logs, tideView, isClassic),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddDialog(context, ref, tideView, isClassic);
        },
        backgroundColor: fabBg,
        foregroundColor: fabFg,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
        label: const Text("記錄今日大物", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, dynamic tideView, bool isClassic) {
    final Color primaryColor = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;
    final Color titleColor = isClassic ? AppColors.classicText : AppColors.textPrimary;
    final Color descColor = isClassic ? Colors.grey.shade600 : AppColors.textSecondary;

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
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.25), 
                  width: 0.5,
                ),
              ),
              child: Icon(Icons.phishing_rounded, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              "尚未建立作釣標本日誌", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: titleColor),
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
                _showAddDialog(context, ref, tideView, isClassic);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, 
                foregroundColor: isClassic ? Colors.white : AppColors.abyssBlack,
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

  Widget _buildLogList(BuildContext context, WidgetRef ref, List<CatchLogItem> logs, dynamic tideView, bool isClassic) {
    final Color stationColor = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;
    final Color titleColor = isClassic ? AppColors.classicText : AppColors.textPrimary;
    final Color noteColor = isClassic ? Colors.blueGrey.shade700 : AppColors.textSecondary;
    final Color timeColor = isClassic ? Colors.grey : AppColors.textTertiary;

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
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.hazardCoral.withValues(alpha: 0.8),
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
                          // 🌟 Kevin Systrom 大物加冕金標 (Trophy Recognition)
                          if (isTrophy) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.bioGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.bioGold.withValues(alpha: 0.4), width: 0.5),
                              ),
                              child: const Text("👑 大物認證", style: TextStyle(color: AppColors.bioGold, fontSize: 9, fontWeight: FontWeight.w900)),
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
                          color: isClassic ? Colors.grey.shade200 : AppColors.glassBorder, 
                          width: 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: item.imagePath != null
                            ? Image.file(
                                File(item.imagePath!),
                                height: 190,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildCloudImage(item.imageUrl, isClassic),
                              )
                            : _buildCloudImage(item.imageUrl, isClassic),
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
                          // 🌟 Kevin Systrom 一鍵戰績社交炫耀分享鈕
                          IconButton(
                            icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.bioGold),
                            tooltip: "分享此大物戰績至 LINE / 社群",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _shareCatchRecord(item),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(
                              5,
                              (starIdx) => Icon(
                                starIdx < item.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 16,
                                color: starIdx < item.rating 
                                    ? AppColors.bioGold 
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
                      if (item.tideHeight != null) _buildMetricBadge("潮位", "${item.tideHeight} m", isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan),
                      if (item.waveHeight != null) _buildMetricBadge("浪高", "${item.waveHeight} m", Colors.indigoAccent),
                      if (item.seaTemperature != null) _buildMetricBadge("水溫", "${item.seaTemperature} ℃", const Color(0xFFFF9500)),
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

  // 🌟 Kevin Systrom 社交炫耀戰報格式化生成
  Future<void> _shareCatchRecord(CatchLogItem item) async {
    HapticFeedback.lightImpact();
    final String timeStr = DateFormat('yyyy/MM/dd HH:mm').format(item.dateTime);
    final String metrics = [
      if (item.tideHeight != null) "潮位 ${item.tideHeight}m",
      if (item.waveHeight != null) "浪高 ${item.waveHeight}m",
      if (item.seaTemperature != null) "海溫 ${item.seaTemperature}℃",
    ].join(" · ");

    final String shareText = """🎣【老船長大物捕獲戰報】
🐟 戰利品：${item.species}
📍 釣點標本：${item.stationName}
⏰ 捕獲時間：$timeStr
🌊 實測水文：${metrics.isNotEmpty ? metrics : '官方即時水文監測'}
📝 作釣心得：${item.notes.isNotEmpty ? item.notes : '水流暢通，精準咬口！'}

📲 全台 85 測站光纖實況雷達：
👉 https://beigou0427.github.io/tide_forecast_app/
""";

    if (item.imagePath != null && File(item.imagePath!).existsSync()) {
      await Share.shareXFiles([XFile(item.imagePath!)], text: shareText);
    } else {
      await Share.share(shareText);
    }
  }

  Widget _buildCloudImage(String? url, bool isClassic) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 120, 
        color: isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.03),
        child: Center(
          child: Icon(Icons.broken_image_rounded, color: isClassic ? Colors.grey : AppColors.textTertiary, size: 36),
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
        color: isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.03),
        child: Center(
          child: CircularProgressIndicator(color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 120, 
        color: isClassic ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.03),
        child: Center(
          child: Icon(Icons.cloud_off_rounded, color: isClassic ? Colors.grey : AppColors.textTertiary, size: 36),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        "$label $val", 
        style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, dynamic tideView, bool isClassic) {
    final speciesCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    int selectedRating = 5;
    final ImagePicker picker = ImagePicker();
    XFile? selectedImage;

    final obs = tideView?.stationData.observations.isNotEmpty == true ? tideView.stationData.observations.last : null;
    final stationName = tideView?.stationData.info.stationName ?? "當前測站";

    final Color sheetBg = isClassic ? Colors.white : AppColors.abyssCard;
    final Color primaryColor = isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan;
    final Color textColor = isClassic ? AppColors.classicText : AppColors.textPrimary;
    final Color inputBg = isClassic ? Colors.grey.shade50 : Colors.white.withValues(alpha: 0.05);
    final Color borderColor = isClassic ? Colors.grey.shade300 : AppColors.glassBorder;

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
                          color: isClassic ? Colors.grey.shade300 : Colors.white24, 
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
                            color: primaryColor.withValues(alpha: 0.12), 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 0.5),
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
                              border: Border.all(color: borderColor, width: 0.5),
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
                                side: BorderSide(color: borderColor, width: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                if (img != null) setModalState(() => selectedImage = img);
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
                                side: BorderSide(color: borderColor, width: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                if (img != null) setModalState(() => selectedImage = img);
                              },
                              icon: Icon(Icons.photo_library_rounded, color: primaryColor, size: 18),
                              label: Text("相簿挑選", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: speciesCtrl,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: "對象魚種 / 體型 (必填)",
                        labelStyle: TextStyle(color: isClassic ? Colors.grey : AppColors.textTertiary, fontSize: 12),
                        hintText: "例如: 黑毛 42cm / 軟絲 1.5kg",
                        hintStyle: TextStyle(color: isClassic ? Colors.grey : AppColors.textTertiary, fontSize: 12),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 0.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.0)),
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
                        labelStyle: TextStyle(color: isClassic ? Colors.grey : AppColors.textTertiary, fontSize: 12),
                        hintText: "例如: 滿潮返乾時大咬，青磺蝦掛阿波1.5號",
                        hintStyle: TextStyle(color: isClassic ? Colors.grey : AppColors.textTertiary, fontSize: 12),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 0.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.0)),
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
                            color: isClassic ? Colors.blueGrey.shade800 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(5, (idx) {
                            return IconButton(
                              icon: Icon(
                                idx < selectedRating ? Icons.star_rounded : Icons.star_border_rounded, 
                                color: idx < selectedRating 
                                    ? AppColors.bioGold 
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
                          foregroundColor: isClassic ? Colors.white : AppColors.abyssBlack,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final species = speciesCtrl.text.trim();
                          if (species.isEmpty) {
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
                              debugPrint("⚠️ 照片沙盒轉移失敗，回退使用原始路徑: $e");
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

                          ref.read(catchLogProvider.notifier).addLog(item);

                          if (ctx.mounted) Navigator.pop(ctx);

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
