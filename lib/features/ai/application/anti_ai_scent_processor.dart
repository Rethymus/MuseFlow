/// Anti-AI-scent post-processor.
///
/// Dual-layer processing system per AI-05 and AI-06:
/// 1. Auto-replacement phase: replaces banned Chinese AI cliches with synonyms
/// 2. Structural highlight phase: detects套话句式 and wraps with 【】 markers
///
/// Per D-09: Synonym map seeded with common Chinese AI cliches.
/// Per D-10: Structural patterns highlighted for manual review, not auto-replaced.
library;

import 'dart:math' as math;

/// Type of text highlight found during processing.
enum HighlightType {
  /// A banned word that was auto-replaced with a synonym or deleted.
  bannedWord,

  /// A structural pattern (套话句式) highlighted for manual review.
  structuralPattern,
}

/// Severity of an author-facing AI-scent review signal.
enum ReviewSignalSeverity {
  /// Low-risk note for author awareness.
  low,

  /// Medium-risk signal that deserves review before accepting AI text.
  medium,

  /// High-risk signal that can make the output feel template-like.
  high,
}

/// A deterministic review signal that explains why AI output may need
/// author attention before being accepted.
class ReviewSignal {
  /// Human-readable title for the signal.
  final String title;

  /// Concrete explanation of the detected pattern.
  final String description;

  /// Severity for prioritizing author review.
  final ReviewSignalSeverity severity;

  /// Optional evidence value shown to users/tests, e.g. "7 次".
  final String evidence;

  const ReviewSignal({
    required this.title,
    required this.description,
    required this.severity,
    required this.evidence,
  });
}

/// A highlight location in the processed text.
class TextHighlight {
  /// Start position (inclusive) in the processed text.
  final int start;

  /// End position (exclusive) in the processed text.
  final int end;

  /// The original text that was found and highlighted/replaced.
  final String originalText;

  /// The type of highlight.
  final HighlightType type;

  const TextHighlight({
    required this.start,
    required this.end,
    required this.originalText,
    required this.type,
  });

  @override
  String toString() =>
      'TextHighlight(start: $start, end: $end, '
      'original: "$originalText", type: $type)';
}

/// Result of anti-AI-scent processing.
class ProcessingResult {
  /// The processed text after replacements and highlight markers.
  final String processedText;

  /// Locations of highlights in the processed text.
  final List<TextHighlight> highlights;

  /// Author-facing review signals for structural AI-scent risk.
  final List<ReviewSignal> reviewSignals;

  const ProcessingResult({
    required this.processedText,
    required this.highlights,
    this.reviewSignals = const [],
  });
}

/// Post-processor that removes AI-scented patterns from Chinese text.
///
/// Processing has two phases:
/// 1. **Auto-replacement**: Banned phrases are replaced with synonyms
///    using boundary-aware matching (per Pitfall 5: checks surrounding
///    characters are punctuation, whitespace, or string boundary).
/// 2. **Structural highlighting**: Complex patterns (套话句式) are
///    wrapped with 【】 markers for the user to manually review.
///
/// Usage:
/// ```dart
/// final processor = AntiAIScentProcessor();
/// final result = processor.process(text, bannedPhrases: extraPhrases);
/// print(result.processedText);
/// for (final h in result.highlights) {
///   print('Found ${h.originalText} at ${h.start}-${h.end}');
/// }
/// ```
class AntiAIScentProcessor {
  /// The keys from the built-in synonym map, used to seed user's banned list.
  static List<String> get synonymKeys => _synonymMap.keys.toList();

