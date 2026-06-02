import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/infrastructure/provenance_attribution.dart';

void main() {
  group('aiProvenanceAttribution', () {
    test('should have id ai_provenance', () {
      expect(aiProvenanceAttribution.id, 'ai_provenance');
    });

    test('should merge with itself', () {
      expect(aiProvenanceAttribution.canMergeWith(aiProvenanceAttribution), isTrue);
    });
  });

  group('provenanceColor', () {
    test('should be blue with low opacity', () {
      // Color(0x1A2196F3) -- alpha=0x1A (~10%), blue=0xF3, green=0x96, red=0x21
      expect(provenanceColor.alpha, 0x1A);
      expect(provenanceColor.blue, 0xF3);
      expect(provenanceColor.green, 0x96);
      expect(provenanceColor.red, 0x21);
    });
  });
}
