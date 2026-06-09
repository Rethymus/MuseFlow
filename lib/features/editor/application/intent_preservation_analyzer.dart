import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';

/// Compares the author's selected text with AI output and surfaces
/// author-facing review signals before the user accepts the change.
class IntentPreservationAnalyzer {
  const IntentPreservationAnalyzer();

  List<ReviewSignal> analyze({
    required String originalText,
    required String aiText,
  }) {
    if (originalText.trim().isEmpty || aiText.trim().isEmpty) {
      return const [];
    }

    final signals = <ReviewSignal>[];
    final lostTerms = _lostDistinctiveTerms(originalText, aiText);
    if (lostTerms.isNotEmpty) {
      signals.add(
        ReviewSignal(
          title: '原文关键信息可能丢失',
          description: 'AI 输出没有保留部分专名或强记忆词，采纳前请确认是否偏离作者原意。',
          severity: lostTerms.length >= 3
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: lostTerms.take(4).join('、'),
        ),
      );
    }

    final lengthRatio = _lengthRatio(originalText, aiText);
    if (lengthRatio >= 2.4) {
      signals.add(
        ReviewSignal(
          title: 'AI 扩写幅度过大',
          description: '输出长度明显超过原文，可能加入作者未确认的动作、情绪或设定。',
          severity: lengthRatio >= 3.5
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '${lengthRatio.toStringAsFixed(1)}x',
        ),
      );
    } else if (lengthRatio <= 0.45 && originalText.trim().length >= 20) {
      signals.add(
        ReviewSignal(
          title: 'AI 压缩幅度过大',
          description: '输出明显短于原文，可能删掉铺垫、语气或人物关系信息。',
          severity: ReviewSignalSeverity.medium,
          evidence: '${lengthRatio.toStringAsFixed(1)}x',
        ),
      );
    }

    if (_dialogueMarkerCount(originalText) > _dialogueMarkerCount(aiText)) {
      signals.add(
        const ReviewSignal(
          title: '对话语气可能被削弱',
          description: '原文含有对话标记，但 AI 输出减少了对话，需确认角色声音是否仍然存在。',
          severity: ReviewSignalSeverity.medium,
          evidence: '对话减少',
        ),
      );
    }

    return signals;
  }

  List<String> _lostDistinctiveTerms(String originalText, String aiText) {
    final originalTerms = _distinctiveTerms(originalText);
    if (originalTerms.isEmpty) return const [];
    return originalTerms.where((term) => !aiText.contains(term)).toList();
  }

  List<String> _distinctiveTerms(String text) {
    final terms = <String>[];
    final seen = <String>{};

    void addTerm(String term) {
      if (term.isEmpty) return;
      if (_isCommonTerm(term) || !seen.add(term)) return;
      terms.add(term);
    }

    void addMatches(RegExp pattern) {
      for (final match in pattern.allMatches(text)) {
        addTerm(match.group(0)!);
      }
    }

    void addPersonNameMatches(RegExp pattern) {
      for (final match in pattern.allMatches(text)) {
        final term = match.group(0)!;
        if (_looksLikeFalsePersonName(term)) continue;
        addTerm(term);
      }
    }

    void addIntentAnchorMatches(RegExp pattern) {
      for (final match in pattern.allMatches(text)) {
        addTerm(_normalizeIntentAnchor(match.group(0)!));
      }
    }

    addMatches(RegExp(r'[A-Za-z][A-Za-z0-9_-]{2,}'));
    addPersonNameMatches(
      RegExp(
        r'[赵钱孙李周吴郑王冯陈褚卫蒋沈韩杨朱秦尤许何吕施张孔曹严华金魏陶姜谢邹喻柏水窦章云苏潘葛奚范彭郎鲁韦昌马苗凤花方俞任袁柳鲍史唐费廉岑薛雷贺倪汤滕殷罗毕郝邬安常乐于时傅皮卞齐康伍余元卜顾孟平黄和穆萧尹姚邵湛汪祁毛禹狄米贝明臧计伏成戴谈宋庞熊纪舒屈项祝董梁杜阮蓝闵席季麻强贾路娄危江童颜郭梅盛林刁钟徐邱骆高夏蔡田胡凌霍虞万支柯管卢莫房裘缪干解应宗丁宣邓郁单杭洪包左石崔吉龚程邢裴陆荣翁荀羊惠曲家封靳段富焦巴牧车侯全秋仲宫宁甘厉祖武符刘景詹龙叶幸司韶黎薄宿白怀蒲从索赖卓蔺蒙池乔能苍闻党翟谭贡姬申冉宰桑桂牛寿通边扈燕尚农温庄柴阎慕连习艾鱼向古易慎戈廖终居衡步都耿满弘匡国文寇广东欧沃利越隆师巩聂晁勾敖融冷辛那简饶空曾养鞠须丰关相查荆红游竺权盖益桓公][一-龥]{1,2}',
      ),
    );
    addIntentAnchorMatches(
      RegExp(r'[一-龥]{1,4}(?:玉简|真人|长老|山|宫|宗|门|城|谷|殿|峰|剑|符|丹|阵|诀)'),
    );

    return terms;
  }

  String _normalizeIntentAnchor(String term) {
    return term
        .replaceFirst(RegExp(r'^.*?(握紧|攥紧|握着|拿着|捧着|沿着|顺着|想起|看见|走向|来到)'), '')
        .replaceFirst(RegExp(r'^(握紧|攥紧|握着|拿着|捧着|沿着|顺着|想起|看见|走向|来到)'), '')
        .replaceFirst(RegExp(r'^(那座|这座|那柄|这柄|那张|这张|那枚|这枚|一柄|一张|一枚)'), '');
  }

  bool _looksLikeFalsePersonName(String term) {
    if (term.length < 2 || term.length > 3) return false;
    if (RegExp(r'[A-Za-z]').hasMatch(term)) return false;
    return RegExp(
      r'[山石阶剑宫宗门城谷殿峰玉简符丹阵诀向上下前后走来去入出回握紧攥拿捧看想]',
    ).hasMatch(term.substring(1));
  }

  bool _isCommonTerm(String term) {
    const commonTerms = {
      '他们',
      '我们',
      '你们',
      '自己',
      '时候',
      '已经',
      '没有',
      '只是',
      '因为',
      '所以',
      '但是',
      '然后',
      '这里',
      '那里',
      '眼前',
      '心中',
      '握紧',
      '攥紧',
      '沿着',
      '顺着',
      '继续',
      '向上',
    };
    return commonTerms.contains(term);
  }

  double _lengthRatio(String originalText, String aiText) {
    final originalLength = originalText.trim().length;
    if (originalLength == 0) return 1;
    return aiText.trim().length / originalLength;
  }

  int _dialogueMarkerCount(String text) {
    return RegExp(r'[“”"「」『』：:]').allMatches(text).length;
  }
}
