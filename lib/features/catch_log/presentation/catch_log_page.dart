import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/catch_log_provider.dart';
import '../data/catch_log_model.dart';
import '../../tide/providers/tide_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/review_service.dart';

/// 🍏 Apple 首席設計工藝：黑金標本展覽館 (Catch Archive Gallery)
class CatchLogPage extends ConsumerWidget {
  const CatchLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(catchLogProvider);
    final tideView = ref.watch(tideViewDataProvider).value;

    return Scaffold(
      backgroundColor: AppColors.abyssBlack,
      appBar: AppBar(
        title: const Text(
          "潮汐漁獲榮譽日誌", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary, letterSpacing: -0.4),
        ),
        backgroundColor: AppColors.abyssBlack.withValues(alpha: 0.88),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: logs.isEmpty 
          ? _buildEmptyState(context, ref, tideView) 
          : _buildLogList(context, ref, logs, tideView),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddDialog(context, ref, tideView);
        },
        backgroundColor: AppColors.pelagicCyan,
        foregroundColor: AppColors.abyssBlack,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
        label: const Text("記錄今日作釣", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, dynamic tideView) {
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
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: const Icon(Icons.phishing_rounded, size: 40, color: AppColors.pelagicCyan),
            ),
            const SizedBox(height: 20),
            const Text(
              "尚未建立作釣日誌", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "拍下戰利品，每筆紀錄將自動疊加當下即時水文\n並永久備份至本機與雲端金庫，留下不朽傳奇！",
              textAlign: TextAlign.center, 
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddDialog(context, ref, tideView);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pelagicCyan, 
                foregroundColor: AppColors.abyssBlack,
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

  Widget _buildLogList(BuildContext context, WidgetRef ref, List<CatchLogItem> logs, dynamic tideView) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final item = logs[index];
        final timeStr = DateFormat('yyyy/MM/dd HH:mm').format(item.dateTime);

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
                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.pelagicCyan),
                          const SizedBox(width: 4),
                          Text(
                            item.stationName, 
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.pelagicCyan),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (item.imageUrl != null) const Icon(Icons.cloud_done_rounded, size: 12, color: Color(0xFF30D158)),
                          if (item.imageUrl != null) const SizedBox(width: 4),
                          Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // 藍寶石展覽相框
                  if (item.imagePath != null || item.imageUrl != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder, width: 0.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: item.imagePath != null
                            ? Image.file(
                                File(item.imagePath!),
                                height: 190,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildCloudImage(item.imageUrl),
                              )
                            : _buildCloudImage(item.imageUrl),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.species, 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.3),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (starIdx) => Icon(
                            starIdx < item.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 16,
                            color: starIdx < item.rating ? AppColors.bioGold : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.notes, 
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.tideHeight != null) _buildMetricBadge("潮位", "${item.tideHeight} m", AppColors.pelagicCyan),
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

  Widget _buildCloudImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 120, 
        color: Colors.white.withValues(alpha: 0.03),
        child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textTertiary, size: 36)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 190, 
        color: Colors.white.withValues(alpha: 0.03),
        child: const Center(child: CircularProgressIndicator(color: AppColors.pelagicCyan, strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        height: 120, 
        color: Colors.white.withValues(alpha: 0.03),
        child: const Center(child: Icon(Icons.cloud_off_rounded, color: AppColors.textTertiary, size: 36)),
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

  void _showAddDialog(BuildContext context, WidgetRef ref, dynamic tideView) {
    final speciesCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    int selectedRating = 5;
    final ImagePicker picker = ImagePicker();
    XFile? selectedImage;

    final obs = tideView?.stationData.observations.isNotEmpty == true ? tideView.stationData.observations.last : null;
    final stationName = tideView?.stationData.info.stationName ?? "當前測站";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.abyssCard,
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
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "登錄作釣漁獲日誌", 
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.3),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.pelagicCyan.withValues(alpha: 0.12), 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.pelagicCyan.withValues(alpha: 0.25), width: 0.5),
                          ),
                          child: Text(
                            "鎖定: $stationName", 
                            style: const TextStyle(fontSize: 10.5, color: AppColors.pelagicCyan, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 照片捕捉展示區
                    if (selectedImage != null)
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.glassBorder, width: 0.5),
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
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                if (img != null) setModalState(() => selectedImage = img);
                              },
                              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.pelagicCyan, size: 18),
                              label: const Text("現場拍攝", style: TextStyle(color: AppColors.pelagicCyan, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                if (img != null) setModalState(() => selectedImage = img);
                              },
                              icon: const Icon(Icons.photo_library_rounded, color: AppColors.pelagicCyan, size: 18),
                              label: const Text("相簿挑選", style: TextStyle(color: AppColors.pelagicCyan, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: speciesCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: "對象魚種 / 體型 (必填)",
                        labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        hintText: "例如: 黑毛 42cm / 軟絲 1.5kg",
                        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.pelagicCyan, width: 1.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: "作釣心得 / 使用餌料 (選填)",
                        labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        hintText: "例如: 滿潮返乾時大咬，青磺蝦掛阿波1.5號",
                        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.pelagicCyan, width: 1.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text("咬度評價: ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(5, (idx) {
                            return IconButton(
                              icon: Icon(
                                idx < selectedRating ? Icons.star_rounded : Icons.star_border_rounded, 
                                color: idx < selectedRating ? AppColors.bioGold : AppColors.textTertiary,
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
                          backgroundColor: AppColors.pelagicCyan,
                          foregroundColor: AppColors.abyssBlack,
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

                          // 永久沙盒轉移 (防照片蒸發)
                          String? permanentPath;
                          if (selectedImage != null) {
                            try {
                              final appDir = await getApplicationDocumentsDirectory();
                              final fileName = "${DateTime.now().millisecondsSinceEpoch}_catch.jpg";
                              final savedFile = await File(selectedImage!.path).copy('${appDir.path}/$fileName');
                              permanentPath = savedFile.path;
                            } catch (e) {
                              debugPrint("⚠️ 照片沙盒永久轉移失敗，回退使用原始路徑: $e");
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

                          // 🌟 核心防護：檢查 ctx 是否依然掛載存活，徹底消除 use_build_context_synchronously 警告！
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

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