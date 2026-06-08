import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = Directory.systemTemp.createTempSync('hive_notifier_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('CharacterCardNotifier', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    group('build', () {
      test('should load all cards from repository', () async {
        final box = await Hive.openBox<dynamic>('character_cards');
        final now = DateTime(2026, 1, 1);
        await box.put('1', CharacterCard(
          id: '1',
          name: 'Card1',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ).toJson());
        await box.put('2', CharacterCard(
          id: '2',
          name: 'Card2',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ).toJson());

        container = ProviderContainer();
        final notifier = container.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        final state = container.read(characterCardNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value.length, equals(2));
        final names = state.asData!.value.map((c) => c.name).toList();
        expect(names, containsAll(['Card1', 'Card2']));
      });
    });

    group('add', () {
      test('should add card and refresh state', () async {
        container = ProviderContainer();
        final notifier = container.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        final card = CharacterCard(
          id: '',
          name: 'NewCard',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: DateTime(2026, 1, 1),
        );

        await notifier.add(card);
        // Wait for invalidateSelf rebuild
        await notifier.future;

        final state = container.read(characterCardNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value.length, equals(1));
        expect(state.asData!.value.first.name, equals('NewCard'));
      });
    });

    group('save', () {
      test('should update card and refresh state', () async {
        final box = await Hive.openBox<dynamic>('character_cards');
        final now = DateTime(2026, 1, 1);
        final existing = CharacterCard(
          id: '1',
          name: 'Original',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        );
        await box.put('1', existing.toJson());

        container = ProviderContainer();
        final notifier = container.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        await notifier.save(existing.copyWith(name: 'Updated'));
        await notifier.future;

        final state = container.read(characterCardNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value.first.name, equals('Updated'));
        expect(state.asData!.value.first.updatedAt, isNotNull);
      });
    });

    group('delete', () {
      test('should delete card and refresh state', () async {
        final box = await Hive.openBox<dynamic>('character_cards');
        final now = DateTime(2026, 1, 1);
        await box.put('1', CharacterCard(
          id: '1',
          name: 'ToDelete',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ).toJson());

        container = ProviderContainer();
        final notifier = container.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        await notifier.delete('1');
        await notifier.future;

        final state = container.read(characterCardNotifierProvider);
        expect(state.asData?.value, isNotNull);
        expect(state.asData!.value, isEmpty);
      });
    });

    group('searchByName', () {
      test('should filter current state by query', () async {
        final box = await Hive.openBox<dynamic>('character_cards');
        final now = DateTime(2026, 1, 1);
        await box.put('1', CharacterCard(
          id: '1',
          name: '李逍遥',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ).toJson());
        await box.put('2', CharacterCard(
          id: '2',
          name: '赵灵儿',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: now,
        ).toJson());

        container = ProviderContainer();
        final notifier = container.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        final results = notifier.searchByName('逍遥');

        expect(results.length, equals(1));
        expect(results.first.name, equals('李逍遥'));
      });
    });
  });
}
