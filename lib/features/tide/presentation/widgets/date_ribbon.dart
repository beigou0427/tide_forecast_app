import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';

/// 🌟 Dan Abramov 細粒度響應式日期捲軸 (Fine-Grained Reactive Ribbon)
/// 100% 幾何狀態同步版：
/// 1. 實裝 didUpdateWidget，確保透過日曆或「返回今日」按鈕變更日期時，捲軸能自動精確滾動至目標可視區。
/// 2. 導入 ref.watch(select()) 精確訂閱與冪等點擊防抖，徹底阻止無效全域重繪。
class DateRibbon extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final Color themeColor;
  const DateRibbon({super.key, required this.selectedDate, required this.themeColor});

  @override
  ConsumerState<DateRibbon> createState() => _DateRibbonState();
}

class _DateRibbonState extends ConsumerState<DateRibbon> {
  late ScrollController _scrollController;
  static const double itemWidth = 66.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate(animate: false));
  }

  // 🌟 核心防線：監聽外部 State 變化，強制對齊 ScrollController 幾何偏移量！
  @override
  void didUpdateWidget(covariant DateRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      // 若外部變更了日期 (例如日曆選擇或返回今日)，自動平滑滾動至該日期
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate(animate: true));
    }
  }

  void _scrollToSelectedDate({required bool animate}) {
    if (_scrollController.hasClients) {
      final now = DateTime.now();
      final todayZero = DateTime(now.year, now.month, now.day);
      final targetZero = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
      
      // 精算日曆天數差，並約束在 [-30, 30] 快取區間內
      final int dayDiff = targetZero.difference(todayZero).inDays.clamp(-30, 30);
      final int targetIndex = 30 + dayDiff; // Index 30 為今日
      
      final screenWidth = MediaQuery.of(context).size.width;
      final offset = (targetIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      if (animate) {
        _scrollController.animateTo(
          offset, 
          duration: const Duration(milliseconds: 400), 
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime todayZero = DateTime(now.year, now.month, now.day);
    final String todayStr = DateFormat('yyyyMMdd').format(todayZero);
    final String selectedStr = DateFormat('yyyyMMdd').format(widget.selectedDate);

    // 🌟 Dan Abramov 細粒度選擇器：僅在 isPremium 布林值翻轉時才觸發局部重繪
    final bool isPremium = ref.watch(premiumProvider.select((s) => s.isPremium || s.isFounder));

    return SizedBox(
      height: 78,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 61, 
        itemBuilder: (context, index) {
          final int dayDiff = index - 30;
          final date = DateTime(todayZero.year, todayZero.month, todayZero.day + dayDiff);
          
          final String currentStr = DateFormat('yyyyMMdd').format(date);
          final bool isToday = currentStr == todayStr;
          final bool isSelected = currentStr == selectedStr;
          final bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

          final bool isFree = dayDiff >= -1 && dayDiff <= 1;
          final bool isLocked = !isFree && !isPremium;

          final Color weekdayColor = isSelected 
              ? widget.themeColor 
              : (isToday ? Colors.amberAccent : (isWeekend ? Colors.deepOrangeAccent : Colors.white70));
          
          final Color dateColor = isSelected 
              ? widget.themeColor 
              : (isWeekend && !isToday ? Colors.orange.shade100 : Colors.white);

          return GestureDetector(
            onTap: () {
              // 🌟 冪等性短路防護：若點擊當前已選中日期，0 操作直接返回
              if (isSelected) return;

              HapticFeedback.selectionClick();

              if (isLocked) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
              } else {
                ref.read(selectedDateProvider.notifier).state = date;
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : (isWeekend && !isToday ? Colors.deepOrange.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(16),
                border: isToday 
                    ? Border.all(color: isSelected ? Colors.amber : Colors.amberAccent, width: 2.5) 
                    : (isWeekend && !isSelected ? Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.4), width: 1.2) : null),
                boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date), 
                          style: TextStyle(
                            color: weekdayColor, 
                            fontSize: 10, 
                            fontWeight: isToday || isWeekend ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          DateFormat('dd').format(date), 
                          style: TextStyle(
                            color: dateColor, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    Positioned(
                      top: -11, left: 0, right: 0, 
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                          decoration: BoxDecoration(
                            color: Colors.amber, 
                            borderRadius: BorderRadius.circular(8), 
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                          ), 
                          child: const Text("今日", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  if (isLocked)
                    Positioned(
                      top: 4, right: 4, 
                      child: Icon(Icons.lock_outline, size: 10, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}