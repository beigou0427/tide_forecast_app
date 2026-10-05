enum SemanticClusterType {
  species,          // 魚種生物群
  tacticsAndGear,   // 釣法裝備群
  hydroPhysical,    // 水文物理群
  maritimeSafety,   // 海事安全群
}

class SemanticClusterItem {
  final String term;
  final SemanticClusterType cluster;

  const SemanticClusterItem({
    required this.term,
    required this.cluster,
  });
}

class SemanticClusterAuditReport {
  final bool isZeroDuplication;
  final bool isAllClustersCovered;
  final int totalCombinatorialQueries; // 推估 Apple 可組合之長尾搜尋詞數
  final Map<SemanticClusterType, int> clusterCounts;
  final List<String> issues;

  const SemanticClusterAuditReport({
    required this.isZeroDuplication,
    required this.isAllClustersCovered,
    required this.totalCombinatorialQueries,
    required this.clusterCounts,
    required this.issues,
  });

  bool get isPassed => isZeroDuplication && isAllClustersCovered && issues.isEmpty;
}

/// 🌟 Gabe Kwakyi (Incipia 共同創辦人 / 語意分群專家)
/// 跨欄位排列組合去重演算法與四大語意聚類引擎
class SemanticClusterEngine {
  // 四大語意分群庫
  static const List<SemanticClusterItem> dictionary = [
    // 1. 魚種生物群
    SemanticClusterItem(term: "黑毛", cluster: SemanticClusterType.species),
    SemanticClusterItem(term: "白毛", cluster: SemanticClusterType.species),
    SemanticClusterItem(term: "軟絲", cluster: SemanticClusterType.species),
    SemanticClusterItem(term: "透抽", cluster: SemanticClusterType.species),
    SemanticClusterItem(term: "紅甘", cluster: SemanticClusterType.species),
    SemanticClusterItem(term: "煙仔虎", cluster: SemanticClusterType.species),
    SemanticClusterItem(term: "黑鯛", cluster: SemanticClusterType.species),
    SemanticClusterItem(term: "石斑", cluster: SemanticClusterType.species),

    // 2. 釣法裝備群
    SemanticClusterItem(term: "磯釣", cluster: SemanticClusterType.tacticsAndGear),
    SemanticClusterItem(term: "船釣", cluster: SemanticClusterType.tacticsAndGear),
    SemanticClusterItem(term: "路亞", cluster: SemanticClusterType.tacticsAndGear),
    SemanticClusterItem(term: "前打", cluster: SemanticClusterType.tacticsAndGear),
    SemanticClusterItem(term: "沉底", cluster: SemanticClusterType.tacticsAndGear),
    SemanticClusterItem(term: "鐵板", cluster: SemanticClusterType.tacticsAndGear),
    SemanticClusterItem(term: "木蝦", cluster: SemanticClusterType.tacticsAndGear),
    SemanticClusterItem(term: "阿波", cluster: SemanticClusterType.tacticsAndGear),

    // 3. 水文物理群
    SemanticClusterItem(term: "海流", cluster: SemanticClusterType.hydroPhysical),
    SemanticClusterItem(term: "水溫", cluster: SemanticClusterType.hydroPhysical),
    SemanticClusterItem(term: "潮差", cluster: SemanticClusterType.hydroPhysical),
    SemanticClusterItem(term: "大潮", cluster: SemanticClusterType.hydroPhysical),
    SemanticClusterItem(term: "氣壓", cluster: SemanticClusterType.hydroPhysical),
    SemanticClusterItem(term: "月相", cluster: SemanticClusterType.hydroPhysical),

    // 4. 海事安全群
    SemanticClusterItem(term: "瘋狗浪", cluster: SemanticClusterType.maritimeSafety),
    SemanticClusterItem(term: "防困礁", cluster: SemanticClusterType.maritimeSafety),
    SemanticClusterItem(term: "85測站", cluster: SemanticClusterType.maritimeSafety),
    SemanticClusterItem(term: "光纖直連", cluster: SemanticClusterType.maritimeSafety),
    SemanticClusterItem(term: "離線神盾", cluster: SemanticClusterType.maritimeSafety),
  ];

  /// 🌟 專屬自動化自檢診斷方法：檢驗跨欄位重複浪費度與語意群分佈
  static SemanticClusterAuditReport runDiagnosticCheck({
    required String title,
    required String subtitle,
    required String keywords,
  }) {
    final List<String> issues = [];

    // 1. 拆解單字集合
    final Set<String> titleWords = _extractTerms(title);
    final Set<String> subtitleWords = _extractTerms(subtitle);
    final Set<String> keywordList = keywords.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

    // 2. 檢驗 Title vs Keywords 碰撞
    final titleCollisions = keywordList.intersection(titleWords);
    if (titleCollisions.isNotEmpty) {
      issues.add("Keywords 與 Title 出現重複詞彙: $titleCollisions (白白浪費字元空間)");
    }

    // 3. 檢驗 Subtitle vs Keywords 碰撞
    final subtitleCollisions = keywordList.intersection(subtitleWords);
    if (subtitleCollisions.isNotEmpty) {
      issues.add("Keywords 與 Subtitle 出現重複詞彙: $subtitleCollisions (白白浪費字元空間)");
    }

    // 4. 統計四大語意群覆蓋度
    final String combined = "$title $subtitle $keywords";
    final Map<SemanticClusterType, int> counts = {
      SemanticClusterType.species: 0,
      SemanticClusterType.tacticsAndGear: 0,
      SemanticClusterType.hydroPhysical: 0,
      SemanticClusterType.maritimeSafety: 0,
    };

    for (final item in dictionary) {
      if (combined.contains(item.term)) {
        counts[item.cluster] = (counts[item.cluster] ?? 0) + 1;
      }
    }

    bool allCovered = true;
    counts.forEach((cluster, count) {
      if (count < 2) {
        allCovered = false;
        issues.add("語意群 [${cluster.name}] 收錄不足 (僅 $count 個詞彙，建議至少 2 個)");
      }
    });

    // 5. 計算排列組合數 (Title 核心詞 x Keywords 意圖詞)
    final int combinatorialQueries = titleWords.length * keywordList.length;

    return SemanticClusterAuditReport(
      isZeroDuplication: issues.where((i) => i.contains("重複")).isEmpty,
      isAllClustersCovered: allCovered,
      totalCombinatorialQueries: combinatorialQueries,
      clusterCounts: counts,
      issues: issues,
    );
  }

  static Set<String> _extractTerms(String text) {
    final Set<String> extracted = {};
    for (final item in dictionary) {
      if (text.contains(item.term)) {
        extracted.add(item.term);
      }
    }
    return extracted;
  }
}