  /// Fixed synonym map for auto-replacement per D-09.
  /// Empty string values mean "delete the phrase".
  /// Organized by category for maintainability.
  /// Target: 200+ entries across 20 categories.
  static const Map<String, String> _synonymMap = {
    // ═══════════════════════════════════════════════════════════════
    // 一、过渡连接词 (Essay-style transitions — rare in fiction)
    // ═══════════════════════════════════════════════════════════════
    '然而': '但是',
    '与此同时': '',
    '事实上': '',
    '实际上': '',
    '具体来说': '',
    '换句话说': '',
    '进一步来说': '',
    '更重要的是': '',
    '话虽如此': '',
    '尽管如此': '',
    '不仅如此': '',
    '此外': '',
    '换言之': '',
    '更为重要的是': '',
    '在此期间': '',
    '在此之前': '',
    '从此以后': '',
    '自那以后': '',

    // ═══════════════════════════════════════════════════════════════
    // 二、总结归纳词 (Conclusion phrases — essay-style, not fiction)
    // ═══════════════════════════════════════════════════════════════
    '综上所述': '',
    '总而言之': '',
    '总的来说': '',
    '总之': '',
    '简而言之': '',
    '概而言之': '',
    '由此可见': '',
    '一言以蔽之': '',
    '由此看来': '',
    '事实证明': '',
    '由此可知': '',
    '足以证明': '',
    '由此表明': '',

    // ═══════════════════════════════════════════════════════════════
    // 三、强调判断词 (Emphasis/judgment — AI loves these in fiction)
    // ═══════════════════════════════════════════════════════════════
    '值得注意的是': '',
    '需要指出的是': '',
    '毫无疑问': '',
    '不可否认': '',
    '不言而喻': '',
    '显而易见': '',
    '众所周知': '',
    '毋庸置疑': '',
    '不容忽视': '',
    '至关重要': '',
    '从某种意义上说': '',
    '值得一提': '',
    '尤为突出': '',
    '尤为重要': '',
    '的确如此': '',
    '无可厚非': '',
    '不言自明': '',
    '不可小觑': '',
    '不得不说': '',
    '尤其': '',

    // ═══════════════════════════════════════════════════════════════
    // 四、序数枚举词 (Enumerative — AI enumerates where fiction flows)
    // Note: 第一/第二/第三 removed — they're too aggressive as standalone
    // replacements (e.g., "第二次" → "次"). First/其次/Last catch enumeration.
    '首先': '',
    '其次': '',
    '最后': '',
    '一方面': '',
    '另一方面': '',

    // ═══════════════════════════════════════════════════════════════
    // 五、因果解释词 (Causal explanation — AI over-explains cause)
    // ═══════════════════════════════════════════════════════════════
    '正因如此': '',
    '之所以如此': '',
    '究其原因': '',
    '归根结底': '',
    '追根溯源': '',
    '溯其根源': '',
    '正因为如此': '',
    '正因这般': '',
    '原因很简单': '',
    '其根本原因': '',
    '这其中的原因': '',

    // ═══════════════════════════════════════════════════════════════
    // 六、叙述框架词 (Narrative framework — AI starts with meta)
    // ═══════════════════════════════════════════════════════════════
    '人们常说': '',
    '俗话说': '',
    '古人云': '',
    '常言道': '',
    '有句话说的好': '',
    '正所谓': '',
    '故事要从': '',
    '事情要追溯到': '',
    '事情是这样的': '',
    '情况是这样的': '',
    '原来如此': '',
    '经过一番': '',
    '在一番': '',

    // ═══════════════════════════════════════════════════════════════
    // 七、情感表达套话 (Emotional cliches — AI tells instead of shows)
    // ═══════════════════════════════════════════════════════════════
    '心中涌起一股暖流': '',
    '眼眶微微湿润': '',
    '鼻子一酸': '',
    '暖流涌遍全身': '',
    '百感交集': '',
    '五味杂陈': '',
    '心如刀绞': '',
    '泪流满面': '',
    '一股暖意涌上心头': '',
    '不禁潸然泪下': '',
    '心中五味杂陈': '',
    '一阵酸楚涌上心头': '',
    '眼眶微红': '',
    '心如刀割': '',
    '肝肠寸断': '',
    '心潮澎湃': '',
    '怒火中烧': '',
    '心中一紧': '',
    '心中一颤': '',
    '不由得心头一紧': '',

    // ═══════════════════════════════════════════════════════════════
    // 八、人物描写套话 (Character description — formulaic portraits)
    // ═══════════════════════════════════════════════════════════════
    '眼中闪过一丝': '',
    '嘴角微微上扬': '',
    '眉头微皱': '',
    '眼神中透着': '',
    '目光中带着': '',
    '脸上露出': '',
    '神情自若': '',
    '面色如常': '',
    '面不改色': '',
    '不紧不慢': '',
    '从容不迫': '',
    '波澜不惊': '',
    '气宇轩昂': '',
    '英姿飒爽': '',
    '目光如炬': '',
    '目光深邃': '',
    '嘴角勾起一抹': '',
    '眼中闪过一抹': '',
    '面色微变': '',

    // ═══════════════════════════════════════════════════════════════
    // 九、动作描写套话 (Action cliches — repetitive physical actions)
    // ═══════════════════════════════════════════════════════════════
    '缓缓说道': '',
    '淡淡地说': '',
    '微微一笑': '',
    '紧紧握住': '',
    '默默注视': '',
    '悄然离开': '',
    '倒吸一口凉气': '',
    '不由自主地': '',
    '下意识地': '',
    '情不自禁地': '',
    '鬼使神差地': '',
    '毫不犹豫地': '',
    '缓缓点头': '',
    '轻轻摇头': '',
    '长叹一声': '',
    '深吸一口气': '',

    // ═══════════════════════════════════════════════════════════════
    // 十、心理活动套话 (Inner thought cliches — formulaic narration)
    // ═══════════════════════════════════════════════════════════════
    '心中暗想': '',
    '心中想着': '',
    '心里清楚': '',
    '顿时明白了': '',
    '恍然大悟': '',
    '心下暗忖': '',
    '暗自思忖': '',
    '心中了然': '',
    '心知肚明': '',
    '若有所思': '',
    '陷入沉思': '',
    '百思不得其解': '',
    '心念一动': '',
    '灵光一闪': '',
    '心中暗自': '',

    // ═══════════════════════════════════════════════════════════════
    // 十一、结尾悬念套话 (Ending hook cliches — formulaic chapter ends)
    // ═══════════════════════════════════════════════════════════════
    '一场更大的风暴': '',
    '真正的考验': '',
    '才刚刚开始': '',
    '等待着他': '',
    '命运的齿轮': '',
    '更大的挑战': '',
    '一切才刚刚开始': '',
    '真正的战斗': '',
    '命运的转折': '',
    '故事才刚刚开始': '',
    '一场暴风雨即将来临': '',
    '暗流涌动': '',

    // ═══════════════════════════════════════════════════════════════
    // 十二、比喻/修辞套话 (Metaphor/rhetoric — AI defaults to these)
    // ═══════════════════════════════════════════════════════════════
    '宛如仙境': '',
    '美不胜收': '',
    '如诗如画': '',
    '美轮美奂': '',
    '心旷神怡': '',
    '沁人心脾': '',
    '引人入胜': '',
    '叹为观止': '',
    '仿佛置身于': '',
    '宛若天成': '',
    '犹如一把利剑': '',
    '如同黑夜中的明灯': '',
    '宛如烈火': '',
    '好似潮水': '',

    // ═══════════════════════════════════════════════════════════════
    // 十三、修仙/玄幻类型套话 (Xianxia/fantasy genre cliches)
    // ═══════════════════════════════════════════════════════════════
    '灵气涌动': '',
    '磅礴的力量': '',
    '周身气息': '',
    '体内灵力': '',
    '剑气纵横': '',
    '灵力波动': '',
    '灵光闪烁': '',
    '道韵流转': '',
    '法力涌动': '',
    '灵气四溢': '',
    '威压逼人': '',
    '气势如虹': '',

    // ═══════════════════════════════════════════════════════════════
    // 十四、对话标签套话 (Dialogue tag cliches — repetitive attribution)
    // ═══════════════════════════════════════════════════════════════
    '沉声说道': '',
    '冷冷地说': '',
    '厉声喝道': '',
    '温柔地说道': '',
    '低声说道': '',
    '高声说道': '',
    '轻声说道': '',
    '沉声道': '',
    '冷冷道': '',
    '淡淡道': '',

    // ═══════════════════════════════════════════════════════════════
    // 十五、环境氛围套话 (Atmospheric cliches — formulaic scenery)
    // ═══════════════════════════════════════════════════════════════
    '夜色如水': '',
    '月华如练': '',
    '繁星点点': '',
    '万籁俱寂': '',
    '一片寂静': '',
    '鸦雀无声': '',
    '空气凝固': '',
    '气氛凝重': '',
    '气氛紧张': '',
    '寂静无声': '',

    // ═══════════════════════════════════════════════════════════════
    // 十六、时间转场套话 (Temporal transition — AI paragraph starters)
    // ═══════════════════════════════════════════════════════════════
    '就在这时': '',
    '就在此时': '',
    '就在那一刻': '',
    '刹那间': '',
    '顷刻间': '',
    '转瞬之间': '',
    '弹指之间': '',
    '须臾之间': '',
    '瞬息之间': '',
    '片刻之后': '',
    '过了片刻': '',
    '良久之后': '',

    // ═══════════════════════════════════════════════════════════════
    // 十七、评价性套话 (Evaluative cliches — AI judges for the reader)
    // ═══════════════════════════════════════════════════════════════
    '令人惊叹': '',
    '让人感动': '',
    '不禁感慨': '',
    '令人欣慰': '',
    '引人深思': '',
    '令人震撼': '',
    '让人心酸': '',
    '让人窒息': '',
    '令人叹服': '',
    '让人肃然起敬': '',
    '令人窒息': '',
    '令人心悸': '',

    // ═══════════════════════════════════════════════════════════════
    // 十八、节奏填充词 (Pacing fillers — AI pads rhythm uniformly)
    // ═══════════════════════════════════════════════════════════════
    '不知不觉间': '',
    '在不知不觉中': '',
    '不知不觉地': '',
    '悄无声息地': '',
    '毫无征兆地': '',
    '毫无预兆地': '',
    '缓缓地': '',
    '徐徐地': '',

    // ═══════════════════════════════════════════════════════════════
    // 十九、叙事总结套话 (Narrative summary — AI summarizes instead of shows)
    // ═══════════════════════════════════════════════════════════════
    '事情的发展': '',
    '这一切的一切': '',
    '这才是真正的': '',
    '这便是': '',
    '一切都发生了变化': '',

    // ═══════════════════════════════════════════════════════════════
    // 二十、强度修饰词 (Intensity modifiers — AI amplifies everything)
    // ═══════════════════════════════════════════════════════════════
    '极其': '',
    '异常': '',
    '万分': '',
    '无比': '',
    '极为': '',
    '尤为': '',
    '十分': '',
    '格外': '',
    '甚为': '',
    '着实': '',
  };

