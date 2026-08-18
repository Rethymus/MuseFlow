import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/utils/friendly_error.dart';

void main() {
  test('maps StateError without leaking "Bad state"', () {
    final message = friendlyError(
      StateError('Failed to read character cards: TypeError: boom'),
    );
    expect(message, '数据读取失败，请重试');
    expect(message.contains('Bad state'), isFalse);
    expect(message.contains('TypeError'), isFalse);
  });

  test('maps minified web type errors', () {
    final message = friendlyError(
      'TypeError: Instance of minified:jN<dynamic, dynamic> is not a subtype',
    );
    expect(message, '数据格式异常，请重试');
  });

  test('maps missing AI provider', () {
    expect(friendlyError('Bad state: 未配置可用的 AI 模型'), contains('AI 模型'));
  });

  test('maps network failures', () {
    expect(friendlyError('Failed to fetch'), '网络连接失败，请检查网络');
  });

  test('falls back to a generic message for unknown errors', () {
    expect(friendlyError(Exception('anything else')), '操作失败，请稍后重试');
    expect(friendlyError(Exception('x'), fallback: '自定义'), '自定义');
  });
}
