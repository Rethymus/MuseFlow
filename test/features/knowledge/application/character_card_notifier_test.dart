import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/application/character_card_notifier.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';

/// Manual mock for CharacterCardRepository.
class MockCharacterCardRepository extends CharacterCardRepository {
  final List<CharacterCard> _cards = [];

  MockCharacterCardRepository() : super(_FakeBox());

  void seed(List<CharacterCard> cards) {
    _cards.clear();
    _cards.addAll(cards);
  }

  @override
  Future<CharacterCard> add(CharacterCard card) async {
    final now = DateTime.now();
    final newCard = card.id.isEmpty
        ? card.copyWith(id: 'mock-${_cards.length}', createdAt: now)
        : card;
    _cards.add(newCard);
    return newCard;
  }

  @override
  List<CharacterCard> getAll() => List.unmodifiable(_cards);

  @override
  CharacterCard? getById(String id) {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> update(CharacterCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      _cards[index] = card.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> delete(String id) async {
    _cards.removeWhere((c) => c.id == id);
  }

  @override
  List<CharacterCard> searchByName(String query) {
    final lowerQuery = query.toLowerCase();
    return _cards.where((card) {
      if (card.name.toLowerCase().contains(lowerQuery)) return true;
      return card.aliases
          .any((alias) => alias.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}

class _FakeBox implements noSuchMethodProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ignore: avoid_implementing_value_types
class _FakeBox implements dynamic {
  // This is a placeholder -- the mock overrides all repository methods
  // so the box is never actually used.
}

void main() {
  group('CharacterCardNotifier', () {
    late ProviderContainer container;
    late MockCharacterCardRepository mockRepo;

    setUp(() {
      mockRepo = MockCharacterCardRepository();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer() {
      container = ProviderContainer(
        overrides: [
          characterCardRepositoryProvider.overrideWith((ref) async => mockRepo),
        ],
      );
      return container;
    }

    group('build', () {
      test('should load all cards from repository', () async {
        mockRepo.seed([
          CharacterCard(
            id: '1',
            name: 'Card1',
            personality: '',
            appearance: '',
            backstory: '',
            createdAt: DateTime(2026, 1, 1),
          ),
          CharacterCard(
            id: '2',
            name: 'Card2',
            personality: '',
            appearance: '',
            backstory: '',
            createdAt: DateTime(2026, 1, 2),
          ),
        ]);

        final c = createContainer();
        final notifier = c.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        final state = c.read(characterCardNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!.length, equals(2));
        expect(state.value!.map((c) => c.name), containsAll(['Card1', 'Card2']));
      });
    });

    group('add', () {
      test('should add card and refresh state', () async {
        final c = createContainer();
        final notifier = c.read(characterCardNotifierProvider.notifier);
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

        final state = c.read(characterCardNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!.length, equals(1));
        expect(state.value!.first.name, equals('NewCard'));
      });
    });

    group('update', () {
      test('should update card and refresh state', () async {
        final existing = CharacterCard(
          id: '1',
          name: 'Original',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: DateTime(2026, 1, 1),
        );
        mockRepo.seed([existing]);

        final c = createContainer();
        final notifier = c.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        await notifier.update(existing.copyWith(name: 'Updated'));

        final state = c.read(characterCardNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!.first.name, equals('Updated'));
        expect(state.value!.first.updatedAt, isNotNull);
      });
    });

    group('delete', () {
      test('should delete card and refresh state', () async {
        final card = CharacterCard(
          id: '1',
          name: 'ToDelete',
          personality: '',
          appearance: '',
          backstory: '',
          createdAt: DateTime(2026, 1, 1),
        );
        mockRepo.seed([card]);

        final c = createContainer();
        final notifier = c.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        await notifier.delete('1');

        final state = c.read(characterCardNotifierProvider);
        expect(state.value, isNotNull);
        expect(state.value!, isEmpty);
      });
    });

    group('searchByName', () {
      test('should filter current state by query', () async {
        mockRepo.seed([
          CharacterCard(
            id: '1',
            name: '李逍遥',
            personality: '',
            appearance: '',
            backstory: '',
            createdAt: DateTime(2026, 1, 1),
          ),
          CharacterCard(
            id: '2',
            name: '赵灵儿',
            personality: '',
            appearance: '',
            backstory: '',
            createdAt: DateTime(2026, 1, 2),
          ),
        ]);

        final c = createContainer();
        final notifier = c.read(characterCardNotifierProvider.notifier);
        await notifier.future;

        final results = notifier.searchByName('逍遥');

        expect(results.length, equals(1));
        expect(results.first.name, equals('李逍遥'));
      });
    });
  });
}
