import 'dart:ui';

/// Immutable mapping between a plot node and its saved graph position.
///
/// Keeps visual layout state separate from [PlotNode] so story structure
/// entities stay focused on narrative data.
class NodePosition {
  final String plotNodeId;
  final double x;
  final double y;

  const NodePosition({
    required this.plotNodeId,
    required this.x,
    required this.y,
  });

  /// Returns this position as a Flutter [Offset] for graph layout APIs.
  Offset toOffset() => Offset(x, y);

  /// Creates a copy with the given fields replaced.
  NodePosition copyWith({String? plotNodeId, double? x, double? y}) {
    return NodePosition(
      plotNodeId: plotNodeId ?? this.plotNodeId,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  factory NodePosition.fromJson(Map<String, dynamic> json) {
    return NodePosition(
      plotNodeId: json['plotNodeId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'plotNodeId': plotNodeId, 'x': x, 'y': y};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NodePosition &&
        other.plotNodeId == plotNodeId &&
        other.x == x &&
        other.y == y;
  }

  @override
  int get hashCode => Object.hash(plotNodeId, x, y);

  @override
  String toString() => 'NodePosition(plotNodeId: $plotNodeId, x: $x, y: $y)';
}
