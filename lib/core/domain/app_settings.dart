/// Application settings persisted in an encrypted Hive box.
///
/// Immutable entity -- use [copyWith] to create modified copies.
class AppSettings {
  final double? windowWidth;
  final double? windowHeight;
  final double? windowX;
  final double? windowY;
  final String defaultTag;

  const AppSettings({
    this.windowWidth,
    this.windowHeight,
    this.windowX,
    this.windowY,
    this.defaultTag = '故事',
  });

  /// Creates a copy of this settings with the given fields replaced.
  AppSettings copyWith({
    double? windowWidth,
    double? windowHeight,
    double? windowX,
    double? windowY,
    String? defaultTag,
  }) {
    return AppSettings(
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      windowX: windowX ?? this.windowX,
      windowY: windowY ?? this.windowY,
      defaultTag: defaultTag ?? this.defaultTag,
    );
  }

  /// Creates AppSettings from a JSON map.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      windowWidth: json['windowWidth'] as double?,
      windowHeight: json['windowHeight'] as double?,
      windowX: json['windowX'] as double?,
      windowY: json['windowY'] as double?,
      defaultTag: json['defaultTag'] as String? ?? '故事',
    );
  }

  /// Serializes this settings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'windowX': windowX,
      'windowY': windowY,
      'defaultTag': defaultTag,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.windowWidth == windowWidth &&
        other.windowHeight == windowHeight &&
        other.windowX == windowX &&
        other.windowY == windowY &&
        other.defaultTag == defaultTag;
  }

  @override
  int get hashCode =>
      Object.hash(windowWidth, windowHeight, windowX, windowY, defaultTag);

  @override
  String toString() =>
      'AppSettings(windowWidth: $windowWidth, windowHeight: $windowHeight, '
      'windowX: $windowX, windowY: $windowY, defaultTag: $defaultTag)';
}