  /// Structural pattern regexes per D-10.
  /// These are highlighted with 【】 markers, not auto-replaced.
  /// Organized by pattern type for maintainability.
  static final List<RegExp> _structuralPatterns = [
    // --- 并列/递进结构 (Parallel/progressive) ---
    RegExp(r'不仅[^，。！？\n]{1,20}而且'),
    RegExp(r'不仅[^，。！？\n]{1,20}还'),
    RegExp(r'既[^，。！？\n]{1,12}又[^，。！？\n]{1,12}'),

    // --- 条件/让步结构 (Conditional/concessive) ---
    RegExp(r'无论[^，。！？\n]{1,20}，?[^。！？\n]{1,20}都'),
    RegExp(r'与其说[^，。！？\n]{2,15}，?不如说'),

    // --- 因果/推理结构 (Causal/reasoning) ---
    RegExp(r'随着[^，。！？\n]{1,20}的发展'),
    RegExp(r'在[^，。！？\n]{1,20}中，[^，。！？\n]{1,20}发挥了重要作用'),
    RegExp(r'因为[^，。！？\n]{2,25}，所以[^，。！？\n]{2,25}'),

    // --- 描写/比喻结构 (Description/metaphor) ---
    RegExp(r'仿佛[^，。！？\n]{2,20}一般'),
    RegExp(r'在[^，。！？\n]{2,12}的映衬下'),

    // --- 叙述/评价结构 (Narrative/evaluative) ---
    RegExp(r'让人不禁[^，。！？\n]{2,15}'),
    RegExp(r'正是[^，。！？\n]{2,20}使得[^，。！？\n]{2,20}'),
  ];

