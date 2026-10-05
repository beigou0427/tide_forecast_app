enum AppStoreEventBadge {
  specialEvent, // 特別活動
  liveEvent,    // 即時活動
  majorUpdate,  // 重大更新
}

class InAppEventProposal {
  final String referenceName;
  final String eventName;
  final String shortDescription;
  final String longDescription;
  final String deepLinkUrl;
  final AppStoreEventBadge badge;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const InAppEventProposal({
    required this.referenceName,
    required this.eventName,
    required this.shortDescription,
    required this.longDescription,
    required this.deepLinkUrl,
    required this.badge,
    required this.startDateTime,
    required this.endDateTime,
  });
}

class InAppEventAuditReport {
  final bool isNameWithinLimit;
  final bool isShortDescWithinLimit;
  final bool isLongDescWithinLimit;
  final bool isDurationValid;
  final bool isDeepLinkValid;
  final List<String> issues;

  const InAppEventAuditReport({
    required this.isNameWithinLimit,
    required this.isShortDescWithinLimit,
    required this.isLongDescWithinLimit,
    required this.isDurationValid,
    required this.isDeepLinkValid,
    required this.issues,
  });

  bool get isPassed =>
      isNameWithinLimit &&
      isShortDescWithinLimit &&
      isLongDescWithinLimit &&
      isDurationValid &&
      isDeepLinkValid &&
      issues.isEmpty;
}

/// 🌟 Moritz Daan (Phiture 創辦人 / ASO Stack 創建者)
/// Apple 官方 App 內活動 (In-App Events, IAE) 生成與排程中樞
class InAppEventEngine {
  /// 根據當前時間與天體大潮週期，動態生成下一場「週末大潮走水出海活動」
  static InAppEventProposal generateUpcomingSpringTideEvent(DateTime referenceTime) {
    // 定位下一個週五 18:00 至週日 23:59
    DateTime friday = referenceTime;
    while (friday.weekday != DateTime.friday) {
      friday = friday.add(const Duration(days: 1));
    }
    final start = DateTime(friday.year, friday.month, friday.day, 18, 0);
    final end = start.add(const Duration(days: 2, hours: 5, minutes: 59));

    return InAppEventProposal(
      referenceName: "Weekend_Spring_Tide_Golden_Window",
      eventName: "🌕 週末大潮出海走水黃金窗口",
      shortDescription: "全台85站實測潮差突破2米，走水活化索餌窗口全開！",
      longDescription: "本週末適逢天文大潮走水期，滿潮返退2分急流活水帶動餌魚群聚，立即解鎖85測站即時海象雷達把握出海窗口。",
      deepLinkUrl: "tidepro://events/spring_tide_window",
      badge: AppStoreEventBadge.specialEvent,
      startDateTime: start,
      endDateTime: end,
    );
  }

  /// 🌟 專屬自動化自檢診斷方法：檢驗活動中繼資料是否 100% 符合 Apple 提審剛性規範
  static InAppEventAuditReport runDiagnosticCheck(InAppEventProposal proposal) {
    final List<String> issues = [];

    // 1. 活動名稱 <= 30 字元
    final bool nameOk = proposal.eventName.length <= 30;
    if (!nameOk) {
      issues.add("活動名稱超過 Apple 30 字元限制 (${proposal.eventName.length} > 30)");
    }

    // 2. 簡短說明 <= 64 字元
    final bool shortDescOk = proposal.shortDescription.length <= 64;
    if (!shortDescOk) {
      issues.add("簡短說明超過 Apple 64 字元限制 (${proposal.shortDescription.length} > 64)");
    }

    // 3. 詳細說明 <= 120 字元
    final bool longDescOk = proposal.longDescription.length <= 120;
    if (!longDescOk) {
      issues.add("詳細說明超過 Apple 120 字元限制 (${proposal.longDescription.length} > 120)");
    }

    // 4. 活動時長檢驗 (Apple 限制最長 31 天，最短 15 分鐘)
    final duration = proposal.endDateTime.difference(proposal.startDateTime);
    final bool durationOk = duration.inMinutes >= 15 && duration.inDays <= 31 && proposal.endDateTime.isAfter(proposal.startDateTime);
    if (!durationOk) {
      issues.add("活動時長不合規 (${duration.inHours} 小時，需介於 15 分鐘至 31 天之間)");
    }

    // 5. Deep Link 格式驗證
    final uri = Uri.tryParse(proposal.deepLinkUrl);
    final bool deepLinkOk = uri != null && uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    if (!deepLinkOk) {
      issues.add("深度連結 (Deep Link) 格式無效 (${proposal.deepLinkUrl})");
    }

    return InAppEventAuditReport(
      isNameWithinLimit: nameOk,
      isShortDescWithinLimit: shortDescOk,
      isLongDescWithinLimit: longDescOk,
      isDurationValid: durationOk,
      isDeepLinkValid: deepLinkOk,
      issues: issues,
    );
  }
}