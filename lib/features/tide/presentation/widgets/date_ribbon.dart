import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/tide_provider.dart';
import '../../../premium/services/premium_service.dart';
import '../../../premium/presentation/premium_page.dart';

class DateRibbon extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final Color themeColor;
  const DateRibbon({super.key, required this.selectedDate, required this.themeColor});

  @override
  ConsumerState<DateRibbon> createState() => _DateRibbonState();
}

class _DateRibbonState extends ConsumerState<DateRibbon> {
  late ScrollController _scrollController;
  final double itemWidth = 66.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (_scrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final offset = (30 * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      _scrollController.animateTo(offset, duration: const Duration(milliseconds: 800), curve: Curves.easeOutBack);
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
    final String todayStr = DateFormat('yyyyMMdd').format(now);
    final String selectedStr = DateFormat('yyyyMMdd').format(widget.selectedDate);
    final isPremium = ref.watch(premiumProvider).isPremium;

    return SizedBox(
      height: 78,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 61, 
        itemBuilder: (context, index) {
          final date = now.subtract(const Duration(days: 30)).add(Duration(days: index));
          final String currentStr = DateFormat('yyyyMMdd').format(date);
          final bool isToday = currentStr == todayStr;
          final bool isSelected = currentStr == selectedStr;

          // 🌟 VIP 痛點修復 3/3：精準捕捉週末，賦予高亮色彩
          final bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

          final int dayDiff = date.difference(todayZero).inDays;
          final bool isFree = dayDiff >= -1 && dayDiff <= 1;
          final bool isLocked = !isFree && !isPremium;

          // 週末與平日的文字顏色邏輯
          Color weekdayColor = isSelected 
              ? widget.themeColor 
              : (isToday ? Colors.amberAccent : (isWeekend ? Colors.deepOrangeAccent : Colors.white70));
          
          Color dateColor = isSelected 
              ? widget.themeColor 
              : (isWeekend && !isToday ? Colors.orange.shade100 : Colors.white);

          return GestureDetector(
            onTap: () {
              if (isLocked) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
              } else {
                ref.read(selectedDateProvider.notifier).state = date;
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : (isWeekend && !isToday ? Colors.deepOrange.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.15)),
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
                        Text(DateFormat('E').format(date), style: TextStyle(color: weekdayColor, fontSize: 10, fontWeight: isToday || isWeekend ? FontWeight.bold : FontWeight.normal)),
                        Text(DateFormat('dd').format(date), style: TextStyle(color: dateColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (isToday)
                    Positioned(top: -11, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]), child: const Text("今日", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900))))),
                  if (isLocked)
                    Positioned(top: 4, right: 4, child: Icon(Icons.lock_outline, size: 10, color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}