  static const List<String> _transitionCliches = [
    '与此同时',
    '就在这时',
    '不料',
    '忽然',
    '突然',
    '下一刻',
    '片刻之后',
  ];

  static const List<String> _xianxiaCliches = [
    '灵气涌动',
    '磅礴的力量',
    '眼中闪过一丝',
    '不由得',
    '倒吸一口凉气',
    '周身气息',
    '体内灵力',
    '剑气纵横',
  ];

  static const List<String> _formulaicEndings = [
    '一场更大的风暴',
    '真正的考验',
    '才刚刚开始',
    '等待着他',
    '命运的齿轮',
  ];

  /// Emotional cliches — phrases AI overuses to describe feelings.
  static const List<String> _emotionalCliches = [
    '心中涌起一股暖流',
    '眼眶微微湿润',
    '鼻子一酸',
    '暖流涌遍全身',
    '百感交集',
    '五味杂陈',
    '心如刀绞',
    '泪流满面',
    '一股暖意涌上心头',
    '不禁潸然泪下',
  ];

  /// Description formulas — generic scenic descriptions AI defaults to.
  static const List<String> _descriptionFormulas = [
    '宛如仙境',
    '美不胜收',
    '如诗如画',
    '美轮美奂',
    '心旷神怡',
    '沁人心脾',
    '引人入胜',
    '叹为观止',
  ];

