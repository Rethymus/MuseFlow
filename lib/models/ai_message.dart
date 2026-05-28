/// AI消息模型
/// 支持多种角色类型的消息
class AIMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AIMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.metadata,
  });

  factory AIMessage.user({
    required String id,
    required String content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AIMessage(
      id: id,
      content: content,
      role: MessageRole.user,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  factory AIMessage.assistant({
    required String id,
    required String content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AIMessage(
      id: id,
      content: content,
      role: MessageRole.assistant,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  factory AIMessage.system({
    required String id,
    required String content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AIMessage(
      id: id,
      content: content,
      role: MessageRole.system,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.toString(),
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.fromString(json['role'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  AIMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AIMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 消息角色枚举
enum MessageRole {
  user,
  assistant,
  system,
  tool;

  static MessageRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      case 'tool':
        return MessageRole.tool;
      default:
        throw ArgumentError('Unknown role: $role');
    }
  }

  @override
  String toString() {
    return name;
  }

  String toApiString() {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
      case MessageRole.tool:
        return 'tool';
    }
  }
}
