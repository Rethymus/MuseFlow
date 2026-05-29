import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/models/intent_confirmation.dart';
import 'package:museflow/services/intent_analyzer.dart';

void main() {
  group('意图确认系统测试', () {
    late IntentAnalyzer intentAnalyzer;

    setUp(() {
      intentAnalyzer = IntentAnalyzer();
    });

    test('应该正确分析润色意图', () {
      const testText = '这是一个测试文本。';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: testText,
      );

      expect(intent.actionType, AIActionType.polish);
      expect(intent.originalText, testText);
      expect(intent.description, contains('润色'));
      expect(intent.explanation, isNotEmpty);
      expect(intent.expectedOutcome, isNotEmpty);
    });

    test('应该正确分析扩写意图', () {
      const testText = '短文本';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.expand,
        originalText: testText,
        additionalParams: {
          'targetLength': 100,
        },
      );

      expect(intent.actionType, AIActionType.expand);
      expect(intent.parameters['target_length'], 100);
      expect(intent.description, contains('扩写'));
    });

    test('应该正确分析大纲意图', () {
      const testText = '第一个观点。第二个观点。第三个观点。';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.outline,
        originalText: testText,
      );

      expect(intent.actionType, AIActionType.outline);
      expect(intent.description, contains('大纲'));
      expect(intent.parameters['total_sentences'], greaterThan(0));
    });

    test('应该正确分析摘要意图', () {
      final testText = '这是一段较长的文本，需要生成摘要。' * 10;

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.summarize,
        originalText: testText,
        additionalParams: {
          'maxLength': 50,
        },
      );

      expect(intent.actionType, AIActionType.summarize);
      expect(intent.parameters['max_length'], 50);
      expect(intent.parameters['original_length'], testText.length);
    });

    test('应该正确分析风格转换意图', () {
      const testText = '这是要转换风格的文本。';
      const targetStyle = '正式';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.changeStyle,
        originalText: testText,
        additionalParams: {
          'targetStyle': targetStyle,
        },
      );

      expect(intent.actionType, AIActionType.changeStyle);
      expect(intent.parameters['target_style'], targetStyle);
      expect(intent.description, contains(targetStyle));
    });

    test('应该正确分析智能替换意图', () {
      const testText = '这是要替换的文本。';
      const findText = '替换';
      const replaceWith = '修改';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.smartReplace,
        originalText: testText,
        additionalParams: {
          'findText': findText,
          'replaceWith': replaceWith,
        },
      );

      expect(intent.actionType, AIActionType.smartReplace);
      expect(intent.parameters['find_text'], findText);
      expect(intent.parameters['replace_with'], replaceWith);
    });

    test('应该正确检测文本特征', () {
      const grammarIssuesText = '这有一些语法错误。。和重复的的字符。';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: grammarIssuesText,
      );

      expect(intent.explanation, contains('修正'));
    });

    test('应该正确记录和统计反馈', () {
      const testText = '测试文本';

      final intent1 = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: testText,
      );

      intentAnalyzer.recordFeedback(
        IntentConfirmationFeedback(
          intentId: intent1.id,
          confirmed: true,
        ),
      );

      final intent2 = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.expand,
        originalText: testText,
      );

      intentAnalyzer.recordFeedback(
        IntentConfirmationFeedback(
          intentId: intent2.id,
          confirmed: false,
        ),
      );

      final stats = intentAnalyzer.getFeedbackStatistics();

      expect(stats['total'], 2);
      expect(stats['confirmed'], 1);
      expect(stats['rejected'], 1);
      expect(stats['confirmation_rate'], 0.5);
    });

    test('应该正确生成包含上下文的润色意图', () {
      const testText = '这是要润色的文本。';
      const context = '这是上下文信息。';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: testText,
        additionalParams: {
          'context': context,
        },
      );

      expect(intent.parameters['context'], context);
      expect(intent.explanation, contains('上下文'));
    });

    test('应该正确生成带目标长度的扩写意图', () {
      const testText = '短文本';
      const targetLength = 200;

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.expand,
        originalText: testText,
        additionalParams: {
          'targetLength': targetLength,
        },
      );

      expect(intent.parameters['target_length'], targetLength);
      expect(intent.parameters['expand_ratio'], isNotEmpty);
    });

    test('意图确认应该支持复制和更新', () {
      const testText = '原始文本';

      final intent = IntentConfirmation.polish(
        originalText: testText,
      );

      final updatedIntent = intent.copyWith(
        description: '更新的描述',
      );

      expect(updatedIntent.originalText, testText);
      expect(updatedIntent.description, '更新的描述');
      expect(intent.description, isNot('更新的描述'));
    });

    test('意图确认应该支持序列化', () {
      const testText = '测试文本';

      final intent = IntentConfirmation.polish(
        originalText: testText,
      );

      final json = intent.toJson();
      final restored = IntentConfirmation.fromJson(json);

      expect(restored.actionType, intent.actionType);
      expect(restored.originalText, intent.originalText);
      expect(restored.description, intent.description);
    });

    test('应该正确处理空文本', () {
      const emptyText = '';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: emptyText,
      );

      expect(intent.originalText, emptyText);
      expect(intent.explanation, isNotEmpty);
    });

    test('应该正确处理长文本', () {
      final longText = '这是一段较长的文本。' * 50;

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.summarize,
        originalText: longText,
        additionalParams: {
          'maxLength': 100,
        },
      );

      expect(intent.originalText.length, longText.length);
      expect(intent.parameters['compression_ratio'], isNotEmpty);
    });

    test('应该正确清除反馈历史', () {
      const testText = '测试文本';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: testText,
      );

      intentAnalyzer.recordFeedback(
        IntentConfirmationFeedback(
          intentId: intent.id,
          confirmed: true,
        ),
      );

      expect(intentAnalyzer.getFeedbackStatistics()['total'], 1);

      intentAnalyzer.clearFeedbackHistory();

      expect(intentAnalyzer.getFeedbackStatistics()['total'], 0);
    });

    test('应该正确处理调整后的意图', () {
      const testText = '原始文本';

      final intent = IntentConfirmation.polish(
        originalText: testText,
      );

      final adjustedIntent = intent.copyWith(
        description: '调整后的描述',
        parameters: {
          'custom_param': 'value',
        },
      );

      final feedback = IntentConfirmationFeedback(
        intentId: intent.id,
        confirmed: true,
        adjustedDescription: adjustedIntent.description,
        adjustedParameters: adjustedIntent.parameters,
      );

      expect(feedback.adjustedDescription, '调整后的描述');
      expect(
          feedback.adjustedParameters, containsPair('custom_param', 'value'));
    });

    test('应该正确生成预期效果描述', () {
      const testText = '测试文本';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: testText,
      );

      expect(intent.expectedOutcome, isNotEmpty);
      expect(intent.expectedOutcome, contains('润色'));
    });

    test('应该正确处理中文文本', () {
      const chineseText = '这是中文文本。包含一些特殊字符：！@#￥%……&*（）';

      final intent = intentAnalyzer.analyzeRequest(
        actionType: AIActionType.polish,
        originalText: chineseText,
      );

      expect(intent.originalText, chineseText);
      expect(intent.explanation, contains('中文'));
    });

    test('应该正确生成唯一ID', () {
      const testText = '测试文本';

      final intent1 = IntentConfirmation.polish(
        originalText: testText,
      );

      final intent2 = IntentConfirmation.polish(
        originalText: testText,
      );

      expect(intent1.id, isNot(equals(intent2.id)));
    });
  });

  group('意图确认模型测试', () {
    test('应该正确创建润色意图', () {
      const text = '测试文本';
      const context = '上下文';

      final intent = IntentConfirmation.polish(
        originalText: text,
        context: context,
      );

      expect(intent.actionType, AIActionType.polish);
      expect(intent.originalText, text);
      expect(intent.parameters['context'], context);
    });

    test('应该正确创建扩写意图', () {
      const text = '测试文本';
      const targetLength = 200;

      final intent = IntentConfirmation.expand(
        originalText: text,
        targetLength: targetLength,
      );

      expect(intent.actionType, AIActionType.expand);
      expect(intent.parameters['target_length'], targetLength);
    });

    test('应该正确创建大纲意图', () {
      const text = '测试文本。包含多个句子。';

      final intent = IntentConfirmation.outline(
        originalText: text,
      );

      expect(intent.actionType, AIActionType.outline);
      expect(intent.parameters['max_items'], isNotNull);
    });

    test('应该正确创建摘要意图', () {
      const text = '测试文本';
      const maxLength = 100;

      final intent = IntentConfirmation.summarize(
        originalText: text,
        maxLength: maxLength,
      );

      expect(intent.actionType, AIActionType.summarize);
      expect(intent.parameters['max_length'], maxLength);
    });

    test('应该正确创建风格转换意图', () {
      const text = '测试文本';
      const style = '正式';

      final intent = IntentConfirmation.changeStyle(
        originalText: text,
        targetStyle: style,
      );

      expect(intent.actionType, AIActionType.changeStyle);
      expect(intent.parameters['target_style'], style);
    });

    test('应该正确创建智能替换意图', () {
      const text = '这是要替换的文本。';
      const find = '替换';
      const replace = '修改';

      final intent = IntentConfirmation.smartReplace(
        originalText: text,
        findText: find,
        replaceWith: replace,
      );

      expect(intent.actionType, AIActionType.smartReplace);
      expect(intent.parameters['find_text'], find);
      expect(intent.parameters['replace_with'], replace);
    });
  });

  group('意图反馈测试', () {
    test('应该正确创建确认反馈', () {
      const intentId = 'test_intent_123';

      final feedback = IntentConfirmationFeedback(
        intentId: intentId,
        confirmed: true,
      );

      expect(feedback.intentId, intentId);
      expect(feedback.confirmed, true);
    });

    test('应该正确创建拒绝反馈', () {
      const intentId = 'test_intent_123';

      final feedback = IntentConfirmationFeedback(
        intentId: intentId,
        confirmed: false,
        userComment: '不符合我的预期',
      );

      expect(feedback.confirmed, false);
      expect(feedback.userComment, '不符合我的预期');
    });

    test('应该支持反馈序列化', () {
      const intentId = 'test_intent_123';

      final feedback = IntentConfirmationFeedback(
        intentId: intentId,
        confirmed: true,
        adjustedDescription: '调整后的描述',
      );

      final json = feedback.toJson();
      final restored = IntentConfirmationFeedback.fromJson(json);

      expect(restored.intentId, intentId);
      expect(restored.confirmed, true);
      expect(restored.adjustedDescription, '调整后的描述');
    });
  });
}