  /// Processes the given [text] and returns a [ProcessingResult].
  ///
  /// [bannedPhrases] are additional phrases to remove (appended to the
  /// built-in synonym map). These are deleted (empty replacement).
  ProcessingResult process(String text, {required List<String> bannedPhrases}) {
    if (text.isEmpty) {
      return const ProcessingResult(processedText: '', highlights: []);
    }

    var processedText = text;
    final highlights = <TextHighlight>[];

    // Phase 1: Auto-replacement
    processedText = _applyAutoReplacements(processedText, highlights);

    // Phase 1b: Additional banned phrases from parameter
    if (bannedPhrases.isNotEmpty) {
      processedText = _applyExtraBannedPhrases(
        processedText,
        bannedPhrases,
        highlights,
      );
    }

    // Phase 2: Structural pattern highlighting
    processedText = _applyStructuralHighlights(processedText, highlights);

    // Build review signals on ORIGINAL text — detects AI patterns
    // even when Phase 1 auto-replaced some of them.
    final reviewSignals = _buildReviewSignals(text, highlights);

    return ProcessingResult(
      processedText: processedText,
      highlights: highlights,
      reviewSignals: reviewSignals,
    );
  }

  /// Applies auto-replacement from the fixed synonym map.
  String _applyAutoReplacements(String text, List<TextHighlight> highlights) {
    var result = text;
    for (final entry in _synonymMap.entries) {
      final phrase = entry.key;
      final replacement = entry.value;

      result = _replaceBoundaryAware(
        result,
        phrase,
        replacement,
        highlights,
        HighlightType.bannedWord,
      );
    }
    return result;
  }

  /// Applies additional banned phrases from the parameter.
  String _applyExtraBannedPhrases(
    String text,
    List<String> bannedPhrases,
    List<TextHighlight> highlights,
  ) {
    var result = text;
    for (final phrase in bannedPhrases) {
      result = _replaceBoundaryAware(
        result,
        phrase,
        '', // Delete extra banned phrases
        highlights,
        HighlightType.bannedWord,
      );
    }
    return result;
  }

  /// Boundary-aware replacement per Pitfall 5.
  ///
  /// Only replaces [phrase] when it is bounded by:
  /// - String start/end, OR
  /// - Whitespace/newline, OR
  /// - Chinese punctuation (。，！？；：""''（）【】《》…)
  String _replaceBoundaryAware(
    String text,
    String phrase,
    String replacement,
    List<TextHighlight> highlights,
    HighlightType type,
  ) {
    if (phrase.isEmpty) return text;

    var result = text;
    // Find all non-overlapping occurrences
    var offset = 0;
    while (true) {
      final index = result.indexOf(phrase, offset);
      if (index == -1) break;

      // Boundary check per Pitfall 5: not embedded in a longer CJK word
      if (!_isAtValidBoundary(result, index, phrase.length)) {
        offset = index + 1;
        continue;
      }

      // Record highlight before replacement shifts positions
      highlights.add(
        TextHighlight(
          start: index,
          end: index + phrase.length,
          originalText: phrase,
          type: type,
        ),
      );

      // Perform replacement
      result =
          result.substring(0, index) +
          replacement +
          result.substring(index + phrase.length);

      // Move offset past the replacement
      offset = index + replacement.length;
    }

    return result;
  }

  /// Checks if a code point is a CJK ideograph (potential word character).
  bool _isCjkChar(String char) {
    if (char.isEmpty) return false;
    final code = char.runes.first;
    return (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3400 && code <= 0x4DBF);
  }

  /// Checks whether a phrase occurrence at [index] in [text] has
  /// proper boundaries (not embedded in a longer word).
  ///
  /// Per Pitfall 5: A phrase is considered embedded in a longer word
  /// when BOTH the character before AND the character after are CJK
  /// ideographs. For example, "然而" in "自然而然" has "然" on both
  /// sides, so it's embedded. But "然而他" only has CJK after, so
  /// it's a valid standalone usage.
  bool _isAtValidBoundary(String text, int index, int phraseLength) {
    final beforeIsCjk = index > 0 && _isCjkChar(text[index - 1]);
    final afterIndex = index + phraseLength;
    final afterIsCjk = afterIndex < text.length && _isCjkChar(text[afterIndex]);

    // Only block when BOTH sides are CJK (phrase is embedded in a word)
    return !(beforeIsCjk && afterIsCjk);
  }

