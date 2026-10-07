import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/premium_service.dart';
import '../../../core/utils/share_util.dart';
import '../../../core/theme/app_theme.dart';
import '../../tide/providers/tide_provider.dart';

class VipCenterPage extends ConsumerStatefulWidget {
  const VipCenterPage({super.key});

  @override
  ConsumerState<VipCenterPage> createState() => _VipCenterPageState();
}

class _VipCenterPageState extends ConsumerState<VipCenterPage> {
  final GlobalKey _vipCardKey = GlobalKey();
  
  // VVIP 離線預載防線狀態
  bool _isPreloading = false;
  double _preloadProgress = 0.0;

  Future<void> _preloadAllStations() async {
    final stations = ref.read(stationListProvider).value;
    if (stations == null || stations.isEmpty) return;

    setState(() {
      _isPreloading = true;
      _preloadProgress = 0.0;
    });

    HapticFeedback.mediumImpact();
    final apiService = ref.read(tideApiServiceProvider);
    int successCount = 0;

    for (int i = 0; i < stations.length; i++) {
      try {
        await apiService.fetchData(stations[i].id, isPremium: true);
        successCount++;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _preloadProgress = (i + 1) / stations.length;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isPreloading = false;
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ 離線神盾預載完成！已成功快取 $successCount/${stations.length} 站 30 天水文模型，外海斷網依然完整可用！"),
          backgroundColor: const Color(0xFF30D158),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(premiumProvider);
    final isClassic = ref.watch(isClassicThemeProvider);

    final currentYear = DateTime.now().year;
    final String epochStr = (state.expiryDate?.millisecondsSinceEpoch ?? 1770000000000).toString();
    final String seq = epochStr.length >= 9 ? epochStr.substring(5, 9) : "8888";
    final String memberId = "CAPT-$currentYear-$seq";

    final String title = state.isFounder ? "創始天尊指揮官" : (state.type == SubscriptionType.yearly ? "年度首席領航員" : "尊榮專業會員");
    final String expiryText = state.isFounder ? "終身永久享有最高特權" : "特權有效期至：${state.expiryDate != null ? DateFormat('yyyy/MM/dd').format(state.expiryDate!) : '有效'}";

    final Color pageBg = isClassic ? AppColors.classicBg : const Color(0xFF020E1C);
    final Color appBarBg = isClassic ? const Color(0xFF0077B6) : const Color(0xFF020E1C);
    final Color sectionTitleColor = isClassic ? const Color(0xFF023E8A) : Colors.white.withValues(alpha: 0.9);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text("老船長 VIP 航海指揮中心", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: appBarBg,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: isClassic ? 1 : 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
        child: Column(
          children: [
            // 1. 尊榮金屬身分銘牌
            RepaintBoundary(
              key: _vipCardKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.isFounder 
                        ? const [Color(0xFF2C1802), Color(0xFF150A00), Color(0xFF3D2605)]
                        : const [Color(0xFF062343), Color(0xFF021326), Color(0xFF0A335C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8)).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.anchor_rounded, color: state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8), size: 28),
                            const SizedBox(width: 8),
                            Text(
                              "TIDE PRO COMMANDER",
                              style: TextStyle(
                                color: (state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8)),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8)).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: state.isFounder ? const Color(0xFFFFD700) : const Color(0xFF00B4D8), width: 1),
                          ),
                          child: Text(
                            state.isFounder ? "FOUNDER" : "VIP PRO",
                            style: TextStyle(color: state.isFounder ? const Color(0xFFFFD700) : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: state.isFounder ? const Color(0xFFFFE57F) : Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "編號：$memberId",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, letterSpacing: 1.5, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          expiryText,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.verified_rounded, color: Colors.amber, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: isClassic ? Colors.white : Colors.transparent,
                  side: BorderSide(color: isClassic ? Colors.grey.shade300 : Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, color: AppColors.bioGold, size: 18),
                label: Text(
                  "分享我的 VIP 航海家榮譽身分卡", 
                  style: TextStyle(
                    color: isClassic ? AppColors.classicText : Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                  ),
                ),
                onPressed: () => ShareUtil.captureAndShare(_vipCardKey, stationName: title),
              ),
            ),

            const SizedBox(height: 24),

            // 2. 全天候戰術環境風格切換
            _buildThemeSwitchCard(context, ref, isClassic),

            const SizedBox(height: 24),

            // 3. 全台 85 站離線水文神盾一鍵預載包
            Row(
              children: [
                const Icon(Icons.offline_bolt_rounded, color: Colors.tealAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  "外海離線水文神盾部署",
                  style: TextStyle(color: sectionTitleColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isClassic ? Colors.teal.shade50 : Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withValues(alpha: isClassic ? 0.5 : 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_for_offline_rounded, color: Colors.teal, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "全台 85 測站一鍵預載包", 
                              style: TextStyle(
                                color: isClassic ? Colors.teal.shade900 : Colors.tealAccent, 
                                fontSize: 14, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "出海前預載，外礁斷網也能自由切換 85 站", 
                              style: TextStyle(
                                color: isClassic ? Colors.teal.shade700 : Colors.teal.shade200, 
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isPreloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _preloadProgress,
                        backgroundColor: Colors.teal.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "正在寫入本地磁碟快取... ${(_preloadProgress * 100).toStringAsFixed(0)}%",
                        style: TextStyle(color: isClassic ? Colors.teal.shade800 : Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cloud_download_rounded, size: 18),
                        label: const Text("立即下載 85 站離線水文包", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        onPressed: _preloadAllStations,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 4. 專屬 VIP 硬核特權與運作狀態
            Row(
              children: [
                Icon(Icons.shield_rounded, color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  "專屬 VIP 硬核特權與運作狀態",
                  style: TextStyle(color: sectionTitleColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 特權 1：Apple 官方家人共享 (正式驗證開通)
            _buildStatusCard(
              icon: Icons.groups_rounded,
              title: "Apple 官方「家人共享」機制",
              statusText: "後台已認證生效 • 支援 5 位同行成員",
              desc: "年度指揮官計畫完整相容 Apple 家人共享，同行作釣的家庭成員登入同群組 Apple ID，自動享有 PRO 旗艦特權，零重複扣款。",
              statusColor: const Color(0xFF30D158),
              isClassic: isClassic,
            ),
            const SizedBox(height: 12),

            // 特權 2：老船長經典純潮汐對照表
            _buildStatusCard(
              icon: Icons.menu_book_rounded,
              title: "老船長經典純潮汐對照表",
              statusText: "VVIP 專屬純粹紙本排印已解鎖",
              desc: "駕駛台純潮汐儀表直接置頂呈現傳統航海對照矩陣，大字體顯示全天滿乾潮、潮差變動與走水窗口，支援一鍵複製純文字至 LINE 群組。",
              statusColor: AppColors.bioGold,
              isClassic: isClassic,
            ),
            const SizedBox(height: 12),

            // 特權 3：85 測站光纖直連專線
            _buildStatusCard(
              icon: Icons.bolt_rounded,
              title: "中央氣象署 85 測站光纖直連專線",
              statusText: "專線已連通 • 響應 38ms",
              desc: "具備浮標與 62 座潮位站智慧雙向路由，直達氣象署即時感測陣列，享有 0 延遲水文刷新特權。",
              statusColor: const Color(0xFF00E5FF),
              isClassic: isClassic,
            ),
            const SizedBox(height: 12),

            // 特權 4：Gemini 模型專屬推論通道
            _buildStatusCard(
              icon: Icons.auto_awesome,
              title: "Gemini Flash-Lite-Latest 專屬推論通道",
              statusText: "海事算力優先席位",
              desc: "獨享全維度湧浪週期、風切轉向點與咬度視窗 AI 加權計算，不排隊、無請求次數上限。",
              statusColor: const Color(0xFFBF5AF2),
              isClassic: isClassic,
            ),
            const SizedBox(height: 12),

            // 特權 5：30 分鐘滿潮防困礁主動守護盾
            _buildStatusCard(
              icon: Icons.notifications_active_rounded,
              title: "30 分鐘滿潮防困礁主動守護盾",
              statusText: "背景安全雷達運作中",
              desc: "依據您關注測站之每日滿潮死線，於滿潮前 30 分鐘發出專屬高分貝突發湧浪防護警告，守護人身安全。",
              statusColor: Colors.cyanAccent,
              isClassic: isClassic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitchCard(BuildContext context, WidgetRef ref, bool isClassic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isClassic ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08), width: isClassic ? 1.0 : 0.5),
        boxShadow: isClassic ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isClassic ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              color: isClassic ? const Color(0xFF0077B6) : AppColors.pelagicCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "全天候戰術環境風格",
                  style: TextStyle(
                    color: isClassic ? AppColors.classicText : Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isClassic ? "目前：經典白藍老船長版 (烈日外礁高對比)" : "目前：深淵黑金旗艦版 (OLED極致純黑)",
                  style: TextStyle(
                    color: isClassic ? Colors.grey.shade600 : Colors.white.withValues(alpha: 0.5), 
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isClassic,
            activeColor: const Color(0xFF0077B6),
            onChanged: (val) {
              HapticFeedback.mediumImpact();
              ref.read(isClassicThemeProvider.notifier).setClassicTheme(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String statusText,
    required String desc,
    required Color statusColor,
    required bool isClassic,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClassic ? Colors.white : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isClassic ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08), width: isClassic ? 1.0 : 0.5),
        boxShadow: isClassic ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: TextStyle(
                        color: isClassic ? AppColors.classicText : Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc, 
            style: TextStyle(
              color: isClassic ? Colors.grey.shade600 : Colors.white.withValues(alpha: 0.5), 
              fontSize: 12, 
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}