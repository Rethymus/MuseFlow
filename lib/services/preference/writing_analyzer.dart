import 'dart:math';
import '../../models/user_preference.dart';

/// 写作分析器
/// 分析用户的写作风格和特征
class WritingAnalyzer {
  static WritingAnalyzer? _instance;

  WritingAnalyzer._();

  /// 获取单例实例
  static WritingAnalyzer get instance {
    _instance ??= WritingAnalyzer._();
    return _instance!;
  }

  /// 分析文本
  Future<WritingAnalysis> analyze(String text, {String? context}) async {
    final languageStyle = _detectLanguageStyle(text);
    final detailLevel = _detectDetailLevel(text);
    final paragraphStructure = _detectParagraphStructure(text);
    final sentenceComplexity = _detectSentenceComplexity(text);
    final keywords = _extractKeywords(text);
    final features = _extractFeatures(text);

    // 计算置信度
    final confidence = _calculateAnalysisConfidence(
      languageStyle,
      detailLevel,
      paragraphStructure,
      sentenceComplexity,
    );

    return WritingAnalysis.create(
      text: text,
      languageStyle: languageStyle,
      detailLevel: detailLevel,
      paragraphStructure: paragraphStructure,
      sentenceComplexity: sentenceComplexity,
      keywords: keywords,
      features: features,
      confidence: confidence,
    );
  }

  /// 检测语言风格
  LanguageStyle _detectLanguageStyle(String text) {
    if (text.isEmpty) return LanguageStyle.unknown;

    final formalIndicators = [
      RegExp(r'\b(?:因此|因而|故而|是以|基于|鉴于)\b'),
      RegExp(r'\b(?:务必|务必请|恳请|烦请)\b'),
      RegExp(r'[，。]'), // 标点符号使用
    ];

    final casualIndicators = [
      RegExp(r'\b(?:嗯|啊|吧|嘛|呢|啦)\b'),
      RegExp(r'\b(?:超|超级|特别|非常|真的很)\b'),
      RegExp(r'[!]{2,}'), // 多个感叹号
    ];

    int formalScore = 0;
    int casualScore = 0;

    for (final pattern in formalIndicators) {
      formalScore += pattern.allMatches(text).length;
    }

    for (final pattern in casualIndicators) {
      casualScore += pattern.allMatches(text).length;
    }

    if (formalScore > casualScore * 2) {
      return LanguageStyle.formal;
    } else if (casualScore > formalScore * 2) {
      return LanguageStyle.casual;
    } else if (formalScore > 0 || casualScore > 0) {
      return LanguageStyle.mixed;
    }

    return LanguageStyle.unknown;
  }

  /// 检测详细程度
  DetailLevel _detectDetailLevel(String text) {
    if (text.isEmpty) return DetailLevel.unknown;

    final wordCount = text.split(RegExp(r'\s+')).length;
    final charCount = text.length;
    final avgWordLength = charCount / max(wordCount, 1);

    // 检测详细程度指标
    final detailedIndicators = [
      RegExp(r'\b(?:具体来说|具体而言|详细地|全面地|深入地)\b'),
      RegExp(r'\b(?:包括|包含|涉及|涵盖|范围)\b'),
      RegExp(r'[，、；]'), // 列举标点
    ];

    final conciseIndicators = [
      RegExp(r'\b(?:简而言之|简言之|总之|综上)\b'),
      RegExp(r'\b(?:主要|关键|核心|要点)\b'),
    ];

    final int detailedScore = detailedIndicators
        .map((p) => p.allMatches(text).length)
        .reduce((a, b) => a + b);

    final int conciseScore = conciseIndicators
        .map((p) => p.allMatches(text).length)
        .reduce((a, b) => a + b);

    // 根据平均词长和指示词判断
    if (avgWordLength > 2.5 || detailedScore > 2) {
      return DetailLevel.detailed;
    } else if (avgWordLength > 2.0 || detailedScore > 0) {
      return DetailLevel.moderate;
    } else if (avgWordLength < 1.5 || conciseScore > 1) {
      return DetailLevel.concise;
    }

    return DetailLevel.unknown;
  }

  /// 检测段落结构
  ParagraphStructure _detectParagraphStructure(String text) {
    if (text.isEmpty) return ParagraphStructure.unknown;

    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    final avgParagraphLength =
        paragraphs.map((p) => p.trim().length).reduce((a, b) => a + b) /
            max(paragraphs.length, 1);

    if (avgParagraphLength < 100) {
      return ParagraphStructure.shortParagraphs;
    } else if (avgParagraphLength < 250) {
      return ParagraphStructure.mediumParagraphs;
    } else {
      return ParagraphStructure.longParagraphs;
    }
  }

  /// 检测句式复杂度
  SentenceComplexity _detectSentenceComplexity(String text) {
    if (text.isEmpty) return SentenceComplexity.unknown;

    final sentences = text.split(RegExp(r'[。.!?！？]'));
    final avgSentenceLength =
        sentences.map((s) => s.trim().length).reduce((a, b) => a + b) /
            max(sentences.length, 1);

    // 检测复杂句指示词
    final complexIndicators = [
      RegExp(r'\b(?:虽然|尽管|但是|然而|而且)\b'),
      RegExp(r'\b(?:因为|由于|所以|因此|因而)\b'),
      RegExp(r'\b(?:如果|假如|要是|倘若)\b'),
      RegExp(r'[，,]'), // 逗号表示从句
    ];

    final int complexScore = complexIndicators
        .map((p) => p.allMatches(text).length)
        .reduce((a, b) => a + b);

    if (avgSentenceLength < 20 && complexScore < 2) {
      return SentenceComplexity.simple;
    } else if (avgSentenceLength > 50 || complexScore > 5) {
      return SentenceComplexity.complex;
    } else if (complexScore > 0) {
      return SentenceComplexity.varied;
    }

    return SentenceComplexity.moderate;
  }

