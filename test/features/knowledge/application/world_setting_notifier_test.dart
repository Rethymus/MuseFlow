import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/application/world_setting_notifier.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';

/// Manual mock for WorldSettingRepository.
class MockWorldSettingRepository extends WorldSettingRepository {
  final List<WorldSetting> _settings = [];

  MockWorldSettingRepository() : super(_FakeBox());

  void seed(List<WorldSetting> settings) {
    _settings.clear();
    _settings.addAll(settings);
  }

  @override
  Future<WorldSetting> add(WorldSetting setting) async {
    final now = DateTime.now();
    final newSetting = setting.id.isEmpty
        ? setting.copyWith(id: 'mock-${_settings.length}', createdAt: now)
        : setting;
    _settings.add(newSetting);
    return newSetting;
  }

  @override
  List<WorldSetting> getAll() => List.unmodifiable(_settings);

  @override
  WorldSetting? getById(String id) {
    try {
      return _settings.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> update(WorldSetting setting) async {
    final index = _settings.indexWhere((s) => s.id == setting.id);
    if (index >= 0) {
      _settings[index] = setting.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> delete(String id) async {
    _settings.removeWhere((s) => s.id == id);
  }

  @override
  List<WorldSetting> searchByName(String query) {
    final lowerQuery = query.toLowerCase();
    return _settings.where((setting) {
      if (setting.name.toLowerCase().contains(lowerQuery)) return true;
      return setting.aliases
          .any((alias) => alias.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}

class _FakeBox {
  // Placeholder -- mock overrides all repository methods.
}

void main() {
  group('WorldSettingNotifier', () {
    late ProviderContainer container;
    late MockWorldSettingRepository mockRepo;

    setUp(() {
      mockRepo = MockWorldSettingRepository();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer() {
      container = ProviderContainer(
        overrides: [
          worldSettingRepositoryProvider
              .overrideWith((ref) async => mockRepo),
        ],
      );
      return container;
    }

    group('build', () {
      test('should load all settings from repository', () async {
        mockRepo.seed([
          WorldSetting(
            id: '1',
            name: 'Setting1',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: DateTime(2026, 1, 1),
          ),
          WorldSetting(
            id: '2',
            name: 'Setting2',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: DateTime(2026, 1, 2),
          ),
        ]);

        final c = createContainer();
        final notifier = c.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        final state = c.read(worldSettingNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!.length, equals(2));
        expect(
          state.value!.map((s) => s.name),
          containsAll(['Setting1', 'Setting2']),
        );
      });
    });

    group('add', () {
      test('should add setting and refresh state', () async {
        final c = createContainer();
        final notifier = c.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        final setting = WorldSetting(
          id: '',
          name: 'NewSetting',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: DateTime(2026, 1, 1),
        );

        await notifier.add(setting);

        final state = c.read(worldSettingNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!.length, equals(1));
        expect(state.value!.first.name, equals('NewSetting'));
      });
    });

    group('update', () {
      test('should update setting and refresh state', () async {
        final existing = WorldSetting(
          id: '1',
          name: 'Original',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: DateTime(2026, 1, 1),
        );
        mockRepo.seed([existing]);

        final c = createContainer();
        final notifier = c.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        await notifier.update(existing.copyWith(name: 'Updated'));

        final state = c.read(worldSettingNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!.first.name, equals('Updated'));
        expect(state.value!.first.updatedAt, isNotNull);
      });
    });

    group('delete', () {
      test('should delete setting and refresh state', () async {
        final setting = WorldSetting(
          id: '1',
          name: 'ToDelete',
          description: '',
          rules: '',
          factions: '',
          geography: '',
          techLevel: '',
          createdAt: DateTime(2026, 1, 1),
        );
        mockRepo.seed([setting]);

        final c = createContainer();
        final notifier = c.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        await notifier.delete('1');

        final state = c.read(worldSettingNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!, isEmpty);
      });
    });

    group('searchByName', () {
      test('should filter current state by query', () async {
        mockRepo.seed([
          WorldSetting(
            id: '1',
            name: '修仙界',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: DateTime(2026, 1, 1),
          ),
          WorldSetting(
            id: '2',
            name: '赛博朋克',
            description: '',
            rules: '',
            factions: '',
            geography: '',
            techLevel: '',
            createdAt: DateTime(2026, 1, 2),
          ),
        ]);

        final c = createContainer();
        final notifier = c.read(worldSettingNotifierProvider.notifier);
        await notifier.future;

        final results = notifier.searchByName('修仙');

        expect(results.length, equals(1));
        expect(results.first.name, equals('修仙界'));
      });
    });
  });
}
