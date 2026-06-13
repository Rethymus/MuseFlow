/// CJK stopword grams for n-gram filtering.
///
/// Contains high-frequency functional/grammatical words that carry no author
/// style information. Used by [LexicalSignatureExtractor] to discard
/// meaningless n-grams so the signature reflects the author's characteristic
/// content words rather than structural filler.
///
/// Pure Dart static lexicon (mirrors [SentimentLexicon] pattern).
library;

/// High-frequency CJK functional/grammatical grams.
///
/// Criterion: only words that are high-frequency in *any* Chinese text and
/// carry no author style information. Content words (nouns/verbs/adjective
/// combinations such as 剑意, 凌厉) are deliberately excluded — those are
/// exactly the author-characteristic terms the signature must capture.
class CjkStopwords {
  CjkStopwords._();

  /// Single-character and multi-character functional grams (~60 entries).
  static const Set<String> grams = {
    // Single-char function words
    '的', '了', '是', '在', '和', '与', '或', '我', '你', '他', '她', '它',
    '们', '这', '那', '一', '个', '上', '下', '不', '也', '都', '就', '还',
    '又', '把', '被', '让', '给', '向', '从', '到', '于', '以', '为', '而',
    '则', '其', '之', '着', '过', '地', '得', '所', '等', '吗', '呢', '吧',
    '啊', '呀', '哦', '么', '里', '中', '人', '有', '无', '说', '道', '看',
    '想',
    // Multi-char functional grams
    '知道', '一个', '这个', '那个', '的话', '什么', '怎么', '可以', '没有',
    '我们', '他们', '这是', '那是', '就是', '是的', '了一', '的一', '看着',
    '说着', '想着', '这样', '那样', '一样',
  };
}
