/// Tests for the [AIException] sealed hierarchy, focusing on
/// [AIOfflineException] polymorphism and its distinct user-facing message.
///
/// [AIOfflineException] distinguishes "device is definitively offline"
/// (pre-flight fast-fail) from a generic network failure, so the UI can tell
/// the user to check their connection instead of suspecting the endpoint.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';

void main() {
  group('AIOfflineException', () {
    test('is an AINetworkException (polymorphic fallback)', () {
      // Existing `is AINetworkException` / `on AINetworkException` catch sites
      // (fetchModels connection test, provider_step_page, etc.) must still
      // classify an offline error as a network-class failure without edits.
      const e = AIOfflineException();
      expect(e, isA<AINetworkException>());
      expect(e, isA<AIException>());
    });

    test('surfaces a distinct offline userMessage', () {
      // The whole point of the subtype: distinguish "offline" from the generic
      // "网络连接失败" so the user knows to check their connection, not suspect
      // the endpoint is down.
      const e = AIOfflineException();
      expect(e.userMessage, '当前处于离线状态，请检查网络连接');
      expect(e.userMessage, isNot(equals('网络连接失败')));
    });

    test('default message matches userMessage for log clarity', () {
      // toString() surfaces [message]; aligning the default keeps diagnostics
      // readable ("AIOfflineException: 当前处于离线状态...") instead of a
      // generic "网络连接失败" that would hide the offline root cause.
      const e = AIOfflineException();
      expect(e.message, '当前处于离线状态，请检查网络连接');
      expect(e.toString(), contains('AIOfflineException'));
    });
  });
}
