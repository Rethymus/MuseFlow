import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/infrastructure/provenance_attribution.dart';

void main() {
  group('aiProvenanceAttribution', () {
    test('should have id ai_provenance', () {
      expect(aiProvenanceAttribution.id, 'ai_provenance');
    });

    test('should merge with itself', () {
      expect(
        aiProvenanceAttribution.canMergeWith(aiProvenanceAttribution),
        isTrue,
      );
    });
  });

  group('provenanceColor', () {
    test('should be systemBlue with low opacity', () {
      // Color(0x1A007AFF) -- alpha=0x1A (~10%), systemBlue
      expect((provenanceColor.a * 255.0).round().clamp(0, 255), 0x1A);
      expect((provenanceColor.b * 255.0).round().clamp(0, 255), 0xFF);
      expect((provenanceColor.g * 255.0).round().clamp(0, 255), 0x7A);
      expect((provenanceColor.r * 255.0).round().clamp(0, 255), 0x00);
    });
  });
}
