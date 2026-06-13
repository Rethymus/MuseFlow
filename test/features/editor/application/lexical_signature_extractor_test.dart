/// Tests for [LexicalSignatureExtractor].
///
/// Validates the n-gram extraction pipeline: CJK segmentation, bigram/trigram
/// generation, stopword filtering, salience ranking (trigram 1.5 > bigram 1.0),
/// and maxTerms truncation. Pure function, no IO.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/lexical_signature_extractor.dart';
import 'package:museflow/features/editor/domain/lexical_signature.dart';

void main() {
  group('LexicalSignatureExtractor.extract', () {
    test('high-frequency term should rank first', () {
      // "剑意" repeats far more than any other bigram.
      const text = '剑意凌厉剑意冲霄剑意纵横剑意不绝剑意浩荡';
      final sig = LexicalSignatureExtractor.extract(text);
      expect(sig.isEmpty, isFalse);
      expect(sig.topTerms.first.term, '剑意');
    });

    test('pure stopwords should be filtered out', () {
      // "的、了、是、在" repeated — these functional words carry no author style.
      const text = '的了的了是在是在了在的是的在在了是';
      final sig = LexicalSignatureExtractor.extract(text);
      for (final term in sig.topTerms) {
        // No returned term should be a bare functional word.
        expect(['的', '了', '是', '在'], isNot(contains(term.term)));
        // No returned n-gram should be composed solely of stopword chars.
        expect(_isAllStopword(term.term), isFalse,
            reason: 'stopword-only n-gram leaked into signature: ${term.term}');
      }
    });

    test('bigram and trigram extraction from "拔剑四顾"', () {
      const text = '拔剑四顾拔剑四顾拔剑四顾';
      final sig = LexicalSignatureExtractor.extract(text);
      final terms = sig.topTerms.map((t) => t.term).toSet();
      // bigrams
      expect(terms, containsAll(['拔剑', '剑四', '四顾']));
      // trigrams
      expect(terms, containsAll(['拔剑四', '剑四顾']));
    });

    test('empty / latin-only / punctuation-only input returns empty', () {
      expect(LexicalSignatureExtractor.extract('').isEmpty, isTrue);
      expect(LexicalSignatureExtractor.extract('hello world').isEmpty, isTrue);
      expect(LexicalSignatureExtractor.extract('，。！？').isEmpty, isTrue);
    });

    test('trigram weight (1.5) outranks bigram (1.0) at equal frequency', () {
      // "剑气浩" trigram appears 5 times → score = 5 * 1.5 = 7.5.
      // "剑气" bigram also appears 5 times → score = 5 * 1.0 = 5.0.
      // The trigram must rank strictly above the bigram.
      const text = '剑气浩荡剑气浩荡剑气浩荡剑气浩荡剑气浩荡';
      final sig = LexicalSignatureExtractor.extract(text);
      final terms = sig.topTerms;
      final trigram = terms
          .where((t) => t.term == '剑气浩')
          .fold<LexicalTerm?>(null, (_, t) => t);
      final bigram = terms
          .where((t) => t.term == '剑气')
          .fold<LexicalTerm?>(null, (_, t) => t);
      expect(trigram, isNotNull, reason: 'trigram 剑气浩 missing from signature');
      expect(bigram, isNotNull, reason: 'bigram 剑气 missing from signature');
      expect(trigram!.score, greaterThan(bigram!.score));
      // And the trigram should appear before the bigram in the sorted list.
      final trigramIndex = terms.indexWhere((t) => t.term == '剑气浩');
      final bigramIndex = terms.indexWhere((t) => t.term == '剑气');
      expect(trigramIndex, lessThan(bigramIndex));
    });

    test('maxTerms truncation', () {
      const text = '剑意凌厉剑气纵横剑光闪烁剑心通明剑势磅礴剑影重重剑灵觉醒剑阵玄妙剑诀奥义剑魂不灭剑骨铸成';
      final sig = LexicalSignatureExtractor.extract(text, maxTerms: 3);
      expect(sig.topTerms.length, lessThanOrEqualTo(3));
    });
  });
}

bool _isAllStopword(String gram) {
  const stopwords = {'的', '了', '是', '在', '和', '与', '或', '我', '你',
      '他', '她', '它', '们', '这', '那', '一', '个', '上', '下', '不',
      '也', '都', '就', '还', '又', '把', '被', '让', '给', '向', '从',
      '到', '于', '以', '为', '而', '则', '其', '之', '着', '过', '地',
      '得', '所', '等', '吗', '呢', '吧', '啊', '呀', '哦', '么', '里',
      '中', '人', '有', '无', '说', '道', '看', '想'};
  return gram.runes.every((r) => stopwords.contains(String.fromCharCode(r)));
}
