import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/intent_preservation_analyzer.dart';

void main() {
  group('IntentPreservationAnalyzer', () {
    const analyzer = IntentPreservationAnalyzer();

    test('flags lost distinctive terms from original text', () {
      final signals = analyzer.analyze(
        originalText: '林风握着青铜玉简，想起苏雪晴在紫霄宫前说过的话。',
        aiText: '林风握着旧物，想起有人曾经说过的话。',
      );

      expect(signals.map((signal) => signal.title), contains('原文关键信息可能丢失'));
      expect(signals.first.evidence, contains('青铜玉简'));
    });

    test('flags excessive AI expansion', () {
      final signals = analyzer.analyze(
        originalText: '林风推门。',
        aiText:
            '林风缓缓推开那扇沉重的木门，潮湿的风从门缝里涌入，'
            '把他袖口吹得猎猎作响，也把走廊深处压抑已久的寒意送到眼前。',
      );

      expect(signals.map((signal) => signal.title), contains('AI 扩写幅度过大'));
    });

    test('flags dialogue removal', () {
      final signals = analyzer.analyze(
        originalText: '苏雪晴低声说：“别信赵天磊。”',
        aiText: '苏雪晴提醒林风不要相信赵天磊。',
      );

      expect(signals.map((signal) => signal.title), contains('对话语气可能被削弱'));
    });

    test('returns no signals for close paraphrase', () {
      final signals = analyzer.analyze(
        originalText: '林风握紧木剑，沿着青云山石阶向上走。',
        aiText: '林风攥紧木剑，顺着青云山的石阶继续向上。',
      );

      expect(signals, isEmpty);
    });
  });
}
