/// CJK stopword grams for n-gram filtering.
///
/// Split into two sets used by [LexicalSignatureExtractor]:
/// - [functionChars]: single-character function particles (pronouns,
///   particles, prepositions, conjunctions, aspect markers). An n-gram is
///   discarded if ANY of its characters is one of these.
/// - [functionPhrases]: multi-character functional words (知道/这个/没有…).
///   An n-gram is discarded on EXACT match.
///
/// **Curation rule:** only characters/words that are high-frequency in ANY
/// Chinese text and carry no author-style information belong here.
/// Content-bearing characters that form characteristic compounds are
/// deliberately excluded — e.g. 道 (道心/剑道), 人 (人间/人心), 有 (有意),
/// 看 (看破), 想 (想象), 无 (无心/无敌), 说 (说话), 里 (心里/梦里),
/// 中 (心中/手中). Filtering those would silently drop exactly the
/// author-characteristic vocabulary the signature exists to capture.
///
/// Pure Dart static lexicon (mirrors [SentimentLexicon] pattern).
library;

/// High-frequency CJK functional grams for n-gram filtering.
class CjkStopwords {
  CjkStopwords._();

  /// Single-character function particles.
  ///
  /// An n-gram containing ANY of these characters is discarded. These are
  /// pure grammatical function words — pronouns, particles, prepositions,
  /// conjunctions, aspect markers — that never form author-characteristic
  /// content compounds.
  static const Set<String> functionChars = {
    // particles / aspect
    '的', '了', '着', '过', '地', '得',
    // copula / negation
    '是', '不',
    // pronouns
    '我', '你', '他', '她', '它', '们',
    // demonstratives
    '这', '那',
    // numeral / classifier
    '一', '个',
    // locatives (kept: mostly structural; content compounds like 天下 are
    // rarer than functional 上下/之下 usage)
    '上', '下', '在',
    // conjunctions
    '和', '与', '或', '而', '则',
    // prepositions / coverbs
    '把', '被', '让', '给', '向', '从', '到', '于', '以', '为',
    // classical function
    '其', '之',
    // adverbs (high-frequency, style-neutral)
    '也', '都', '就', '还', '又',
    // misc functional
    '所', '等',
    // sentence-final particles
    '吗', '呢', '吧', '啊', '呀', '哦', '么',
  };

  /// Multi-character functional words.
  ///
  /// An n-gram matching ANY of these EXACTLY is discarded. These are
  /// high-frequency functional bigrams whose constituent characters are not
  /// themselves single-char function particles (知道/这个), so the per-char
  /// filter alone would let them leak.
  static const Set<String> functionPhrases = {
    // common functional bigrams
    '知道', '可以', '没有',
    '什么', '怎么', '的话',
    '这个', '那个', '这是', '那是', '就是', '是的',
    '这样', '那样', '一样',
    // pronoun compounds
    '我们', '他们',
    // narration/dialogue tags (style-neutral scaffolding)
    '说道', '看着', '想着',
  };
}
