import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/catch_log_provider.dart';
import '../data/catch_log_model.dart';
import '../../tide/providers/tide_provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../core/services/review_service.dart'; // 🌟 引入 Google 級 ASO 評分飛輪

class CatchLogPage extends ConsumerWidget {
  const CatchLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(catchLogProvider);
    final tideView = ref.watch(tideViewDataProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("潮汐漁獲日誌", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: logs.isEmpty ? _buildEmptyState(context, ref, tideView) : _buildLogList(context, ref, logs, tideView),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref, tideView),
        backgroundColor: const Color(0xFF0077B6),
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text("記錄今日作釣", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Icon(Icons.phishing_rounded, size: 80, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            const Text("尚未建立任何作釣日誌", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text("拍攝戰利品，每筆日誌將自動疊加當下測站之浪高、潮位與水溫，並自動備份至雲端金庫！",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, ref, tideView),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              label: const Text("新增第一筆拍照紀錄", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(BuildContext context, WidgetRef ref, List<CatchLogItem> logs, dynamic tideView) {
    return ListView.builder(
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
            padding: const EdgeInsets.only(right: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => ref.read(catchLogProvider.notifier).deleteLog(item.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF0077B6)),
                          const SizedBox(width: 4),
                          Text(item.stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0077B6))),
                        ],
                      ),
                      Row(
                        children: [
                          if (item.imageUrl != null) const Icon(Icons.cloud_done_outlined, size: 12, color: Colors.teal),
                          if (item.imageUrl != null) const SizedBox(width: 4),
                          Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (item.imagePath != null || item.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.imagePath != null
                          ? Image.file(
                              File(item.imagePath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => _buildCloudImage(item.imageUrl),
                            )
                          : _buildCloudImage(item.imageUrl),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: Text(item.species, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (starIdx) => Icon(
                            starIdx < item.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.notes, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.tideHeight != null) _buildMetricBadge("潮位", "${item.tideHeight} m", Colors.blue),
                      if (item.waveHeight != null) _buildMetricBadge("浪高", "${item.waveHeight} m", Colors.indigo),
                      if (item.seaTemperature != null) _buildMetricBadge("水溫", "${item.seaTemperature} ℃", Colors.orange),
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
        height: 100, color: Colors.grey.shade100,
        child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 36)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 180, color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF0077B6))),
      ),
      errorWidget: (context, url, error) => Container(
        height: 100, color: Colors.grey.shade100,
        child: Center(child: Icon(Icons.cloud_off_rounded, color: Colors.grey.shade400, size: 36)),
      ),
    );
  }

  Widget _buildMetricBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text("$label $val", style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("新增作釣漁獲日誌", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF0077B6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text("鎖定: $stationName", style: const TextStyle(fontSize: 11, color: Color(0xFF0077B6), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(selectedImage!.path), height: 160, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: InkWell(
                              onTap: () => setModalState(() => selectedImage = null),
                              child: const CircleAvatar(backgroundColor: Colors.black54, radius: 14, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            )
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
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                if (img != null) setModalState(() => selectedImage = img);
                              },
                              icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0077B6)),
                              label: const Text("現場拍攝", style: TextStyle(color: Color(0xFF0077B6), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1200, maxHeight: 1200);
                                if (img != null) setModalState(() => selectedImage = img);
                              },
                              icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF0077B6)),
                              label: const Text("相簿挑選", style: TextStyle(color: Color(0xFF0077B6), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: speciesCtrl,
                      decoration: InputDecoration(
                        labelText: "對象魚種 / 體型 (必填)",
                        hintText: "例如: 黑毛 42cm / 軟絲 1.5kg",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "作釣心得 / 使用餌料 (選填)",
                        hintText: "例如: 滿潮返乾時大咬，青磺蝦掛阿波1.5號",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text("咬度評價: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          children: List.generate(5, (idx) {
                            return IconButton(
                              icon: Icon(idx < selectedRating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber),
                              onPressed: () => setModalState(() => selectedRating = idx + 1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final species = speciesCtrl.text.trim();
                          if (species.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請填寫對象魚種")));
                            return;
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
                            imagePath: selectedImage?.path,
                          );

                          ref.read(catchLogProvider.notifier).addLog(item);
                          Navigator.pop(ctx);

                          // 🌟 Google CMO 高潮觸發原則：剛釣到 4~5 星大魚並保存，多巴胺正濃時發起好評邀請！
                          ReviewService.onCatchLogSaved(selectedRating);
                        },
                        child: const Text("保存並疊加即時海象", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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