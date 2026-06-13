/// Editorial review service — single audited LLM call producing a 4-dimension
/// advisory critique (情节/人物/文笔/节奏).
///
/// Mirrors [DeviationDetectionService] for consistency. Advisory only: the
/// prompt explicitly forbids rewriting prose (磨刀石 not 打字机).
library;

import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/reports/domain/editorial_review.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';

class EditorialReviewService {
  final AIAdapter openAIAdapter;
  final String apiKey;
  final String baseUrl;
  final String model;
  final TokenAuditService? auditService;

  const EditorialReviewService({
    required this.openAIAdapter,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.auditService,
  });

  /// Minimum trimmed text length to attempt a review.
  static const int minChars = 20;

  /// Reviews [text] across the 4 editorial dimensions via a single LLM call.
  ///
  /// Returns an [EditorialReview]. Too-short input or any failure yields a
  /// degraded review (never throws). When [auditService] is provided, the call
  /// is recorded as [AuditOperationType.editorialReview] for cost transparency.
  Future<EditorialReview> reviewChapter(
    String text, {
    String? manuscriptId,
    String? chapterId,
  }) async {
    if (text.trim().length < minChars) {
      return EditorialReview.degraded('文本过短，无法进行评审');
    }

    final prompt = _buildPrompt(text);
    final inputText = 'System: 你是资深中文小说编辑，从四个维度评审。\nUser: $prompt';

    try {
      final buffer = StringBuffer();
      final stream = openAIAdapter.createStream(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        messages: [
          ChatMessage.system(
            '你是一位资深中文小说编辑。从情节、人物、文笔、节奏四个维度评审章节，只输出 JSON。',
          ),
          ChatMessage.user(prompt),
        ],
        maxTokens: 1200,
        onUsage: (usage) {
          auditService?.recordAudit(
            usage: usage,
            modelName: model,
            operationType: AuditOperationType.editorialReview,
            manuscriptId: manuscriptId ?? '',
            chapterId: chapterId,
            inputText: inputText,
            outputText: buffer.toString(),
          );
        },
      );

      await for (final token in stream) {
        buffer.write(token);
      }
      return EditorialReview.parseFromLLM(buffer.toString());
    } catch (e) {
      return EditorialReview.degraded('评审请求失败：$e');
    }
  }

  String _buildPrompt(String text) {
    return '''请评审以下小说章节，从四个维度给出建议。不要重写正文，只提供评审意见。

只返回如下 JSON（不要附加解释）：
{"dimensions":[{"dimension":"情节","score":0到100的整数,"strengths":"优点","weaknesses":"不足","suggestions":"建议"},{"dimension":"人物","score":...,"strengths":"...","weaknesses":"...","suggestions":"..."},{"dimension":"文笔","score":...,"strengths":"...","weaknesses":"...","suggestions":"..."},{"dimension":"节奏","score":...,"strengths":"...","weaknesses":"...","suggestions":"..."}]}

【待评审章节】
$text''';
  }
}
