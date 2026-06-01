import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  setUp(() async {
    await setUpHiveTest();
    // Register adapter once per test
    if (!Hive.isAdapterRegistered(HiveTypeIds.fragment)) {
      Hive.registerAdapter(FragmentAdapter());
    }
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('Hive fragments box', () {
    test('should open fragments box and put/get a Fragment', () async {
      final box = await Hive.openBox<Fragment>('fragments');

      final fragment = Fragment(
        id: 'test-id-1',
        text: '这是一段灵感碎片',
        tags: [FragmentTags.story],
        createdAt: DateTime(2026, 6, 1),
      );

      await box.put(fragment.id, fragment);

      final retrieved = box.get(fragment.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-id-1'));
      expect(retrieved.text, equals('这是一段灵感碎片'));
      expect(retrieved.tags, equals([FragmentTags.story]));
      expect(retrieved.createdAt, equals(DateTime(2026, 6, 1)));

      await box.close();
    });

    test('should store and retrieve Fragment with multiple tags', () async {
      final box = await Hive.openBox<Fragment>('fragments');

      final fragment = Fragment(
        id: 'test-id-2',
        text: '多标签碎片',
        tags: [FragmentTags.story, FragmentTags.chapter],
        createdAt: DateTime(2026, 6, 1),
      );

      await box.put(fragment.id, fragment);

      final retrieved = box.get(fragment.id);
      expect(retrieved!.tags, hasLength(2));
      expect(retrieved.tags, contains(FragmentTags.story));
      expect(retrieved.tags, contains(FragmentTags.chapter));

      await box.close();
    });
  });

  group('Hive encrypted settings box', () {
    test('should open encrypted settings box and put/get window size values',
        () async {
      // Use a proper 32-byte encryption key
      final key = List.generate(32, (i) => i);
      final encryptedBox = await Hive.openBox(
        'settings',
        encryptionCipher: HiveAesCipher(key),
      );

      // Store window size as a map
      await encryptedBox.put('windowSize', {
        'width': 1200.0,
        'height': 800.0,
      });

      final retrieved = encryptedBox.get('windowSize');
      expect(retrieved, isNotNull);
      expect(retrieved['width'], equals(1200.0));
      expect(retrieved['height'], equals(800.0));

      await encryptedBox.close();
    });

    test('should persist and retrieve window position', () async {
      final key = List.generate(32, (i) => i + 100);
      final encryptedBox = await Hive.openBox(
        'settings',
        encryptionCipher: HiveAesCipher(key),
      );

      await encryptedBox.put('windowPosition', {
        'x': 100.0,
        'y': 200.0,
      });

      final retrieved = encryptedBox.get('windowPosition');
      expect(retrieved, isNotNull);
      expect(retrieved['x'], equals(100.0));
      expect(retrieved['y'], equals(200.0));

      await encryptedBox.close();
    });
  });
}
