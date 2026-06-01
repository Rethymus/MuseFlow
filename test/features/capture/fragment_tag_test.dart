import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/application/fragment_service.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/core/infrastructure/fragment_repository.dart';

/// Manual mock for FragmentRepository.
/// Avoids adding mockito as a direct dependency.
class MockFragmentRepository implements FragmentRepository {
  final List<Fragment> _fragments = [];
  bool deleteFragmentCalled = false;
  String? lastDeletedId;
  Fragment? lastUpdatedFragment;

  @override
  Fragment addFragment(String text, {List<String>? tags}) {
    final fragment = Fragment(
      id: 'test-${_fragments.length}',
      text: text,
      tags: tags ?? [],
      createdAt: DateTime.now(),
    );
    _fragments.add(fragment);
    return fragment;
  }

  @override
  List<Fragment> getAllFragments() => List.unmodifiable(_fragments);

  @override
  Future<void> deleteFragment(String id) async {
    deleteFragmentCalled = true;
    lastDeletedId = id;
    _fragments.removeWhere((f) => f.id == id);
  }

  @override
  List<Fragment> getFragmentsByTag(String tag) {
    return _fragments.where((f) => f.tags.contains(tag)).toList();
  }

  @override
  Future<void> updateFragment(Fragment fragment) async {
    lastUpdatedFragment = fragment;
    final index = _fragments.indexWhere((f) => f.id == fragment.id);
    if (index >= 0) {
      _fragments[index] = fragment;
    }
  }
}

void main() {
  late FragmentService service;
  late MockFragmentRepository mockRepo;

  setUp(() {
    mockRepo = MockFragmentRepository();
    service = FragmentService(mockRepo);
  });

  group('FragmentService', () {
    group('createFragment', () {
      test('should create fragment with text and empty tags', () {
        final fragment = service.createFragment('test fragment');

        expect(fragment.text, equals('test fragment'));
        expect(fragment.id, isNotEmpty);
        expect(fragment.tags, isEmpty);
        expect(fragment.createdAt, isNotNull);
      });

      test('should create fragment with provided tags', () {
        final fragment = service.createFragment(
          'tagged fragment',
          tags: [FragmentTags.story],
        );

        expect(fragment.tags, contains(FragmentTags.story));
      });
    });

    group('listFragments', () {
      test('should return fragments sorted by createdAt descending', () async {
        // Add fragments with a small delay to ensure different timestamps
        service.createFragment('first');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        service.createFragment('second');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        service.createFragment('third');

        final fragments = service.listFragments();

        expect(fragments.length, equals(3));
        expect(fragments.first.text, equals('third'));
        expect(fragments.last.text, equals('first'));
      });
    });

    group('listFragmentsByTag', () {
      test('should return all fragments when tag is "全部"', () {
        service.createFragment('a', tags: [FragmentTags.story]);
        service.createFragment('b', tags: [FragmentTags.chapter]);
        service.createFragment('c', tags: [FragmentTags.scene]);

        final fragments = service.listFragmentsByTag('全部');

        expect(fragments.length, equals(3));
      });

      test('should return filtered fragments for specific tag', () {
        service.createFragment('story fragment', tags: [FragmentTags.story]);
        service.createFragment('chapter fragment', tags: [FragmentTags.chapter]);
        service.createFragment('both', tags: [FragmentTags.story, FragmentTags.chapter]);

        final fragments = service.listFragmentsByTag(FragmentTags.story);

        expect(fragments.length, equals(2));
        expect(fragments.every((f) => f.tags.contains(FragmentTags.story)), isTrue);
      });
    });

    group('removeFragment', () {
      test('should delegate delete to repository', () async {
        final fragment = service.createFragment('to delete');

        await service.removeFragment(fragment.id);

        expect(mockRepo.deleteFragmentCalled, isTrue);
        expect(mockRepo.lastDeletedId, equals(fragment.id));
      });
    });

    group('updateFragmentTags', () {
      test('should update tags and set updatedAt', () async {
        final fragment = service.createFragment('original');
        expect(fragment.updatedAt, isNull);

        await service.updateFragmentTags(fragment.id, [FragmentTags.story]);

        expect(mockRepo.lastUpdatedFragment, isNotNull);
        expect(mockRepo.lastUpdatedFragment!.tags, [FragmentTags.story]);
        expect(mockRepo.lastUpdatedFragment!.updatedAt, isNotNull);
      });
    });

    group('getDefaultTags', () {
      test('should return all default tags', () {
        final tags = service.getDefaultTags();

        expect(tags, equals(FragmentTags.defaults));
      });
    });
  });
}