  /// 提取关键词
  List<String> _extractKeywords(String text) {
    if (text.isEmpty) return [];

    // 分词
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s一-龥]'), '')
        .split(RegExp(r'\s+'));

    // 过滤停用词
    final stopWords = {
      '的',
      '是',
      '在',
      '和',
      '或',
      '但',
      '与',
      '及',
      '等',
      '很',
      '也',
      '有',
      '为',
      '不',
      '了',
      '我',
      '你',
      '他',
      '她',
      '它',
      '我们',
      '你们',
      '他们',
      'the',
      'is',
      'and',
      'or',
      'but',
      'with',
      'very',
      'also',
      'this',
      'that',
      'have',
      'been',
      'were',
      'are',
      'was',
      'be',
      'do',
      'does',
      'did',
    };

    // 统计词频
    final wordFreq = <String, int>{};
    for (final word in words) {
      if (word.length > 1 && !stopWords.contains(word)) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    // 返回高频词
    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(20).map((e) => e.key).toList();
  }

  /// 提取文本特征
  Map<String, dynamic> _extractFeatures(String text) {
    if (text.isEmpty) return {};

    final sentences = text.split(RegExp(r'[。.!?！？]'));
    final words = text.split(RegExp(r'\s+'));
    final paragraphs = text.split(RegExp(r'\n\s*\n'));

    return {
      'charCount': text.length,
      'wordCount': words.length,
      'sentenceCount': sentences.length,
      'paragraphCount': paragraphs.length,
      'avgSentenceLength':
          sentences.map((s) => s.length).reduce((a, b) => a + b) /
              max(sentences.length, 1),
      'avgWordLength': text.length / max(words.length, 1),
      'avgParagraphLength':
          paragraphs.map((p) => p.length).reduce((a, b) => a + b) /
              max(paragraphs.length, 1),
      'punctuationRatio': _calculatePunctuationRatio(text),
      'uniqueWordRatio': _calculateUniqueWordRatio(words),
    };
  }

  /// 计算标点符号比例
  double _calculatePunctuationRatio(String text) {
    if (text.isEmpty) return 0.0;

    final punctuation = text.replaceAll(RegExp(r'[^\w\s一-龥]'), '');
    return punctuation.length / text.length;
  }

  /// 计算唯一词汇比例
  double _calculateUniqueWordRatio(List<String> words) {
    if (words.isEmpty) return 0.0;

    final uniqueWords = words.toSet();
    return uniqueWords.length / words.length;
  }

  /// 计算分析置信度
  double _calculateAnalysisConfidence(
    LanguageStyle languageStyle,
    DetailLevel detailLevel,
    ParagraphStructure paragraphStructure,
    SentenceComplexity sentenceComplexity,
  ) {
    double confidence = 0.0;
    int knownCount = 0;

    if (languageStyle != LanguageStyle.unknown) {
      knownCount++;
    }

    if (detailLevel != DetailLevel.unknown) {
      knownCount++;
    }

    if (paragraphStructure != ParagraphStructure.unknown) {
      knownCount++;
    }

    if (sentenceComplexity != SentenceComplexity.unknown) {
      knownCount++;
    }

    if (knownCount > 0) {
      confidence = knownCount / 4.0;
    }

    return confidence;
  }

  /// 比较两个文本的相似度
  double calculateSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    final words1 = _extractWords(text1);
    final words2 = _extractWords(text2);

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final set1 = words1.toSet();
    final set2 = words2.toSet();

    final intersection = set1.intersection(set2);
    final union = set1.union(set2);

    if (union.isEmpty) return 0.0;

    return intersection.length / union.length;
  }

  /// 提取词汇
  List<String> _extractWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s一-龥]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1)
        .toList();
  }

  /// 分析文本变化
  TextChangeAnalysis analyzeTextChange(String original, String modified) {
    final similarity = calculateSimilarity(original, modified);
    final originalWords = _extractWords(original);
    final modifiedWords = _extractWords(modified);

    final addedWords = modifiedWords.toSet().difference(originalWords.toSet());
    final removedWords =
        originalWords.toSet().difference(modifiedWords.toSet());

    return TextChangeAnalysis(
      similarity: similarity,
      addedWords: addedWords.toList(),
      removedWords: removedWords.toList(),
      modificationType: _classifyChange(original, modified, similarity),
    );
  }

  /// 分类文本变化类型
  ModificationType _classifyChange(
      String original, String modified, double similarity) {
    if (similarity > 0.95) {
      return ModificationType.grammar;
    } else if (similarity > 0.85) {
      return ModificationType.style;
    } else if (similarity > 0.7) {
      return ModificationType.vocabulary;
    } else if (modified.length > original.length * 1.2) {
      return ModificationType.expansion;
    } else if (modified.length < original.length * 0.8) {
      return ModificationType.simplification;
    } else {
      return ModificationType.structure;
    }
  }
}

/// 文本变化分析结果
class TextChangeAnalysis {
  final double similarity;
  final List<String> addedWords;
  final List<String> removedWords;
  final ModificationType modificationType;

  TextChangeAnalysis({
    required this.similarity,
    required this.addedWords,
    required this.removedWords,
    required this.modificationType,
  });

  @override
  String toString() {
    return 'TextChangeAnalysis(similarity: $similarity, '
        'modificationType: $modificationType, '
        'addedWords: ${addedWords.length}, '
        'removedWords: ${removedWords.length})';
  }
}
