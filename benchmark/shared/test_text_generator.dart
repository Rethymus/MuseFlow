/// Deterministic Chinese text generator for editor benchmarking.
///
/// Generates realistic Chinese prose at specified character counts using a
/// fixed seed so both editors receive identical input. Produces paragraphs
/// of 200-500 characters with mixed punctuation commonly used in Chinese
/// novel writing.
library;

import 'dart:math';

/// A deterministic random number generator for reproducible test text.
class TestTextGenerator {
  TestTextGenerator({int seed = 42}) : _random = Random(seed);

  final Random _random;

  /// Chinese characters pool (common novel vocabulary).
  static const String _chars =
      '的一是不了人我在有他这为之大来以个中上们到说时地也子就道出会三要于下得'
      '你年生生自前面又定只从现开些长明样已全才将与日此情光里如更别它其后然门被'
      '天所去二能用入理方多点都活当没心动意无知法家风十第公使相本给等产者所世'
      '间正新话林山手度化厂交代少年果近乎表万格回几关做接角统规决常平感该信合'
      '望政治展对容带处必完件系品组数原老或强计社件平直她里经主造反量推其及特'
      '体改已交便处般指令群流交须何写六本按今帮终且则单行思放王走格具张望容'
      '画语春花风雪月山水云雨叶林峰石径桥亭台楼阁窗灯影梦境魂魄情念忆旧时归'
      '晓寒暖霜露阳晨暮夜星辰银金碧朱青翠紫红白黑灰影色笔墨纸砚书画诗词歌赋琴'
      '棋茶酒香苦酸甜辛辣咸味声光影视听思虑愁喜悦怒哀乐惊恐痴醉醒梦';

  /// Sentence-ending punctuation.
  static const String _sentenceEnds = '。！？';

  /// Clause punctuation (within sentences).
  static const String _clausePunct = '，、；：';

  /// Quote pairs for dialogue.
  static const List<List<String>> _quotePairs = [
    ['"', '"'],
    [''', '''],
    ['《', '》'],
  ];

  /// Generates Chinese text of exactly [charCount] characters (excluding
  /// formatting newlines). The output is deterministic for a given seed.
  String generate(int charCount) {
    final buffer = StringBuffer();
    var remaining = charCount;

    while (remaining > 0) {
      final paragraphLength = _clamp(
        _paragraphLength(),
        min: 1,
        max: remaining,
      );
      final paragraph = _generateParagraph(paragraphLength);
      buffer.write(paragraph);
      remaining -= paragraphLength;

      if (remaining > 0) {
        buffer.write('\n\n');
      }
    }

    return buffer.toString();
  }

  /// Generates a single paragraph of approximately [length] characters.
  String _generateParagraph(int length) {
    final buffer = StringBuffer();
    var remaining = length;

    while (remaining > 0) {
      // Occasionally insert dialogue
      if (_random.nextDouble() < 0.15 && remaining > 10) {
        final dialogue = _generateDialogue(remaining);
        buffer.write(dialogue.text);
        remaining -= dialogue.length;
        if (remaining > 0 && _random.nextBool()) {
          buffer.write(_clausePunct[_random.nextInt(_clausePunct.length)]);
          remaining--;
        }
        continue;
      }

      // Generate a clause (phrase between punctuation)
      final clauseLength = _clamp(
        _random.nextInt(12) + 4, // 4-15 chars per clause
        min: 1,
        max: remaining,
      );
      for (var i = 0; i < clauseLength && remaining > 0; i++) {
        buffer.write(_chars[_random.nextInt(_chars.length)]);
        remaining--;
      }

      if (remaining > 0) {
        // Add punctuation
        if (_random.nextDouble() < 0.25) {
          buffer.write(
            _sentenceEnds[_random.nextInt(_sentenceEnds.length)],
          );
        } else {
          buffer.write(
            _clausePunct[_random.nextInt(_clausePunct.length)],
          );
        }
        remaining--;
      }
    }

    return buffer.toString();
  }

  /// Generates a dialogue segment wrapped in quote marks.
  ({String text, int length}) _generateDialogue(int maxChars) {
    final pair = _quotePairs[_random.nextInt(_quotePairs.length)];
    final maxInner = maxChars - 3; // quotes + end punctuation
    if (maxInner < 2) {
      return (text: '', length: 0);
    }
    final innerLength = _clamp(
      _random.nextInt(maxInner - 2) + 2,
      min: 2,
      max: maxInner,
    );
    final buffer = StringBuffer(pair[0]);
    for (var i = 0; i < innerLength; i++) {
      buffer.write(_chars[_random.nextInt(_chars.length)]);
    }
    buffer.write(pair[1]);
    final endPunct =
        _sentenceEnds[_random.nextInt(_sentenceEnds.length)];
    buffer.write(endPunct);
    return (text: buffer.toString(), length: innerLength + 3);
  }

  /// Returns a random paragraph length between 200-500 characters.
  int _paragraphLength() => _random.nextInt(301) + 200;

  /// Clamps [value] between [min] and [max].
  int _clamp(int value, {required int min, required int max}) =>
      value < min ? min : (value > max ? max : value);
}

/// Predefined benchmark sizes matching the plan's document size steps.
enum BenchmarkSize {
  small10k(10000),
  medium50k(50000),
  large100k(100000),
  xlarge300k(300000);

  const BenchmarkSize(this.charCount);

  final int charCount;

  String get label {
    switch (this) {
      case BenchmarkSize.small10k:
        return '10K';
      case BenchmarkSize.medium50k:
        return '50K';
      case BenchmarkSize.large100k:
        return '100K';
      case BenchmarkSize.xlarge300k:
        return '300K';
    }
  }
}