  /// Applies structural pattern highlighting with 【】 markers per D-10.
  String _applyStructuralHighlights(
    String text,
    List<TextHighlight> highlights,
  ) {
    var result = text;

    for (final pattern in _structuralPatterns) {
      var offset = 0;
      while (true) {
        final matches = pattern.allMatches(result, offset);
        final match = matches.firstOrNull;
        if (match == null) break;

        final matchedText = match.group(0)!;
        final start = match.start;
        final end = match.end;

        // Wrap with 【】 markers
        final marked = '【$matchedText】';
        result = result.substring(0, start) + marked + result.substring(end);

        highlights.add(
          TextHighlight(
            start: start,
            end: start + marked.length,
            originalText: matchedText,
            type: HighlightType.structuralPattern,
          ),
        );

        // Move offset past the marked text
        offset = start + marked.length;
      }
    }

    return result;
  }

  List<ReviewSignal> _buildReviewSignals(
    String text,
    List<TextHighlight> highlights,
  ) {
    final signals = <ReviewSignal>[];
    final transitionCount = _countPhraseHits(text, _transitionCliches);
    if (transitionCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '转场套话偏多',
          description: '连续使用常见转场词会让段落显得机械，建议作者手动调整节奏。',
          severity: transitionCount >= 4
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '$transitionCount 次',
        ),
      );
    }

    final genreClicheCount = _countPhraseHits(text, _xianxiaCliches);
    if (genreClicheCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '类型文套句偏多',
          description: '修仙常见短语重复出现，可能削弱作者自己的画面感。',
          severity: genreClicheCount >= 4
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '$genreClicheCount 次',
        ),
      );
    }

    final endingCount = _countPhraseHits(text, _formulaicEndings);
    if (endingCount > 0) {
      signals.add(
        ReviewSignal(
          title: '结尾悬念公式化',
          description: '章节收束出现常见钩子句式，采纳前建议改成更贴合当前人物选择的结尾。',
          severity: ReviewSignalSeverity.medium,
          evidence: '$endingCount 处',
        ),
      );
    }

    final sentenceLengths = _sentenceLengths(text);
    final rhythmScore = _sentenceRhythmUniformity(sentenceLengths);
    if (rhythmScore >= 0.72 && sentenceLengths.length >= 4) {
      signals.add(
        ReviewSignal(
          title: '句长节奏过于整齐',
          description: '多句长度接近会形成 AI 式匀速叙述，可穿插短句、动作或停顿。',
          severity: rhythmScore >= 0.85
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '${(rhythmScore * 100).round()}%',
        ),
      );
    }

    final structuralCount = highlights
        .where((h) => h.type == HighlightType.structuralPattern)
        .length;
    if (structuralCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '结构化句式重复',
          description: '多个句子被标记为套话结构，建议逐句确认是否符合角色和场景。',
          severity: ReviewSignalSeverity.medium,
          evidence: '$structuralCount 处',
        ),
      );
    }

    final emotionalClicheCount = _countPhraseHits(text, _emotionalCliches);
    if (emotionalClicheCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '情感描写套路化',
          description: '情感表达使用了常见套话短语，建议替换为更贴合角色和场景的独特描写。',
          severity: emotionalClicheCount >= 4
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '$emotionalClicheCount 处',
        ),
      );
    }

    final descriptionFormulaCount = _countPhraseHits(text, _descriptionFormulas);
    if (descriptionFormulaCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '描写公式化',
          description: '场景描写使用了通用形容词组合，建议加入具体感官细节让画面更独特。',
          severity: ReviewSignalSeverity.medium,
          evidence: '$descriptionFormulaCount 处',
        ),
      );
    }

    return signals;
  }

  int _countPhraseHits(String text, List<String> phrases) {
    var count = 0;
    for (final phrase in phrases) {
      var offset = 0;
      while (true) {
        final index = text.indexOf(phrase, offset);
        if (index == -1) break;
        count++;
        offset = index + phrase.length;
      }
    }
    return count;
  }

  List<int> _sentenceLengths(String text) {
    return text
        .split(RegExp(r'[。！？!?；;\n]+'))
        .map((s) => s.replaceAll(RegExp(r'\s+'), '').length)
        .where((length) => length >= 4)
        .toList();
  }

  double _sentenceRhythmUniformity(List<int> lengths) {
    if (lengths.length < 4) return 0;
    final average = lengths.reduce((a, b) => a + b) / lengths.length;
    if (average == 0) return 0;
    final variance =
        lengths
            .map((length) {
              final diff = length - average;
              return diff * diff;
            })
            .reduce((a, b) => a + b) /
        lengths.length;
    final coefficientOfVariation = math.sqrt(variance) / average;
    return (1 - coefficientOfVariation).clamp(0, 1);
  }
}
