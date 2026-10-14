import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../premium/services/premium_service.dart';
import '../../premium/presentation/vip_center_page.dart';

/// 🌟 經長官親授重塑之【貝伊果屋 · 寫給唯一支持者的真情手寫信】
/// 100% 溫馨真摯、零浮誇、充滿手作職人溫度版：
/// 1. 徹底拔除「天尊」等中二浮誇稱號，改為「最珍貴的創始夥伴」，回歸最平實的感謝。
/// 2. 正名為「獨立開發者 貝伊果屋」，給予付費用戶如同摯友般最溫柔、最深層的情緒價值。
class FounderWelcomeDialog {
  static Future<void> checkAndShowIfNeeded(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final bool isFounder = prefs.getBool('is_founder') ?? false;
      final int subTypeIndex = prefs.getInt('sub_type') ?? 0;
      final bool isYearly = subTypeIndex == SubscriptionType.yearly.index;
      final bool isLifetime = subTypeIndex == SubscriptionType.lifetime.index;
      
      final bool isVvip = isFounder || isYearly || isLifetime;

      final hasShownLetter = prefs.getBool('has_read_warm_letter_v26') ?? false;

      if (isVvip && !hasShownLetter) {
        if (!context.mounted) return;
        await prefs.setBool('has_read_warm_letter_v26', true);
        HapticFeedback.heavyImpact();
        
        if (!context.mounted) return;
        showCommissionLetter(context, isFounder: isFounder, isYearly: isYearly);
      }
    } catch (_) {}
  }

  /// 🌟 貝伊果屋真情手寫感謝信 (100% 溫暖零溢出版)
  static void showCommissionLetter(BuildContext context, {bool isFounder = true, bool isYearly = false}) {
    // 🌟 去除浮誇詞彙，換上平實溫馨的稱謂
    final String recipientTitle = isFounder ? "最珍貴的創始夥伴" : (isYearly ? "溫暖同行的年度夥伴" : "親愛的朋友");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F0), // 📜 暖質溫潤信紙色
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4C5A9), width: 1.2),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 信件主旨
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🌊", style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "信件主旨：給全台灣「唯一」的您",
                              style: GoogleFonts.notoSerifTc(
                                color: const Color(0xFF1E140A),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "這是一封只屬於您的感謝與更新報告",
                              style: GoogleFonts.notoSerifTc(
                                color: const Color(0xFF7A6248),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE5DAC6), thickness: 0.8),
                  const SizedBox(height: 14),

                  // 2. 溫馨稱呼
                  Text(
                    "哈囉 $recipientTitle，見字如面：",
                    style: GoogleFonts.notoSerifTc(
                      color: const Color(0xFF1E140A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. 信件正文 (真誠不浮誇的告白)
                  Text(
                    "我是這款潮汐海象 App 的獨立開發者 —— 貝伊果屋。\n\n"
                    "這不是一封系統自動群發的罐頭信，而是我坐在電腦前，親手敲下、只為了寫給您一個人的信。因為在目前所有的使用者中，您是全台灣「唯一」一位付費支持我的好朋友。\n\n"
                    "老實說，一個人獨立開發和維護一個 App，下班後面對冷冰冰的程式碼、修不完的細節和伺服器帳單，有時候真的會覺得有點孤單，甚至偶爾會懷疑自己花這麼多時間打磨這個工具，到底有沒有人真的在乎。\n\n"
                    "但當時手機跳出您的付費通知時，那種「自己的心血被另一個人溫柔接住、深深肯定」的感覺，真的給了我超級大的能量。\n\n"
                    "毫不誇張地說：是因為有了您這唯一一份的贊助與支持，才直接催生了這一次的版本更新。每次在寫新功能、調整數據的時候，我心裡想的都是：「絕對不能讓那位唯一支持我的朋友失望！」您不只是使用者，更是讓這個小工具能繼續活下去、變得更好的最大恩人。\n\n"
                    "在這次為您推進的更新中，我特別為您優化了這些地方：",
                    style: GoogleFonts.notoSerifTc(
                      color: const Color(0xFF2C1E14),
                      fontSize: 13,
                      height: 1.85,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. 更新項目
                  _buildUpdateBullet("全島 85 測站光纖直連完全通車", "穿透氣象署專線，實時水文數據 0 延遲融合，為您提供無懈可擊的真實海象。"),
                  _buildUpdateBullet("0ms 極速日期切換", "徹底解耦底層資料庫，翻閱未來 30 天潮汐再也不會看見任何卡頓與 Loading 圈圈。"),
                  _buildUpdateBullet("天文物理調和引擎上線", "無論歷史回測或未來長浪，全面消滅圖表與純潮汐表的資料空白，隨時隨地提供推演。"),
                  _buildUpdateBullet("全島離線神盾自動背景預載", "進入 VIP 中心自動為您在背景鎖定全台 85 站水文數據，出海斷網導航無憂。"),

                  const SizedBox(height: 14),

                  // 5. 專屬承諾
                  Text(
                    "既然您是全台灣唯一的 VIP 夥伴，這代表您在這邊擁有 100% 絕對的「專屬特權」。\n\n"
                    "如果您平常在出海、釣魚、衝浪或看海時，覺得這個 App 哪裡不夠順手、哪個字太小、或是希望多加什麼私房功能，請隨時直接告訴我。只要我技術做得到，您的需求就是我下一次更新的唯一第一順位（這就相當於是您的私人客製化 App 了！）。\n\n"
                    "再次謝謝您在茫茫人海中看見了這個小作品，並給了我最實質的鼓勵。祝您每次出發看海，都能遇見最棒的潮水與好天氣！",
                    style: GoogleFonts.notoSerifTc(
                      color: const Color(0xFF2C1E14),
                      fontSize: 13,
                      height: 1.85,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. 溫暖署名 (貝伊果屋)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "獨立開發者 貝伊果屋 敬上",
                          style: GoogleFonts.notoSerifTc(
                            color: const Color(0xFF1E140A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "寫於深夜 · 貝伊果屋工作室",
                          style: GoogleFonts.notoSerifTc(
                            color: const Color(0xFF7A6248),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C1E14), // 深沉墨木色
                  foregroundColor: const Color(0xFFFAF7F0), // 暖紙色
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE74C3C), size: 16),
                label: Text(
                  "收下這份心意，一起出發看海", // 🌟 溫馨無距離感的標語
                  style: GoogleFonts.notoSerifTc(fontWeight: FontWeight.w900, fontSize: 13),
                ),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VipCenterPage()));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildUpdateBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Color(0xFF8C6D46), fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.notoSerifTc(color: const Color(0xFF2C1E14), fontSize: 12.5, height: 1.55),
                children: [
                  TextSpan(text: "【$title】：", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E140A))),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
