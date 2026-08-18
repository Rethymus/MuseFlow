import 'package:flutter/foundation.dart';

/// Maps an arbitrary provider/repository error to user-facing Chinese copy.
///
/// SE-6: raw exceptions ("Bad state: ...", "TypeError: minified:jN<...>")
/// must not reach the UI — they leak implementation detail and give the
/// user no recovery path. The original error stays in [debugPrint] for
/// diagnosis; callers that need richer recovery actions (e.g. "去配置")
/// branch on the same signals themselves.
String friendlyError(Object error, {String fallback = '操作失败，请稍后重试'}) {
  final raw = error.toString();
  debugPrint('friendlyError: $raw');

  // Specific, actionable causes win over the generic StateError bucket —
  // e.g. StateError('未配置可用的 AI 模型') toString contains "Bad state".
  if (raw.contains('未配置')) {
    return '尚未配置可用的 AI 模型';
  }
  if (raw.contains('API Key') || raw.contains('401')) {
    return 'API Key 无效，请检查设置';
  }
  if (raw.contains('网络') ||
      raw.contains('Failed to fetch') ||
      raw.contains('SocketException')) {
    return '网络连接失败，请检查网络';
  }
  if (error is StateError || raw.contains('Bad state')) {
    return '数据读取失败，请重试';
  }
  if (raw.contains('TypeError') ||
      RegExp("type '.+' is not a subtype").hasMatch(raw)) {
    return '数据格式异常，请重试';
  }
  if (raw.contains('Box not found') || raw.contains('HiveError')) {
    return '本地存储尚未就绪，请稍后重试';
  }
  return fallback;
}
