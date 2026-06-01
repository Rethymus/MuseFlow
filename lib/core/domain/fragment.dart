/// Type ID registry for Hive adapters.
/// Centralizes all type IDs to prevent conflicts.
abstract class HiveTypeIds {
  static const int fragment = 0;
  static const int appSettings = 1;
  static const int manuscript = 2;
}

/// A creative fragment captured by the user.
/// Represents a single inspiration snippet with optional tags.
///
/// Immutable entity -- use [copyWith] to create modified copies.
class Fragment {
  final String id;
  final String text;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Fragment({
    required this.id,
    required this.text,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a copy of this fragment with the given fields replaced.
  Fragment copyWith({
    String? id,
    String? text,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fragment(
      id: id ?? this.id,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a Fragment from a JSON map.
  factory Fragment.fromJson(Map<String, dynamic> json) {
    return Fragment(
      id: json['id'] as String,
      text: json['text'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Serializes this fragment to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fragment &&
        other.id == id &&
        other.text == text &&
        _listEquals(other.tags, tags) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, text, Object.hashAll(tags), createdAt, updatedAt);

  @override
  String toString() =>
      'Fragment(id: $id, text: $text, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
