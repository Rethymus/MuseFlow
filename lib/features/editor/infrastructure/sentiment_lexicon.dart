/// Chinese sentiment lexicon for basic emotional tone analysis.
///
/// Contains static word lists for positive and negative sentiment words
/// commonly used in Chinese prose. Used by [StyleAnalyzer] to compute
/// the emotionalTone dimension of an [AuthorStyleProfile].
///
/// These lists are curated from common Chinese NLP sentiment resources
/// and filtered for literary/relevance contexts.
library;

/// Lexicon of Chinese sentiment words for emotional tone analysis.
class SentimentLexicon {
  SentimentLexicon._();

  /// Positive/warm sentiment words (~200 entries).
  static const Set<String> positiveWords = {
    // 温暖/幸福
    '温暖', '温馨', '幸福', '快乐', '喜悦', '欢笑', '微笑', '甜美', '温柔',
    '慈爱', '关怀', '呵护', '珍惜', '感恩', '感动', '欣慰', '安心', '宁静',
    '祥和', '和睦', '融洽', '亲切', '友善', '善良', '纯真', '美好', '光明',
    '希望', '阳光', '明朗', '清澈', '纯净', '真挚', '忠诚', '勇敢', '坚强',
    '自信', '骄傲', '自豪', '荣耀', '尊严', '高贵', '优雅', '端庄', '从容',
    '淡然', '安详', '恬静', '悠然', '自在', '洒脱', '豁达', '宽容',
    '包容', '理解', '信任', '尊重', '敬佩', '赞赏', '称赞', '鼓励', '支持',
    '陪伴', '守护', '庇护', '相守', '相伴', '携手', '并肩', '拥抱', '依偎',
    // 自然/美好
    '春风', '明月', '清风', '花香', '鸟鸣', '溪流', '山峦', '云朵',
    '繁星', '晨曦', '暮色', '彩虹', '露珠', '雪花', '细雨', '微风', '碧空',
    '青山', '绿水', '翠竹', '红梅', '兰花', '荷花', '桂花', '松柏',
    // 力量/积极
    '奋起', '崛起', '腾飞', '翱翔', '冲刺', '突破', '超越', '升华',
    '蜕变', '觉醒', '顿悟', '领悟', '明悟', '洞察', '明智', '睿智',
    '英明', '果断', '坚决', '坚毅', '刚毅', '无畏', '无惧', '不怕',
  };

  /// Negative/cold sentiment words (~200 entries).
  static const Set<String> negativeWords = {
    // 悲伤/痛苦
    '悲伤', '痛苦', '哀伤', '凄凉', '孤独', '寂寞', '落寞', '空虚', '绝望',
    '无助', '无奈', '迷茫', '彷徨', '惆怅', '忧伤', '忧愁', '苦涩', '辛酸',
    '心酸', '酸楚', '凄惨', '悲惨', '惨烈', '残酷', '无情', '冷漠', '冷酷',
    '冷血', '冰冷', '寒意', '阴冷', '阴暗', '黑暗', '深渊', '泥潭', '困境',
    // 愤怒/对抗
    '愤怒', '暴怒', '狂怒', '恼怒', '怨恨', '仇恨', '憎恨', '嫉妒', '嫉恨',
    '敌意', '杀意', '恶意', '歹意', '歹心', '野心', '贪心', '私心', '虚荣',
    '傲慢', '轻蔑', '蔑视', '鄙视', '嘲笑', '讥讽', '嘲讽', '讽刺', '挖苦',
    '侮辱', '羞辱', '屈辱', '耻辱', '愧疚', '懊悔', '悔恨', '悔过', '忏悔',
    // 恐惧/不安
    '恐惧', '害怕', '惊恐', '恐慌', '畏惧', '战栗', '颤抖', '发抖', '紧张',
    '焦虑', '不安', '惶恐', '慌乱', '慌张', '惊慌', '惊愕', '震惊',
    '错愕', '茫然', '不知所措', '心惊肉跳', '毛骨悚然', '胆寒', '心寒',
    // 破坏/消极
    '毁灭', '破坏', '摧残', '蹂躏', '践踏', '抛弃', '遗弃', '背叛', '出卖',
    '欺骗', '谎言', '虚伪', '狡诈', '阴险', '恶毒', '毒辣', '残忍', '暴虐',
    '贪婪', '腐败', '堕落', '沉沦', '崩溃', '瓦解', '消亡', '灭亡', '死亡',
  };

  /// Count positive words in text.
  static int countPositive(String text) {
    var count = 0;
    for (final word in positiveWords) {
      var offset = 0;
      while (true) {
        final index = text.indexOf(word, offset);
        if (index == -1) break;
        count++;
        offset = index + word.length;
      }
    }
    return count;
  }

  /// Count negative words in text.
  static int countNegative(String text) {
    var count = 0;
    for (final word in negativeWords) {
      var offset = 0;
      while (true) {
        final index = text.indexOf(word, offset);
        if (index == -1) break;
        count++;
        offset = index + word.length;
      }
    }
    return count;
  }

  /// Compute warmth score (0.0–1.0) from positive/negative word counts.
  ///
  /// Higher = warmer/more positive tone.
  static double warmthScore(int positiveCount, int negativeCount) {
    final total = positiveCount + negativeCount;
    if (total == 0) return 0.5; // neutral
    return (positiveCount / total).clamp(0.0, 1.0);
  }

  /// Compute intensity score (0.0–1.0) from total sentiment word density.
  ///
  /// Higher = more emotionally intense text.
  static double intensityScore(
    int positiveCount,
    int negativeCount,
    int totalChars,
  ) {
    if (totalChars < 100) return 0.3; // too short to measure
    final density = (positiveCount + negativeCount) / (totalChars / 100);
    // Normalize: ~2 sentiment words per 100 chars = moderate intensity
    return (density / 4.0).clamp(0.0, 1.0);
  }

  /// Classify overall tone from warmth and intensity.
  static String classifyTone(double warmth, double intensity) {
    if (intensity < 0.3) {
      return warmth > 0.5 ? '平静温和' : '冷静克制';
    }
    if (warmth > 0.6) {
      return intensity > 0.6 ? '热烈奔放' : '温暖明亮';
    }
    if (warmth < 0.4) {
      return intensity > 0.6 ? '沉重压抑' : '冷淡疏离';
    }
    return intensity > 0.6 ? '张力充沛' : '张弛有度';
  }
}
